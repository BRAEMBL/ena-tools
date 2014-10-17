package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::DomainObjectBuilder::ExperimentBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'refname' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'refcenter' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'design' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'run' => (
  is      => 'rw', 
  isa     => 'ArrayRef[BRAEMBL::ENA::Rest::Run]',
  default => sub { return [] },
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

sub build_platform {
  my $self = shift;
  return $self->metadata->platform;
}

sub build_library_layout {
  my $self = shift;
  return $self->metadata->library_layout;
}

sub build_instrument_model {
  my $self = shift;
  return $self->metadata->instrument_model;
}

sub build_library_name {
  my $self = shift;
  return $self->metadata->library_name;
}

sub build_library_strategy {
  my $self = shift;
  return $self->metadata->library_strategy;
}

sub build_library_source {
  my $self = shift;
  return $self->metadata->library_source;
}

sub build_library_selection {
  my $self = shift;
  return $self->metadata->library_selection;
}

sub build_library_layout_paired_nominal_length {

  my $self = shift;  
  my $sample_id = shift;
  return $self->metadata->insert_length->{$sample_id};
}

sub build_library_layout_paired_stddev {

  my $self = shift;  
  return;
}

sub build_refname {
  my $self = shift;
  my $sample_id = shift;
  return join '-', 'EXPERIMENT', $self->metadata->center_name, $self->study->alias, $sample_id;
}

sub build_center {
  my $self = shift;
  return $self->metadata->center_name;
}

sub build_design {
  my $self = shift;
  return {
      design_description => '',
  };
}

sub build_run {
  my $self = shift;
  return $self->run;
}

sub construct {

    my $self      = shift;
    my $sample_id = shift;

    use BRAEMBL::ENA::Rest::Experiment;
    my $obj = BRAEMBL::ENA::Rest::Experiment->new();

    my @attribute = $obj->meta->get_all_attributes;
  
    foreach my $current_attribute (@attribute) {

        my $attribute_name = $current_attribute->name;
        my $build_method   = "build_${attribute_name}";

        $obj->$attribute_name( $self->$build_method($sample_id) );
    }  
    return $obj;
  
}

1;
