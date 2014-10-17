package BRAEMBL::ENA::Rest::File;

use Moose;

has 'local_file_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'ftp_file_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'checksum' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);

has 'file_name_parser' => (
  is      => 'rw', 
  isa     => 'CodeRef',
  lazy    => 1,
  default => sub { confess('file_name_parser has not been set!'); },
  trigger => sub {
      my $self  = shift;
      my $value = shift;
      
      confess('Type error') unless (ref $value eq 'CODE');
  }
);
  
sub component {
    my $self = shift;
    return $self->file_name_parser->($self->local_file_name);
}
  
1;
