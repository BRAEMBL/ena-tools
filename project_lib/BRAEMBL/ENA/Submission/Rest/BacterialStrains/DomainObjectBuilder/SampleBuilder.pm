package BRAEMBL::ENA::Submission::Rest::BacterialStrains::DomainObjectBuilder::SampleBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'strain_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'scientific_name_base' => (
  is      => 'rw', 
  isa     => 'Str',
  lazy    => 1,
  default => sub {       
      my $self = shift;
      return $self->metadata->scientific_name_base;
  },
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

has 'experiment' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Experiment',
);

has 'taxon_id' => (
  is      => 'rw', 
  isa     => 'Str',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return $self->metadata->taxon_id;
  },
);

sub build_alias {

  my $self = shift;
  my $parsed_file_name = shift;
  
  confess 'Missing parameter!' unless($parsed_file_name);
  my $strain_name      = $parsed_file_name->{strain_name};

  return $self->scientific_name_base . ' ' . $strain_name;
}

sub construct {

    my $self = shift;
    
    use BRAEMBL::ENA::Rest::Sample;
    my $sample = BRAEMBL::ENA::Rest::Sample->new();
    
    # The name of the sample based on the information parsed from the file
    #
    my $scientific_name = sub {

        my $strain_name = shift;
        confess 'Missing parameter!' unless($strain_name);
        return $self->scientific_name_base . ' ' .  $strain_name;
    };

    my $study = $self->study;

    $sample->alias          ( $self->metadata->center_name . '-' . $study->alias . '-' . $self->strain_name );
    $sample->common_name    ( $scientific_name->($self->strain_name) );
    $sample->description    ( $scientific_name->($self->strain_name) );
    $sample->title          ( $scientific_name->($self->strain_name) );
    $sample->taxon_id       ( $self->taxon_id );
    $sample->scientific_name( $self->scientific_name_base );
    
    $sample->attributes( 
      {
        'ENA-CHECKLIST' => 'ERC000011',
        
        # Recommended by ENA: Instead of appending the strain name to the 
        # scientific name, it should go in as an extra attribute. "strain"
        # is recognised by ENA.
        #
        'strain' => $self->strain_name,
      }
    );
    $sample->experiment( [ $self->experiment ] );

    return $sample;  
}

1;
