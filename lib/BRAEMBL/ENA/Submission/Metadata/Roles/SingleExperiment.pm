package BRAEMBL::ENA::Submission::Metadata::Roles::SingleExperiment;

use Moose::Role;
use BRAEMBL::ENA::Submission::Metadata::TypeConstraints;

with 'BRAEMBL::ENA::Submission::Metadata::Roles::Library';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::PairedEnd';

has 'instrument_model' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'platform' => (
  is      => 'rw', 
  isa     => 'platform_type',
);

has 'reads_produced' => (
  is      => 'rw', 
  isa     => 'references_by_id',
  coerce  => 1,
);

1;
