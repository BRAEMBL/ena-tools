package BRAEMBL::ENA::Rest::Experiment;

use Moose;
use BRAEMBL::ENA::Submission::Metadata::TypeConstraints;

has 'refname' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'center' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'design' => (
  is      => 'rw', 
  isa     => 'HashRef',
  default => sub { return {} },
);

has 'run' => (
  is      => 'rw', 
  isa     => 'ArrayRef[BRAEMBL::ENA::Rest::Run]',
  default => sub { return [] },
);

has 'library_name' => (
  is      => 'rw', 
  #default => 'not set',
);

has 'library_strategy' => (
  is      => 'rw', 
  #default => 'not set',
);

has 'library_source' => (
  is      => 'rw', 
  #default => 'not set',
);

has 'library_selection' => (
  is      => 'rw', 
  #default => 'not set',
);

has 'library_layout_paired_nominal_length' => (
  is      => 'rw', 
  isa     => 'Num',
);

has 'library_layout_paired_stddev' => (
  is      => 'rw', 
  isa     => 'Num',
);

has 'instrument_model' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'platform' => (
  is      => 'rw', 
  # Doesnt work, no idea, why
  #isa     => 'platform_type',
);

has 'library_layout' => (
  is      => 'rw', 
  # Doesnt work, no idea, why
  #isa     => 'library_layout_type',
);

has 'attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',
  default => sub { return {} },
);

1;
