package BRAEMBL::ENA::Submission::Rest::CoralGenome::FileListBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'read_files' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return $self->metadata->read_files;        
  },
);

sub build {
  my $self = shift;  
  return values %{$self->read_files};
}


1
;