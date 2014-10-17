package BRAEMBL::ENA::Transcripts::ConfiguredGenesParser;

use Moose;
use BRAEMBL::DefaultLogger;
use Hash::Util qw(lock_keys);
use Data::Dumper;

sub parse {

  my $self = shift;
  my $annotation = shift;
  
  #print Dumper($annotation);  exit;
  
  #my @lines = split "\n", $annotation;
  
  my $annotation_as_hash = $self->parse_annotation_to_hash($annotation);
  #print Dumper($annotation_as_hash);  exit;
  
  return $self->parsed_annotation_hash_to_bioperl_object_list(
    $annotation_as_hash
  );
}

sub parsed_annotation_hash_to_bioperl_object_list {

  my $self = shift;  
  my $annotation_hash = shift;
  
  my @gene_list;
  
  foreach my $current_contig (keys %$annotation_hash) {
    my $gene_obj = $self->parsed_annotation_to_bioperl_object($annotation_hash->{$current_contig});
    push @gene_list, $gene_obj;
  }
  return \@gene_list;
}

sub parsed_annotation_to_bioperl_object {

  my $self = shift;
  my $hash = shift;
  
  #print Dumper($hash);
  
    my $gene = new Bio::SeqFeature::Gene::GeneStructure (
    -start  => $hash->{coordinates}->{start},
    -end    => $hash->{coordinates}->{end},
    -strand => $hash->{strand},
    -display_name => $hash->{superfamily} . ', ' . $hash->{arachnoserver_name},
    -primary => 'gene',
    -tag    => { 
      product     => $hash->{arachnoserver_name},
      superfamily => $hash->{superfamily},
      note        => $hash->{not_sure},
    }
  );
  
  $gene->location->seq_id($hash->{contig_name});
  
  use Bio::SeqFeature::Gene::Transcript;
  my $transcript = new Bio::SeqFeature::Gene::Transcript (
    -start  => $hash->{coordinates}->{start},
    -end    => $hash->{coordinates}->{end},
    -strand => $hash->{strand},
  );
  
  my $frame = $hash->{frame};
  
  my $tag = { note => "original_frame=$frame" };

  my @init_exon_args = (
    -start  => $hash->{coordinates}->{start},
    -end    => $hash->{coordinates}->{end},
    -strand => $hash->{strand},
    -tag    => $tag,
  );

  my $exon = new Bio::SeqFeature::Gene::Exon(@init_exon_args);

  $transcript->add_exon($exon);
  $gene->add_transcript($transcript);

  return $gene;
}

sub parse_annotation_list_to_hash_list {

  my $self = shift;

  my @line = @_;
  my @hash_list;
  
  foreach my $current_line (@line) {
  
    my $parsed_hash = $self->parse_annotation_to_hash($current_line);
    push @hash_list, $parsed_hash;
  
  }
  return @hash_list;
}

sub parse_annotation_to_hash {

  my $self = shift;
  my $annotation = shift;
  my %parsed_annotation;

  use List::AllUtils qw(zip);
  my @headers = qw(superfamily arachnoserver_name frame coordinates);
  
  my %seen_sequences;
  foreach my $current_seq_name (keys %$annotation) {
      
      if (exists $seen_sequences{$current_seq_name}) {
	confess("Sequence is not unique: $current_seq_name");
      } else {
	$seen_sequences{$current_seq_name} = 1;
      }
      my $value = $annotation->{$current_seq_name};
      #print "$value\n";
      my @values = split /\t/, $value;
      my %parsed = zip @headers, @values;      
      my $coordinates = $parsed{coordinates};
      
      my @alternatives = split '/', $coordinates;
      
      if (@alternatives==1) {
	  $parsed{strand} = 1;
	  $coordinates=$alternatives[0];
      }
      if (@alternatives==2) {
	  $parsed{strand} = -1;
	  $coordinates=$alternatives[1];
      }
      
      unless(exists $parsed{strand}) {
	use Data::Dumper;
	confess("Parse error! No strand for the feature with these coordinates $coordinates: " . Dumper(\%parsed));
      };
      
      (my $start, my $end) = split '-', $coordinates;
      
      $parsed{coordinates_source} = $parsed{coordinates};
      $parsed{coordinates} = {
	  start => $start,
	  end   => $end,
      };
      $parsed{contig_name} = $current_seq_name;
      
      lock_keys(%{$parsed{coordinates}});
      
      $parsed_annotation{$current_seq_name} = \%parsed;
  }
  lock_keys(%parsed_annotation);
  return \%parsed_annotation;
}

1;
