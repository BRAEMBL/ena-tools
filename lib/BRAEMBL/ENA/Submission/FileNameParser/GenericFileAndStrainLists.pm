package BRAEMBL::ENA::Submission::FileNameParser::GenericFileAndStrainLists;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'id__to__strain_id' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {       
      my $self = shift;
      return $self->metadata->strain_ids;
  },
);

has 'read_files__to__id' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { 
      my $self = shift;
      my %x = reverse %{$self->metadata->read_files};
      return \%x;
  },
);

sub parse_strain_name {

    my $self = shift;
    my $name = shift;

    if (!exists $self->read_files__to__id->{$name}) {
        confess(
            "Unknown file $name has to be one of " . ( join ', ', sort values %{$self->metadata->read_files} )
        );
    }
    
    my $id = $self->read_files__to__id->{$name};

    if (!exists $self->id__to__strain_id->{$id}) {
        confess(
            "Unknown id $id!"
        );
    }
    my $strain_name = $self->id__to__strain_id->{$id};
    
    return $strain_name;
}

sub create_run_identifier {
    confess("Must be overridden by subclass!");
}

sub parse {

    my $self = shift;
    my $name = shift;
    
    my $strain_name    = $self->parse_strain_name($name);
    my $run_identifier = $self->create_run_identifier($name);
        
    my $result = {
        strain_name    => $strain_name,
        run_identifier => $run_identifier
    };

    use Hash::Util qw( lock_keys );
    lock_keys(%$result);

    return $result;
};

1
;