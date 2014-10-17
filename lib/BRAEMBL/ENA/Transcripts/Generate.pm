package BRAEMBL::ENA::Transcripts::Generate;

use Moose;
use BRAEMBL::DefaultLogger;
use Data::Dumper;

has 'template_dir' => (
  is      => 'rw', 
  isa     => 'Str',
);

sub sanity_check_raw {

  my $annotation = shift;
  my $seq        = shift;
  
  my $start = $annotation->{coordinates}->{start};
  my $end   = $annotation->{coordinates}->{end};

  run_sanity_checks({
    start => $start,
    end   => $end,
    name  => "Raw: " . $seq->display_id,
  });
}

sub sanity_check {

  my $bio_seq = shift;    
  confess('Type error') unless($bio_seq->isa('Bio::Seq'));
  
  my @features = $bio_seq->get_SeqFeatures;
  
  my @exon = grep { $_->isa('Bio::SeqFeature::Gene::Exon') } @features;
  
  if (@exon>1) {
    confess("More than one exon found!");
  }
  if (@exon==0) {
    confess("No exon found!");
  }
  my $exon = $exon[0];
  
  run_sanity_checks(
    as_param($exon, "Processed: " . $bio_seq->display_id)
  );
}

sub as_param {

  my $exon = shift;
  my $name = shift;

  my $start = $exon->start;
  my $end   = $exon->end;
  my $seq   = $exon->seq->seq;
  
  return {
    start => $start,
    end   => $end,
    seq   => $seq,
    name  => $name,
  };
}

sub is_end_greater_than_start {

  my $param = shift;

  my $start = $param->{start};
  my $end   = $param->{end};
  
  return $end>$start;
}

sub is_protein_coding_feature_length_multiple_of_three {

  my $param = shift;

  my $start = $param->{start};
  my $end   = $param->{end};
  
  my $length = $end - $start + 1;
  
  return $length % 3 == 0;
}

sub is_start_methionine {

  my $param = shift;
  my $seq   = $param->{seq};  
  my $startcodon = substr($seq, 0, 3);  
  return $startcodon eq 'ATG';
}

sub is_terminated_by_stop_codon {

  my $param = shift;
  my $seq   = $param->{seq};  
  my $stopcodon = substr($seq, length($seq) - 3, 3);
  
  my $stopcodon_found = grep { $_ eq $stopcodon } qw(
    TAG
    TAA
    TGA
  );
  
  return $stopcodon_found;
}

sub has_less_than_three_bases {

  my $param = shift;

  my $start = $param->{start};
  my $end   = $param->{end};
  
  my $length = $end - $start + 1;
  
  return $end - $start >=3;
}

sub run_sanity_checks {

  my $param = shift;  
  my $seq   = $param->{seq};
  my $name  = $param->{name};

  my $logger = get_logger();
  
  $logger->error($name . ": End must be greater than start.") 
    unless (is_end_greater_than_start($param));  
  $logger->error($name . ": Protein coding feature length must be a multiple of 3. Consider 5' or 3' partial location.") 
    unless (is_protein_coding_feature_length_multiple_of_three($param));
  
  $logger->error($name . ": Protein coding feature with fewer than 3 bases must be 3' or 5' partial.") 
    unless(has_less_than_three_bases($param));
  
  
  if ($seq) {
    $logger->error($name . ": The protein translation of the protein coding feature does not start with a methionine. Consider 5' partial location.") 
      unless(is_start_methionine($param));

    $logger->error($name . ": No stop codon at the 3' end of the CDS feature translation. Consider 3' partial location.") 
      unless(is_terminated_by_stop_codon($param));
  }
}

