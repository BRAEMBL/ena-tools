package BRAEMBL::ENA::Submission::Serialiser;

use Moose;

has 'no_md5' => (
  is      => 'rw', 
  isa     => 'Bool',
  trigger => sub {
    my $self  = shift;
    $self->compute_md5(!$self->compute_md5);
  },
  default => 1,
);

has 'compute_md5' => (
  is      => 'rw', 
  isa     => 'Bool',
  default => 1,
  
);

has 'template_dir' => (
  is       => 'rw', 
  isa      => 'Str',
  required => 1,
);

has 'output_dir' => (
  is       => 'rw', 
  isa      => 'Str',
  required => 1,
);

sub serialise_study {

    my $self = shift;
    my $param = shift;

    my $metadata     = $param->{metadata};
    my $format       = $param->{format};
    my $compute_md5  = $param->{compute_md5};
    my $reporter     = $param->{reporter};

    my $template_dir = $self->template_dir;
    my $output_dir   = $self->output_dir;
    my $study        = $param->{study};
    
    use BRAEMBL::DefaultLogger;
    my $logger = &get_logger;

    $logger->info("Creating submission files for: " . $study->alias);
    $logger->info("Results will be written to " . $output_dir);

    foreach my $current_format (@$format) {
    
        my $current_output_dir = File::Spec->join(
            $output_dir,
            $current_format
        ); 

        my $current_template_dir = File::Spec->join(
            $template_dir,
            $current_format
        );
      
        my $current_generated_file = run_template_engine({
            study        => $study,
            template_dir => $current_template_dir,
            output_dir   => $current_output_dir,
            format       => $current_format,
        });        

        $reporter->add($current_format, $current_generated_file);
    }
}

sub run_template_engine {

    my $param = shift;

    my $study        = $param->{study};
    my $template_dir = $param->{template_dir};
    my $output_dir   = $param->{output_dir};
    my $format       = $param->{format};

    use BRAEMBL::ENA::Rest::TemplateEngineRunnerFactory;
    my $template_engine_runner = BRAEMBL::ENA::Rest::TemplateEngineRunnerFactory
      ->new
      ->create_template_engine_runner($format);
    
    $template_engine_runner->template_dir($template_dir);
    $template_engine_runner->output_dir($output_dir);
    
    my $generated_file = $template_engine_runner->apply_templates($study);
    
    return $generated_file;
}

1;
