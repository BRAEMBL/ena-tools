package BRAEMBL::ENA::Rest::Study;

use Moose;
use BRAEMBL::ENA::Submission::Metadata::TypeConstraints;

has 'alias' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'center_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'broker_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'title' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'hold_until_date' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'existing_study_type' => (
  is      => 'rw', 
  isa     => 'existing_study_type',,
);

has 'abstract' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',
  default => sub { return {} },
);


=head2 sample

    http://www.ebi.ac.uk/ena/about/read_validation
    
    maps from the strain name to the sample object.

=cut
has 'sample' => (
  is      => 'rw', 
  isa     => 'HashRef[BRAEMBL::ENA::Rest::Sample]',
  default => sub { return {} },
);



1;
