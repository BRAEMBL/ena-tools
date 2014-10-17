package BRAEMBL::ENA::Submission::Metadata::Roles::Library;

use Moose::Role;
use BRAEMBL::ENA::Submission::Metadata::TypeConstraints;

has 'instrument_model' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'library_name' => (
  is      => 'rw', 
);

has 'library_strategy' => (
  is      => 'rw', 
  isa     => 'library_strategy_type',
);

has 'library_source' => (
  is      => 'rw', 
);

has 'library_selection' => (
  is      => 'rw', 
  isa     => 'library_selection_type',
);

has 'library_layout' => (
  is      => 'rw', 
#  isa     => 'library_layout_type',
);

has 'library_layout_paired_nominal_length' => (
  is      => 'rw', 
);

has 'library_layout_paired_stddev' => (
  is      => 'rw', 
);

1;
