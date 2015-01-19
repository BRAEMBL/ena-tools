package BRAEMBL::ENA::Submission::MetadataFactory;

use Moose;

with 'BRAEMBL::ModuleLoader';

has 'configuration_file' => (
  is       => 'ro', 
  #isa      => 'Str|Maybe',
  required => 1,
);

has 'configuration_file_parsed' => (
  is       => 'rw', 
  isa      => 'HashRef',
  lazy     => 1,
  builder  => 'build_configuration_file_parsed',
);

sub build_configuration_file_parsed {

    my $self = shift;
    
    my $configuration_file = $self->configuration_file;

    # If no configuration file was specified, read from STDIN.
    if (! $configuration_file) {
      
	use BRAEMBL::DefaultLogger;
	my $logger = &get_logger;
    
	$logger->warn("No configuration file was specified, reading from STDIN.");
	$configuration_file = \*STDIN;
    }
    
    use Config::General;
    my $config_general = Config::General->new(
      -ConfigFile           => $configuration_file,
      -IncludeRelative      => 1,
      -UseApacheInclude     => 1,
      
      # Allow inclusion of several attribute blocks so they are merged into one.
      -MergeDuplicateBlocks => 1,
    );
    my %configuration_file_parsed = $config_general->getall;    
    
    return \%configuration_file_parsed;    
}

has 'metadata' => (
  is      => 'rw', 
  lazy    => 1,
  builder => 'build_metadata',
);

sub build_metadata {
    my $self = shift;
    
    my $configuration_file_parsed = $self->configuration_file_parsed;    
    my $study_type = $configuration_file_parsed->{study_type};
    
    my $module = "BRAEMBL::ENA::Submission::Rest::${study_type}::Metadata";
    my $metadata = load_and_instantiate($module, %$configuration_file_parsed);
    
    return $metadata;
  }

1;
