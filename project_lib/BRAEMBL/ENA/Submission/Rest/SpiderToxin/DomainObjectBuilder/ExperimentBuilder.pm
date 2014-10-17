package BRAEMBL::ENA::Submission::Rest::SpiderToxin::DomainObjectBuilder::ExperimentBuilder;

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
  shift->metadata->platform;
}

sub build_center {
  shift->metadata->run_center;
}

sub build_library_layout {
  shift->metadata->library_layout;
}

sub build_instrument_model {
  shift->metadata->instrument_model;
}

sub build_library_name {
  shift->metadata->library_name;
}

sub build_library_strategy {
  shift->metadata->library_strategy;
}

sub build_library_source {
  shift->metadata->library_source;
}

sub build_library_selection {
  shift->metadata->library_selection;
}

sub build_library_layout_paired_nominal_length {}

sub build_library_layout_paired_stddev {}

sub build_refname {
  my $self = shift;
  return join '-', 'EXPERIMENT', $self->metadata->center_name, $self->study->alias;
}

sub build_refcenter {
  shift->study->center_name;
}

sub build_attributes {
  my $logger = &get_logger;  
  $logger->info("Experiment attributes are not used for spider submissions.");
  return {};
}

sub build_design {
  my $self = shift;
  return {
      design_description => '',
  };
}

sub build_run {  
  shift->run;
}

sub construct {

    my $self = shift;

    use BRAEMBL::ENA::Rest::Experiment;
    my $obj = BRAEMBL::ENA::Rest::Experiment->new();

    my @attribute = $obj->meta->get_all_attributes;
    my $logger = &get_logger;  
  
    foreach my $current_attribute (@attribute) {

        my $attribute_name = $current_attribute->name;
        my $build_method   = "build_${attribute_name}";

	if ($self->can($build_method)) {
	  $obj->$attribute_name( $self->$build_method );
	} else {
	    $logger->warn("Building $attribute_name is not supported.");
	}

    }  
    return $obj;
  
}

1;
