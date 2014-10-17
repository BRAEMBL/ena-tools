package BRAEMBL::ENA::Submission::Rest::BacterialStrains::BacterialMetadata;

use Moose::Role;

has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'scientific_name_base' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'strain_ids' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

1;
