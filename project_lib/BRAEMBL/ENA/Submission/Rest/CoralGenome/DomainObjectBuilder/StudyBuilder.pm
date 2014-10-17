package BRAEMBL::ENA::Submission::Rest::CoralGenome::DomainObjectBuilder::StudyBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

sub build_alias {
    my $self = shift;
    return $self->metadata->study_alias;
}

sub build_center_name {
    my $self = shift;
    return $self->metadata->center_name;
}

sub build_broker_name {
    my $self = shift;
    return $self->metadata->broker_name;
}

sub build_title {
    my $self = shift;
    return $self->metadata->title;
}

sub build_hold_until_date {
    my $self = shift;
    return $self->metadata->hold_until_date;
}

sub build_existing_study_type {
    my $self = shift;
    return $self->metadata->existing_study_type;
}

sub build_abstract {
    my $self = shift;
    return $self->metadata->abstract;
}

sub build_attributes {
    return {
#     Set like this:
#       foo => 'bar',
#       x => 'y',
    };
}

sub build_sample {

  use BRAEMBL::DefaultLogger;
  my $logger = &get_logger;
  $logger->debug('Samples are not built by this builder.');
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
