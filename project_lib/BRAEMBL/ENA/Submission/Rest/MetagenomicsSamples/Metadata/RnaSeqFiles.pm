package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::Metadata::RnaSeqFiles;

use Moose::Role;

has 'read_files_trigger_active' => (
  is      => 'rw', 
  isa     => 'Bool',
  default => 0,
);

has 'read_files' => (
  is      => 'rw', 
  #isa     => 'HashRef',
  trigger => sub {
  
    my $self  = shift;
    my $value = shift;
    
    if ($self->read_files_trigger_active) {
      return;
    }
    $self->read_files_trigger_active(1);
    
    if (ref $value eq 'ARRAY') {
      if (@$value==1) {
	$self->read_files($value->[0]);
      } else {
        confess('Configuration error for read_files!');
      }
    } 
    $self->read_files_trigger_active(0);
  }
);

has 'read_files_ftp' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

1;
