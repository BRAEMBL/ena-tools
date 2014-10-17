package BRAEMBL::ENA::Submission::Rest::BacterialStrains::DomainObjectBuilder::Director;

use Moose;

has 'ena_object_builders' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

has 'compute_md5' => (
  is      => 'rw', 
  isa     => 'Bool',
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
    
    $self->read_sample_data_from_directory(
        $study,
    );
    
    use Hash::Util qw( lock_keys );
    lock_keys(%$study);

}

sub read_sample_data_from_directory {

    my $self = shift;

    my $study           = shift;

    use BRAEMBL::DefaultLogger;
    my $logger = &get_logger;

    my @file_list = $self->file_list_builder->build;    
    #use Data::Dumper;    print Dumper(\@file_list);
    
    #FILE: foreach my $f (@file_list) {
    FILE: foreach my $file_id (keys %{$self->file_list_builder->read_files}) {
    
	my $f = $self->file_list_builder->read_files->{$file_id};
                
        my $parsed_file_name = $self->file_name_parser->parse($f);
        my $strain_name      = $parsed_file_name->{strain_name};
        
        $logger->info("Processing $f strain: $strain_name");

        my $local_file_name = $f;
        use File::Basename;
        my $ftp_file_name   =  $self->file_list_builder->read_files_ftp->{$file_id};
        
#         my $ftp_file_name   = File::Spec->join(
#             $self->ftp_path->( $f ), 
#         );
        
        my $md5;
        if ($self->compute_md5) {
            open (my $fh, '<', $local_file_name) or die "Can't open '$local_file_name': $!";
            binmode ($fh);
            $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
            close $fh;
        } else {
            $md5 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        }
                
        if (!exists $study->sample->{$strain_name}) {

            $self->run_builder        ->strain_name($strain_name);
            $self->experiment_builder ->strain_name($strain_name);
            $self->sample_builder     ->strain_name($strain_name);
            
            # Clear the previous run from the builder
            $self->experiment_builder->run([]);
            
            my $current_experiment = $self->experiment_builder->construct;

            $self->sample_builder->experiment($current_experiment);            
            my $sample = $self->sample_builder->construct();
            
            $study->sample->{$strain_name} = $sample;
        }
        
        use BRAEMBL::ENA::Rest::File;
        my $current_file = BRAEMBL::ENA::Rest::File->new();

        $current_file->file_name_parser( 
            sub { 
                my $file_name = shift;
                return $self->file_name_parser->parse($file_name);
            }
        );
        $current_file->local_file_name( $f );
        $current_file->ftp_file_name( $ftp_file_name );
        $current_file->checksum( $md5 );

        #push @{$study->sample->{$strain_name}->experiment->run->file}, $current_file;
        
        my $files_are_paired_end = 1;        
        my $a_run_with_this_strain_already_exists = scalar @{$study->sample->{$strain_name}->experiment->[0]->run} > 0;
        
        if ($files_are_paired_end && $a_run_with_this_strain_already_exists) {
        
          #push @{$current_run->file}, $current_file;
          push @{$study->sample->{$strain_name}->experiment->[0]->run->[0]->file}, $current_file;
          
        } else {
            $self->run_builder->strain_name($strain_name);
            $self->run_builder        ->file([ $current_file ]);

            my $current_run = $self->run_builder->construct;
            #push @{$current_run->file}, $current_file;
            
            push @{$study->sample->{$strain_name}->experiment->[0]->run}, $current_run;

        }
        

    }
    return $study;
}



1;
