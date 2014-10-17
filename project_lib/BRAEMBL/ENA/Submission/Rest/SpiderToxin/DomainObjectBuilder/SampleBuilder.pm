package BRAEMBL::ENA::Submission::Rest::SpiderToxin::DomainObjectBuilder::SampleBuilder;

use Moose;

has 'metadata' => (
  is      => 'rw', 
);

has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
  lazy    => 1,
  default => sub {       
      my $self = shift;
      return $self->metadata->scientific_name;
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
  return $self->scientific_name ;
}

sub construct {

    my $self = shift;
    
    use BRAEMBL::ENA::Rest::Sample;
    my $sample = BRAEMBL::ENA::Rest::Sample->new();

    my $study = $self->study;

    $sample->alias          ( $self->metadata->center_name . '-' . $study->alias );
    $sample->common_name    ( $self->scientific_name );
    $sample->description    ( $self->scientific_name );
    $sample->title          ( $self->scientific_name );
    $sample->taxon_id       ( $self->taxon_id );
    $sample->scientific_name( $self->scientific_name );
    
    my $attributes_hash = $self->metadata->sample_attributes->{1};
    
#     use Data::Dumper;
#     print Dumper($attributes_hash->{1});
#     exit;
#     
    $sample->attributes($attributes_hash);
    $sample->experiment([ $self->experiment ]);

    return $sample;  
}

1;
