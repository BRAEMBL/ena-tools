package BRAEMBL::ENA::Submission::Rest::Coral::RestValueGuesser;

use Moose;
use BRAEMBL::DefaultLogger;

has 'project_data' => (
  is      => 'rw',
  isa     => 'ArrayRef', 
);

sub guess_study_type {

  my $self = shift;

  my $dataset = assert_all_keys_have_same_value({
    key => 'Dataset',
    array_of_hashes => \@$project_data,
  });

  my $study_type = $dataset;
  
  $study_type =~ s/ /_/g;
  $study_type = lc ($study_type);
  
  return $study_type;
}
  
  my $genome_sequencing_facility = assert_all_keys_have_same_value({
    key => 'Genome Sequencing Facility',
    array_of_hashes => \@$project_data,
  });
  
  my $sequencer = assert_all_keys_have_same_value({
    key => 'Sequencer',
    array_of_hashes => \@$project_data,
  });
  
# Species is often a link like this:
# http://purl.obolibrary.org/obo/NCBITaxon_51062
#
  my $species = assert_all_keys_have_same_value({
    key => 'Species',
    array_of_hashes => \@$project_data,
  });  
  
  my $taxon_id;
  
  if ($dataset !~ /Genome/) {
  
    $species = undef;
    
  } else {

    my $taxon_id_found = $species =~ "http://purl.obolibrary.org/obo/NCBITaxon_(\d+)";
    
    if ($taxon_id_found) {
      $taxon_id = $1;
    } else {
      if ($species eq 'Galaxea fascicularis') {
	# http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=46745&lvl=3&lin=f&keep=1&srchmode=1&unlock
	$taxon_id = '46745';
      }
    }
  }
  if ($taxon_id) {
    $logger->warn("No taxon id found for species $species");
  }


sub assert_all_keys_have_same_value {

  my $param = shift;
  
  my $key = $param->{key};
  my $array_of_hashes = $param->{array_of_hashes};

  use List::MoreUtils qw{ uniq };
  
  my @unique;
  
  eval {
    @unique = uniq map { $_->{$key} } @$array_of_hashes;
  };
  if ($@) {
    $logger->error(
      "Got error $@ when processing this dataset: " . Dumper($array_of_hashes)
    );
  }
  
  if (@unique!=1) {
    if (@unique>1) {
      $logger->error("Got more than one value for $key:" . join ', ', @unique );
    }
    if (@unique==0) {
      $logger->error("Got no value for $key!");
    }
  }
  return $unique[0];
}


1;
