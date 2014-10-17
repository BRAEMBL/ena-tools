package BRAEMBL::ENA::Submission::Rest::BacterialStrains::DomainObjectBuilder::ExperimentBuilder;

use Moose;
use BRAEMBL::DefaultLogger;

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

has 'strain_name' => (
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
  
  my $strain_name = $self->strain_name;
  
  my $insert_length = $self->metadata->insert_length;
  
  my $library_layout_paired_nominal_length;
  
  if (ref $insert_length eq 'HASH') {
      $library_layout_paired_nominal_length = $self->metadata->insert_length->{$strain_name};
  } else {
       $library_layout_paired_nominal_length = $self->metadata->insert_length;
  }  
  
  if (!$library_layout_paired_nominal_length) {
      use Data::Dumper;
      print Dumper($self->metadata->insert_length);
      confess("Couldn't get an insert length for $strain_name!");
  }  
  my $library_layout_paired_nominal_length_rounded = sprintf("%.0f", $library_layout_paired_nominal_length);
  
  return $library_layout_paired_nominal_length_rounded;
}

sub build_library_layout_paired_stddev {

  my $self = shift;
  
  my $strain_name = $self->strain_name;
  
  my $insert_stddev = $self->metadata->insert_stddev;
  
  my $library_layout_paired_stddev;
  
  if (ref $insert_stddev eq 'HASH') {
      $library_layout_paired_stddev = $self->metadata->insert_stddev->{$strain_name};
  } else {
       $library_layout_paired_stddev = $self->metadata->insert_stddev;
  }  
  
  if (!$library_layout_paired_stddev) {
      use Data::Dumper;
      print Dumper($self->metadata->insert_stddev);
      confess("Couldn't get an insert stddev for $strain_name!");
  }  
  
  return $library_layout_paired_stddev;
}

sub build_refname {
  my $self = shift;
  return join '-', 'EXPERIMENT', $self->metadata->center_name, $self->study->alias, $self->strain_name;
}

sub build_refcenter {
  my $self = shift;
  return $self->study->center_name;
}

sub build_center {
  my $self = shift;
  return $self->study->center_name;
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

    my $self = shift;

    use BRAEMBL::ENA::Rest::Experiment;
    my $obj = BRAEMBL::ENA::Rest::Experiment->new();

    my @attribute = $obj->meta->get_all_attributes;
  
    foreach my $current_attribute (@attribute) {

        my $attribute_name = $current_attribute->name;
        my $build_method   = "build_${attribute_name}";
	
	if ($self->can($build_method)) {
	  $obj->$attribute_name( $self->$build_method );
	} else {
	    my $logger = &get_logger;  
	    $logger->warn("Building $attribute_name is not supported.");
	}
    }  
    return $obj;
  
}

1;
