package BRAEMBL::ENA::Submission::Rest::CoralGenome::Metadata;

use Moose;

with 'BRAEMBL::ENA::Submission::Metadata::Roles::Common';
with 'BRAEMBL::ENA::Submission::Rest::CoralGenome::SingleSpecies';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::MultipleExperiments';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::PairedEnd';

has 'read_files' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'read_files_ftp' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

1
;
