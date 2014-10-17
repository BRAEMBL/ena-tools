package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::DomainObjectBuilder::Director;

use Moose;

has 'ena_object_builders' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'compute_md5' => (
  is      => 'rw', 
  isa     => 'Bool',
);

has 'metadata' => (
  is      => 'rw', 
);

has 'ftp_path' => (
  is      => 'rw', 
  isa     => 'CodeRef',
);

has 'study_builder' => (
  is      => 'rw', 
#   isa     => 'BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::StudyBuilder',
);

has 'sample_builder' => (
  is      => 'rw', 
#   isa     => 'BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::SampleBuilder',
);

has 'experiment_builder' => (
  is      => 'rw', 
#   isa     => 'BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::ExperimentBuilder',
);

has 'run_builder' => (
  is      => 'rw', 
#   isa     => 'BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::RunBuilder',
);

has 'file_list_builder' => (
  is      => 'rw', 
#   isa     => 'BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::RunBuilder',
);

has 'file_name_parser' => (
  is      => 'rw', 
#  isa     => 'CodeRef',
  default => sub {
      confess("The director has to be provided with a file name parser!");
  },
);

sub construct {

    my $self        = shift;
   
    $self->study_builder(      $self->ena_object_builders->{study_builder} );
    $self->sample_builder(     $self->ena_object_builders->{sample_builder} );
    $self->experiment_builder( $self->ena_object_builders->{experiment_builder} );
    $self->run_builder(        $self->ena_object_builders->{run_builder} );

    my $study = $self->study_builder->construct();

    $self->sample_builder->study($study);
    $self->experiment_builder->study($study);
    $self->run_builder->study($study);    
    
    $self->create_study_related_objects($study);
    
    use Hash::Util qw( lock_keys );
    lock_keys(%$study);

}

sub create_study_related_objects {

    my $self = shift;

    my $study           = shift;

    use BRAEMBL::DefaultLogger;
    my $logger = &get_logger;

    #my @file_list = $self->file_list_builder->build;
    my $sample_id_to_name = $self->metadata->sample_ids;
    
    FILE: foreach my $current_sample_id (keys %$sample_id_to_name) {
    
	$self->run_builder->reset;
        
        my $sample_name = $sample_id_to_name->{$current_sample_id};
        
        $logger->info("Processing $sample_name");
        
        # Clear the previous run from the builder, if there was one.
        $self->experiment_builder->run([]);
        
        # Build experiment object
        my $current_experiment = $self->experiment_builder->construct($current_sample_id);

        # Set this as the current experiment.
        #
        # This makes the link sample -> experiment
        #
        $self->sample_builder->experiment($current_experiment);            
        
        # Create a new sample
        my $sample = $self->sample_builder->construct($current_sample_id);
        
        # Link this new sample to the current study, there might be more than 
        # one, so put in hash and index with the current species name.
        #
        # This extends the link to study -> sample -> experiment
        #
        $study->sample->{$current_sample_id} = $sample;

         my $local_file_names = $self->metadata->read_files->{$current_sample_id};
         
	 for my $current_local_file_name (@$local_file_names) {
	 
	    use BRAEMBL::ENA::Rest::File;
	    my $current_file = BRAEMBL::ENA::Rest::File->new();
	    
	    $current_file->file_name_parser( 
		sub { 
		    my $file_name = shift;
		    return $self->file_name_parser->parse($file_name);
		}
	    );
	    use File::Basename;	    
	    my $current_local_file_name_base = basename($current_local_file_name);
	    
	    my @matching_ftp_file_names = 
	      grep { $_=~/$current_local_file_name_base$/ } @{$self->metadata->read_files_ftp->{$current_sample_id}}; 
	    ;
	    if (@matching_ftp_file_names!=1) {
	      use Data::Dumper;
	      confess("Problem matching up local files with ftp files with sample_id $current_sample_id!\n" . Dumper($self->metadata->read_files_ftp) );
	    }
	    my $ftp_file_name = $matching_ftp_file_names[0];
	    
	    my $md5;
	    if ($self->compute_md5) {
	      open (my $fh, '<', $current_local_file_name) or die "Can't open '$current_local_file_name': $!";
	      binmode ($fh);
	      $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
	      close $fh;
	    } else {
	      $md5 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
	    }
	    $current_file->local_file_name( $current_local_file_name );
	    $current_file->ftp_file_name( $ftp_file_name );
	    $current_file->checksum( $md5 );
	    
	    push @{$self->run_builder->file}, $current_file;
         }

        my $current_run = $self->run_builder->construct;        
        
        # Finally: study -> sample -> experiment -> run -> file
        #
        push @{$study->sample->{$current_sample_id}->experiment->[0]->run}, $current_run;
    }
    return $study;
}

1;
