package BRAEMBL::ENA::Submission::Metadata::Roles::MultipleExperiments;

use Moose::Role;
use BRAEMBL::ENA::Submission::Metadata::TypeConstraints;
use BRAEMBL::ENA::Submission::Metadata::SingleExperiment;

has 'experiment' => (
  is      => 'rw', 
  isa     => 'HashRefOfExperiments',
  coerce  => 1,
);

1;
