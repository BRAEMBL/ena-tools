package BRAEMBL::ENA::Submission::Rest::BacterialStrains::BacterialRnaSeqFiles;

use Moose::Role;

has 'read_files' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'read_files_ftp' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'ftp_path' => (
  is      => 'rw', 
  isa     => 'CodeRef',
  lazy    => 1,
  default => sub {

      my $self = shift;
  
      my $read_files = $self->read_files;
      
      if (! defined $read_files) {
          confess("No read files defined!");
      }
      
      my %file_to_id = reverse %{$read_files};
      my $id_to_ftp_path = $self->read_files_ftp;
      
      my $local_path_to_ftp_path = transitive_hash(\%file_to_id, $id_to_ftp_path);
  
      return sub {        
        my $file = shift;        
        if (! exists $local_path_to_ftp_path->{$file} ) {
          confess("No ftp path configured for $file!");
        }        
        return $local_path_to_ftp_path->{$file};        
      } 
  }
);

sub transitive_hash {

  my $first  = shift;
  my $second = shift;

  my %transitive_hash;
  foreach my $key (keys %$first) {

    if ( ! exists $second->{$first->{$key}}  ) {
      confess("No value for $first->{$key} in second hash!");
    }
    $transitive_hash{$key} = $second->{$first->{$key}};
  }
  return \%transitive_hash;
}


1;
