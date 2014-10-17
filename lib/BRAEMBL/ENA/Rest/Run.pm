package BRAEMBL::ENA::Rest::Run;

use Moose;

has 'alias' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

# Obsolete
has 'center_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'run_center' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'file' => (
  is      => 'rw', 
  isa     => 'ArrayRef[BRAEMBL::ENA::Rest::File]',
  default => sub { return [] },
);

1;
