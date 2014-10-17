package BRAEMBL::ENA::Submission::Rest::SpiderToxin::SingleSpecies;

use Moose::Role;
  
has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

1
;