sub generate_transcript_file {

  my $self  = shift;
  my $param = shift;
  
  my $seqIO_in                = $param->{seqIO_in};
  my $seqIO_fasta_out         = $param->{seqIO_fasta_out};
  my $parsed_annotation       = $param->{parsed_annotation};
  my $embl                    = $param->{embl};
  my $embl_output_dir         = $param->{embl_output_dir};
  my $contigs_with_annotation = $param->{contigs_with_annotation};
  my $contig_file             = $param->{contig_file};
  my $html_output_dir         = $param->{html_output_dir};
  my $fasta_submission_file   = $param->{fasta_submission_file};  
  
  use BRAEMBL::ENA::Transcripts::ConfiguredGenesParser;
  my $cgp = BRAEMBL::ENA::Transcripts::ConfiguredGenesParser->new();

  my $num_genes = 0;
  my $num_genes_with_stop_codons = 0;
  my @problem_genes;
  
  my $logger = get_logger();

  my $all_contigs = Set::Scalar->new;
  
  CONTIG: while(my $seq = $seqIO_in->next_seq) {
  
    my $primary_id = $seq->primary_id;  
    $all_contigs->insert($primary_id);
    
    next CONTIG unless (exists $parsed_annotation->{$primary_id});
    
    my $annotation = $parsed_annotation->{$primary_id};  
    
    sanity_check_raw($annotation, $seq);
    
    $num_genes++;

    my $gene = $cgp->parsed_annotation_to_bioperl_object($annotation);
    my @exons = $gene->exons;
    my $exon = $exons[0];
    my @transcripts = $gene->transcripts;
    my $transcript = $transcripts[0];
    
    my $is_reverse_strand_feature = $exon->strand == -1;
    
    $seq->add_SeqFeature($gene);
    $seq->add_SeqFeature($transcript);  
    $seq->add_SeqFeature($exon);
    
    $exon->primary_tag('CDS');  
    
    sanity_check($seq);
    
    my @products = $gene->get_tag_values('product');
    my $product  = $products[0];
    
    my $three_prime_coordinate;
    my $five_prime_coordinate;
    
    if ($is_reverse_strand_feature) {

      my $primary_id = $seq->primary_id;
      $seq = $seq->revcom;
      $seq->primary_id($primary_id);

      revcom_feature_coordinates($seq->length, $exon);
      $exon->attach_seq($seq);
      
    }
    $five_prime_coordinate  = $exon->start;
    $three_prime_coordinate = $exon->end;
    
    my $is_partial_at_five_prime  = ! is_start_methionine(as_param($exon, $product));
    my $is_partial_at_three_prime = 
      ! is_protein_coding_feature_length_multiple_of_three(as_param($exon, $product))
      || ! is_terminated_by_stop_codon(as_param($exon, $product))
    ;
    #is_protein_coding_feature_length_multiple_of_three($param)
  
    my $seq_description = join ' ',
      '[Organism=Hadronyche infensa]',
      '[Name for the assembly=HI]',
      '[Assembly method=MIRA]',
      '[Sequencing technology=454 GS]',
      '[SRA Study Accession=ERP005525]',
      '[SRA Sample Accession=ERS431088]',
      '[Contig/Isotig name=' . $primary_id . ']',
      ($product ne '' ? '[product=' . $product . ']' : ''),
      '[5\' CDS location='. $five_prime_coordinate .']',
      '[3\' CDS location='. $three_prime_coordinate .']',
      "[partial at 5' ? (yes/no)=" . ( $is_partial_at_five_prime ? 'yes' : 'no' ) . "]",
      "[partial at 3' ? (yes/no)=" . ( $is_partial_at_three_prime ? 'yes' : 'no' ) . "]",
      "[Translation table=1]"
    ; 

    $seq->desc($seq_description);
    
    if ($exon->start<1) {
	$exon->start(1);
	$logger->fatal("Start is outside of known sequence for: ${seq_description}");
	#die;
    }
    if ($exon->end>$seq->length) {
	
	$logger->fatal("End (". $exon->end .") is greater than length of sequence (". $seq->length .") for: ${seq_description}");
	
	$exon->end($seq->length);
	#die;
    }
    
    my $translated_sequence;  
    eval {
      $translated_sequence = $exon->cds->translate->seq;
    };
    if ($@) {
      $logger->fatal("Problem getting the amino acid sequence of the following exon object:");
      $logger->fatal(Dumper($exon));
      confess ( $@ );    
    }

    my @stop_codons = $translated_sequence =~ /\*/g;
    my $num_stop_codons = @stop_codons;
    # If there is a stop codon at the end of the amino acid sequence, this is 
    # not an error.
    #
    my $expected_stop_codons = $translated_sequence =~ /\*$/;  
    my $num_bad_stop_codons = $num_stop_codons - $expected_stop_codons;
    
    if ($num_bad_stop_codons>0) {   
      
      my $problem_description = {
	gene => $gene,
	msg  => "Sequence of gene on ". $seq->primary_id ." has $num_bad_stop_codons stop codons in its sequence."
      };    
      use Hash::Util qw( lock_keys );
      lock_keys(%$problem_description);
      
      $logger->error($problem_description->{msg});
      push @problem_genes, $problem_description;
      $num_genes_with_stop_codons++;
    }

    if ($embl) {
    
      my $embl_file = File::Spec->join( $embl_output_dir, $seq->primary_id . '.embl');
      
      my $seqIO_embl_out = Bio::SeqIO->new( 
	-file   => '>' . $embl_file,
	-format => 'embl'
      );
      
      $seqIO_embl_out->write_seq($seq);
    }
    $seqIO_fasta_out->write_seq($seq);
  }

  #
  # ---------------------------------------------------------------------------
  #
  # Done processing contigs, now do stats
  #

  $logger->info("$num_genes genes processed.");

  my %problem_data;
  my $are_problems_with_data;

  if ($num_genes_with_stop_codons>0) {  

    $logger->error("$num_genes_with_stop_codons protein coding genes had stop codons in them.");  
    $problem_data{problem_genes} = \@problem_genes;  
    $are_problems_with_data = 1;
    
  } else {

    $logger->info("Good: No stop codons found in protein coding genes.");
    $problem_data{problem_genes} = ();  
  }

  if ($embl) {
    $logger->info("EMBL files of the contigs with genes annotated in them were generated you can find them in $embl_output_dir and use Artemis to view them.");
  }

  my $referenced_contigs_but_not_in_contig_file = $contigs_with_annotation->difference($all_contigs);
  my @genes_on_non_existing_contigs;
  if ($referenced_contigs_but_not_in_contig_file->size) {

    $logger->warn($referenced_contigs_but_not_in_contig_file->size . " contigs were referenced in the annotation, but they were not found in the contig file $contig_file. The contigs are: " . $referenced_contigs_but_not_in_contig_file . ". They might be misspelled. If this is not fixed, the genes on these contigs will not be submitted.");
    
    while (defined(my $contig_name = $referenced_contigs_but_not_in_contig_file->each)) {

      my $gene = $cgp->parsed_annotation_to_bioperl_object($parsed_annotation->{$contig_name});
      push @genes_on_non_existing_contigs, {
	gene => $gene,
	contig_name => $contig_name,
      };
    }
      $problem_data{genes_on_non_existing_contigs} = \@genes_on_non_existing_contigs;
      $are_problems_with_data = 1;
  }

  if ($are_problems_with_data) {
    my $summary_problem_genes = $self->summarise_problem_genes(\%problem_data, $html_output_dir);
    $logger->error(
      "A summary of the problem genes has been written to ${summary_problem_genes}. You can review these genes by running 'firefox $summary_problem_genes'."
    );
  }

  if (!$are_problems_with_data) {

    $logger->info(
      "A fasta file has been prepared for submission: $fasta_submission_file"
    );

  }
}

