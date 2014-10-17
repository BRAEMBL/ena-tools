package BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::StudyBuilder;

use Moose;

sub build_alias {
#     my $self = shift;
#     return $self->build_submitter_name . '-' . 'ST131';
    return 'ST131';
}

sub build_center_name {
    return 'BRAEMBL';
}

sub build_broker_name {
    return 'BRAEMBL';
}

sub build_submitter_name {
    return 'BRAEMBL';
}

sub build_title {
    return 'Global dissemination of a multidrug resistant Escherichia coli clone';
}

sub build_hold_until_date {
    return '2015-01-21';
}

=head2 build_existing_study_type

    Controlled vocabulary for existing_study_type:

      Whole Genome Sequencing
      Metagenomics
      Transcriptome Analysis
      Resequencing
      Epigenetics
      Synthetic Genomics
      Forensic or Paleo-genomics
      Gene Regulation Study
      Cancer Genomics
      Population Genomics
      RNASeq
      Exome Sequencing
      Pooled Clone Sequencing
      Other
      If using "Other" please add new_study_type="TODO: add own term" attribute

=cut
sub build_existing_study_type {
    return 'Whole Genome Sequencing';
}

sub build_abstract {
    return 'Escherichia coli ST131 is a globally disseminated, multidrug resistant (MDR) clone responsible for a high proportion of urinary tract and bloodstream infections. The rapid emergence and successful spread of E. coli ST131 is strongly associated with several factors, including resistance to fluoroquinolones, high virulence gene content, the possession of the type 1 fimbriae FimH30 allele and the production of the CTX-­‐M-­‐15 extended spectrum β-­‐lactamase (ESBL). Here we used genome sequencing to examine the molecular epidemiology of a collection of E. coli ST131 strains isolated from six distinct geographical locations across the world spanning 2000-­‐2011. The global phylogeny of E. coli ST131, determined from whole-­‐genome sequence data, revealed a single lineage of E. coli ST131 distinct from other extra-­‐intestinal E. coli strains within the B2 phylogroup. Three closely related E. coli ST131 sub-­‐lineages were identified, with little association to geographic origin. The majority of single nucleotide variants associated with each of the sub-­‐ lineages were due to recombination in regions adjacent to mobile genetic elements (MGEs). The most prevalent sub-­‐lineage of ST131 strains was characterized by fluoroquinolone resistance, and a distinct virulence factor and MGE profile. Four different variants of the CTX-­‐M ESBL-­‐resistance gene were identified in our ST131 strains, with acquisition of CTX-­‐M-­‐15 representing a defining feature of a discrete but geographically dispersed ST131 sub-­‐lineage. This study confirms the global dispersal of a single E. coli ST131 clone and demonstrates the role of MGEs and recombination in the evolution of this important MDR pathogen.';
}

sub build_attributes {
    return {
#     Set like this:
#       foo => 'bar',
#       x => 'y',
    };
}

sub build_sample {
  print "build_sample not implemented yet.";
  return {};
}



sub construct {

  my $self = shift;

  use BRAEMBL::ENA::Rest::Study;
  my $study = BRAEMBL::ENA::Rest::Study->new();
  
  # List of Moose::Meta::Attribute
  #
  my @attribute = $study->meta->get_all_attributes;
  
  foreach my $current_attribute (@attribute) {
  
    my $attribute_name = $current_attribute->name;
    my $build_method   = "build_${attribute_name}";
    
    $study->$attribute_name( $self->$build_method );
  }  
  
  return $study; 

}


1;
