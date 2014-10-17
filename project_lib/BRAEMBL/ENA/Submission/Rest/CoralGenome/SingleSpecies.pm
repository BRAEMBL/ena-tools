package BRAEMBL::ENA::Submission::Rest::CoralGenome::SingleSpecies;

use Moose::Role;
  
has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

1
;
