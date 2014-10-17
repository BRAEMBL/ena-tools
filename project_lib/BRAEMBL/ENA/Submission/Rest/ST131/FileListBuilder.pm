package BRAEMBL::ENA::Submission::ST131::FileListBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

sub build {

  my $self      = shift;
  my $read_dir  = $self->metadata->read_dir;
  
  my @file_list;

  use BRAEMBL::DefaultLogger;
  my $logger = &get_logger;

  opendir(D, $read_dir) || confess "Can't open directory $read_dir: $!\n";
  my @list = readdir(D);
  closedir(D);

  FILE: foreach my $f (@list) {
    next FILE if $f =~ /^\.+$/;
    push @file_list, $read_dir . '/' . $f;
  }

  return @file_list;
}


1
;