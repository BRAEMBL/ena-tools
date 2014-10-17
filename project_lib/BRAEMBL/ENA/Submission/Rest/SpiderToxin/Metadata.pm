package BRAEMBL::ENA::Submission::Rest::SpiderToxin::Metadata;

use Moose;

with 'BRAEMBL::ENA::Submission::Metadata::Roles::Common';
with 'BRAEMBL::ENA::Submission::Rest::SpiderToxin::SingleSpecies';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::SingleExperiment';

has 'read_files' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

1
;
