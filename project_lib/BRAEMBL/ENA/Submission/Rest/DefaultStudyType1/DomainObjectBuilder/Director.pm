package BRAEMBL::ENA::Submission::Rest::DefaultStudyType1::DomainObjectBuilder::Director;

use Moose;
use Data::Dumper;

has 'metadata' => (
  is      => 'rw', 
);

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
);

has 'sample_builder' => (
  is      => 'rw', 
);

has 'experiment_builder' => (
  is      => 'rw', 
);

has 'run_builder' => (
  is      => 'rw', 
);

has 'file_list_builder' => (
  is      => 'rw', 
);

has 'file_name_parser' => (
  is      => 'rw', 
  default => sub {
      confess("The director has to be provided with a file name parser!");
  },
);

sub construct {

    my $self        = shift;

    use BRAEMBL::DefaultLogger;
    my $logger = &get_logger;

    $self->study_builder(      $self->ena_object_builders->{study_builder} );
    $self->sample_builder(     $self->ena_object_builders->{sample_builder} );
    $self->experiment_builder( $self->ena_object_builders->{experiment_builder} );
    $self->run_builder(        $self->ena_object_builders->{run_builder} );

    my $study = $self->study_builder->construct();

    $self->sample_builder->study($study);
    $self->experiment_builder->study($study);
    $self->run_builder->study($study);    
    
    my $run = $self->run_builder->construct;
    #print Dumper($run); exit;
    
    my $experiment_builder = $self->experiment_builder;
    $experiment_builder->known_runs($run);
    
    my $experiment = $experiment_builder->construct;
    #print Dumper($experiment); exit;
    
    # Create a new sample
    my $sample = $self->sample_builder->construct();
    #print Dumper($sample); exit;
    
    foreach my $sample_key (sort keys %$sample) {
    
      #$logger->info("Processing sample $sample_key");
    
      my @referenced_experiment_id = @{$sample->{$sample_key}->{experiment_id}};
      my @referenced_experiment;
      
      foreach my $experiment_id (@referenced_experiment_id) {
      
	my $current_experiment = $experiment->{$experiment_id};
	
	if (!defined $current_experiment) {
	  $logger->warn("An experiment with id $experiment_id is referenced by a sample, but it doesn't exist!");
	} else {	
	  push @referenced_experiment, $current_experiment
	}
      }
      #print Dumper(\@referenced_experiment); exit;
      $sample->{$sample_key}->experiment(\@referenced_experiment);
    }
    
    $study->sample($sample);
    
    use Hash::Util qw( lock_keys );
    lock_keys(%$study);
}

1;
