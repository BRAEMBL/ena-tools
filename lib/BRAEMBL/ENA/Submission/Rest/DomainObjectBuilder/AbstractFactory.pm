package BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::AbstractFactory;

use Moose;

with 'BRAEMBL::ModuleLoader';

has 'metadata' => (
  is       => 'rw', 
  required => 1,
);

has 'command_line_parameter' => (
  is       => 'rw', 
  required => 1,
  isa      => 'HashRef',
);

sub create_director {

  my $self = shift;
  
  my $compute_md5 = ! $self->command_line_parameter->{no_md5};

  my $ena_object_builders = $self->create_builders;
  my $file_list_builder   = $self->create_file_list_builder;
  my $file_name_parser    = $self->create_file_name_parser;

  my $metadata = $self->metadata;
  my $study_type = $metadata->study_type;

  my $module = "BRAEMBL::ENA::Submission::Rest::${study_type}::DomainObjectBuilder::Director";

  my $director = load_and_instantiate(
      $module,
      ena_object_builders => $ena_object_builders,
      compute_md5         => $compute_md5,
      file_list_builder   => $file_list_builder,
      file_name_parser    => $file_name_parser,
      metadata            => $metadata,
  );
  
  return $director;
}

=head2 create_builders

  Create the correct builder for a given study name
  
=cut
sub create_builders {

  my $self       = shift;

  my $study_builder;
  my $sample_builder;
  my $experiment_builder;
  my $run_builder;
  
  my $metadata = $self->metadata;
  my $study_type = $metadata->study_type;
  
  $study_builder      = load_and_instantiate("BRAEMBL::ENA::Submission::Rest::${study_type}::DomainObjectBuilder::StudyBuilder");
  $sample_builder     = load_and_instantiate("BRAEMBL::ENA::Submission::Rest::${study_type}::DomainObjectBuilder::SampleBuilder");
  $experiment_builder = load_and_instantiate("BRAEMBL::ENA::Submission::Rest::${study_type}::DomainObjectBuilder::ExperimentBuilder");
  $run_builder        = load_and_instantiate("BRAEMBL::ENA::Submission::Rest::${study_type}::DomainObjectBuilder::RunBuilder");

  $study_builder     -> metadata($metadata);
  $sample_builder    -> metadata($metadata);
  $experiment_builder-> metadata($metadata);
  $run_builder       -> metadata($metadata);
  
  # Originally the director is the one who computes the md5 sums. In 
  # afterthought, it should be really be done by the run_builder. So in newer
  # classes it will be set here.
  #
  if ($run_builder->meta->has_attribute('compute_md5')) {
    $run_builder -> compute_md5(! $self->command_line_parameter->{no_md5});
  }  

  my $builders = {
    study_builder      => $study_builder, 
    sample_builder     => $sample_builder,
    experiment_builder => $experiment_builder,
    run_builder        => $run_builder,
  };
  
  use Hash::Util qw( lock_keys );
  lock_keys(%$builders);

  return $builders;
}

sub create_file_list_builder {

  my $self       = shift;
  my $metadata   = $self->metadata;
  my $study_type = $metadata->study_type;

  my $module = "BRAEMBL::ENA::Submission::Rest::${study_type}::FileListBuilder";
  
  my $file_list_builder = load_and_instantiate($module);
  $file_list_builder->metadata($metadata);         
      
  return $file_list_builder;
}

sub create_file_name_parser {

  my $self       = shift;
  my $metadata   = $self->metadata;
  my $study_type = $metadata->study_type;
  
  my $module  = "BRAEMBL::ENA::Submission::Rest::${study_type}::FileNameParser";
    
  my $file_list_builder = load_and_instantiate($module);
  $file_list_builder->metadata($metadata);      

  return $file_list_builder;
}

1
;