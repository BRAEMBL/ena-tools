package BRAEMBL::ENA::Rest::Sample;

use Moose;

# Currently used for naming samples, not used for submission, just for keeping track of the sample when debugging.
has 'internal_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'alias' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
  #default => undef,
);

has 'attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',
  default => sub { return {} },
);

has 'attribute_units' => (
  is      => 'rw', 
  isa     => 'HashRef',
  default => sub { return {} },
);

use Moose::Util::TypeConstraints;

has 'common_name' => (
  is      => 'rw', 
  isa     => maybe_type ('Str'),
  #default => 'not set',
);

has 'description' => (
  is      => 'rw', 
  isa     => 'Str',
  #default => 'not set',
);

has 'title' => (
  is      => 'rw', 
  isa     => 'Str',
  #default => 'not set',
);

has 'taxon_id' => (
  is      => 'rw', 
  isa     => 'Str',
  #default => 'not set',
);

use Moose::Util::TypeConstraints;

subtype 'Array_of_experiments',
    as 'ArrayRef[BRAEMBL::ENA::Rest::Experiment]';

coerce 'Array_of_experiments',
    from 'BRAEMBL::ENA::Rest::Experiment',
    via { [ $_ ] };

has 'experiment' => (
  is      => 'rw', 
  isa     => 'Array_of_experiments',
  coerce  => 1,
);

subtype 'array_of_experiment_ids',
    as 'ArrayRef[Str]';

coerce 'array_of_experiment_ids',
    from 'Str',
    via { [ split ',', $_ ] };

coerce 'array_of_experiment_ids',
    from 'Undef',
    via { [] };

has 'experiment_id' => (
  is      => 'rw', 
  isa     => 'array_of_experiment_ids',
  coerce  => 1,
  default => sub { [] },

);

1;

