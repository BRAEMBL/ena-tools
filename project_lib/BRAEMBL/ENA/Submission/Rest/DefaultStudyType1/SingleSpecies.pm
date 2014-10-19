package BRAEMBL::ENA::Submission::Rest::DefaultStudyType1::SingleSpecies;

use Moose::Role;
  
has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

1
;
