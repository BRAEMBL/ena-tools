package BRAEMBL::ENA::Submission::Metadata::Roles::PairedEnd;

use Moose::Role;

has 'insert_length' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'insert_stddev' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

1;