sub revcom_feature_coordinates {

  my $seq_length = shift;
  my $feature    = shift;
  
  my $feature_length_before = $feature->end - $feature->start + 1;
  
  my $feature_start = $seq_length - $feature->start + 1;
  my $feature_end   = $seq_length - $feature->end   + 1;
  
  $feature->start($feature_end);
  $feature->end($feature_start);
  
  my $feature_length_after = $feature->end - $feature->start + 1;
  
  my $logger = get_logger();
  
  if ($feature_length_before != $feature_length_after) {
    $logger->error("Length of gene has changed during reverse complementing!");
  }
  
  $feature->strand(-1 * $feature->strand);

}

sub summarise_problem_genes {

    my $self = shift;

    my $problem_data = shift;
    my $output_dir   = shift;

    use Template;

    my $current_template = '/problem_genes.html';

    my $template = Template->new( 
        ENCODING     => 'utf8',
        ABSOLUTE     => 1, 
        RELATIVE     => 1,
        INCLUDE_PATH => File::Spec->join($self->template_dir),
    );

    use Text::Wrap;
    $Text::Wrap::columns = 60;
    $Text::Wrap::separator="\n";
    
    my $template_var = {
        problem_data => $problem_data,
        #genes_on_non_existing_contigs => \@genes_on_non_existing_contigs,
        wrap_text => sub { 
	  my $text = shift;
	  return wrap('', '', $text);
        }
    };

    make_path($output_dir);
    
    my $xml;
    my $generated_file = File::Spec->join($output_dir,  $current_template);

    $template->process(
	File::Spec->join( $self->template_dir, $current_template),
	$template_var,
	$generated_file
	
    )
	|| confess ($template->error());
    return $generated_file;
}

1;
