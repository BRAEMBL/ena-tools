package BRAEMBL::ENA::Submission::Rest::CoralGenome::DomainObjectBuilder::RunBuilder;

use Moose;
use BRAEMBL::ENA::Rest::Run;
use BRAEMBL::ENA::Rest::File;

has 'metadata' => (
  is      => 'rw', 
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

has 'compute_md5' => (
  is      => 'rw', 
  isa     => 'Bool',
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
  my $read_file_id = shift;
  return join ', ', 
        $self->metadata->center_name, 
	$self->study->alias,
	'run ' . $read_file_id
  ;
}

sub build_center_name {
  my $self = shift;
  return $self->metadata->center_name;
}

sub build_run_center {
  my $self = shift;
  return $self->metadata->run_center;
}

has 'product' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'BRAEMBL::ENA::Rest::Run',
);

sub construct {

    my $self = shift;
    
    my $run_hash = {};
    
    my %read_files     = %{$self->metadata->read_files};
    my %read_files_ftp = %{$self->metadata->read_files_ftp};
    
    use BRAEMBL::DefaultLogger;
    my $logger = &get_logger;


    # Create a run object for every set of read files
    #
    foreach my $current_read_file_id (keys %read_files) {
    
      # The alias depends on the file names, so has to be built first.
      #my @attribute_name = ('file', 'center_name', 'alias', 'run_center');
      my @attribute_name = ('center_name', 'alias', 'run_center');
      
      my $obj = BRAEMBL::ENA::Rest::Run->new();
    
      foreach my $current_attribute_name (@attribute_name) {

	  my $build_method   = "build_${current_attribute_name}";

	  $obj->$current_attribute_name( 
	    $self->$build_method(
	      $obj, 
	      $current_read_file_id
	    ) 
	  );	  
      }
      
      my @file_list;
      for(my $file_index=0; $file_index<@{$read_files{$current_read_file_id}}; $file_index++) {
      
	my $current_local_file_name = $read_files{$current_read_file_id}->[$file_index];
	
	my $md5 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
	if ($self->compute_md5) {
	
	  # This can take some time, so user should be kept updated.
	  $logger->info("Computing md5 sum for " . $current_local_file_name);
	
	  open (my $fh, '<', $current_local_file_name) or die "Can't open '$current_local_file_name': $!";
	  binmode ($fh);
	  $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
	  close $fh;
	}
      
	push @file_list, BRAEMBL::ENA::Rest::File->new(
	  local_file_name => $current_local_file_name,
	  ftp_file_name   => $read_files_ftp{$current_read_file_id}->[$file_index],
	  file_name_parser => sub { return { run_identifier => shift }; },
	  checksum => $md5,
	);
      }
      
      $obj->file(\@file_list);

      $run_hash->{$current_read_file_id} = $obj;      
    }
    return $run_hash;
}

1;
