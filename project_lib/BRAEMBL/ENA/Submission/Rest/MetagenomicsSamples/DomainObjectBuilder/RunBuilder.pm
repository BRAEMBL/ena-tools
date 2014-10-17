package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::DomainObjectBuilder::RunBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

sub generate_fileset_id {
  my $self = shift;  
  my $run  = shift;
  
  my @all_ids;
  foreach my $current_file (@{$run->file}) {  
  
      confess('Type error!') unless ($current_file->isa('BRAEMBL::ENA::Rest::File'));
  
      push @all_ids, $current_file->component->{run_identifier};
  }
  my $fileset_id = join '_', @all_ids;
  return $fileset_id;

}

sub build_alias {
  my $self = shift;
  my $run  = shift;
  return join '-', 
      'RUN', 
        $self->metadata->center_name, 
        $self->study->alias, 
        $self->generate_fileset_id($run)
  ;
}

sub build_center_name {
  my $self = shift;  
  
  my $center_name = $self->metadata->run_center;
  
  use BRAEMBL::DefaultLogger;
  
  if (!$center_name) {
    get_logger->error("Run center has not been set!");
  }
  
  return $self->metadata->run_center;
}

has 'file' => (
  is      => 'rw', 
  isa     => 'ArrayRef[BRAEMBL::ENA::Rest::File]',
  default => sub { return [] },
);

sub build_file {
  my $self = shift;
  return $self->file;
}

use BRAEMBL::ENA::Rest::Run;

has 'product' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'BRAEMBL::ENA::Rest::Run',
);

sub reset {
    my $self = shift;
    $self->file([]);
}

sub construct {

    my $self = shift;

    my $obj = BRAEMBL::ENA::Rest::Run->new();

    # The alias depends on the file names, so has to be built first.
    #my @attribute_name = ('file', 'center_name', 'alias', 'run_center');
    my @attribute_name = ('file', 'center_name', 'alias');
  
    foreach my $current_attribute_name (@attribute_name) {
        my $build_method   = "build_${current_attribute_name}";
        $obj->$current_attribute_name( $self->$build_method($obj) );
    }  
    return $obj;  
}

1;
