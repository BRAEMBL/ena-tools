package BRAEMBL::ENA::Submission::Rest::DefaultStudyType1::DomainObjectBuilder::ExperimentBuilder;

use Moose;
use BRAEMBL::DefaultLogger;

has 'metadata' => (
  is      => 'rw', 
);

has 'known_runs' => (
  is      => 'rw', 
  isa     => 'HashRef[BRAEMBL::ENA::Rest::Run]',
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
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->platform;
}

sub build_center {
  shift->metadata->center_name;
}

sub build_library_layout {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_layout;
}

sub build_instrument_model {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->instrument_model;
}

sub build_library_name {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_name;
}

sub build_library_strategy {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_strategy;
}

sub build_library_source {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_source;
}

sub build_library_selection {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_selection;
}

sub build_library_layout_paired_nominal_length {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_layout_paired_nominal_length;
}

sub build_library_layout_paired_stddev {
  my $self           = shift;
  my $experiment_key = shift;
  $self->metadata->experiment->{$experiment_key}->library_layout_paired_stddev;
}

sub build_attributes {
  my $self           = shift;
  my $experiment_key = shift;
  
  if ($self->metadata->experiment_attributes) {
    $self->metadata->experiment_attributes->{$experiment_key};
  }
}

sub build_refname {
  my $self = shift;
  my $experiment_name = shift;
  
  #return "Experiment ". $experiment_name ." by " . $self->metadata->center_name . ", " . $self->study->alias;
  return join ', ', 
    $self->metadata->center_name,
    $self->study->alias,
    "experiment ". $experiment_name;
}

sub build_refcenter {
  shift->study->center_name;
}

sub build_design {
  my $self = shift;
  return {
      design_description => '',
  };
}

sub build_run {  

  my $self            = shift;
  my $experiment_name = shift;
  
  my $reads_produced = $self->metadata->experiment->{$experiment_name}->{reads_produced};
  confess('Type error!') unless(ref $reads_produced eq 'ARRAY');
  
  my @runs_from_current_experiment;
  
  foreach my $current_read_id (@$reads_produced) {
    push @runs_from_current_experiment, $self->known_runs->{$current_read_id};
  }
  return \@runs_from_current_experiment;
}

sub construct {

    my $self = shift;
    
    my @experiment_name = keys %{$self->metadata->experiment};
    my %experiment_list;

    foreach my $current_experiment_name (@experiment_name) {
    
      use BRAEMBL::ENA::Rest::Experiment;
      my $obj = BRAEMBL::ENA::Rest::Experiment->new();
      my @attribute = $obj->meta->get_all_attributes;
      my $logger = &get_logger;  
    
      foreach my $current_attribute (@attribute) {

	  my $attribute_name = $current_attribute->name;
	  my $build_method   = "build_${attribute_name}";
	  
	  if ($self->can($build_method)) {
	  
	    my $attribute_value = $self->$build_method($current_experiment_name);

	    if ($attribute_value) {
	      $obj->$attribute_name( $attribute_value );
	    }

	  } else {
	    $logger->warn("Building $attribute_name is not supported.");
	  }
      }
      $experiment_list{$current_experiment_name} = $obj;
    }
    return \%experiment_list;
  
}

1;
