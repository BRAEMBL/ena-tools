package BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::ST131::SampleBuilder;

use Moose; # automatically turns on strict and warnings

# has 'sample_specific_info' => (
#   is      => 'rw', 
#   isa     => 'HashRef',
#   default => sub { return {} },
# );

has 'strain_name' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

has 'experiment' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Experiment',
);


sub build_alias {

  my $self = shift;
  my $parsed_file_name = shift;
  
  confess 'Missing parameter!' unless($parsed_file_name);
  my $strain_name      = $parsed_file_name->{strain_name};

  return "Escherichia coli ST131 $strain_name";
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
        return "Escherichia coli ST131 $strain_name";
    };

    # The taxon id based on the information parsed from the file
    #
    my $taxon_id = sub {

        my $parsed_file_name = shift;
        confess 'Missing parameter!' unless($parsed_file_name);

        return 1359206;
    };

    my $study = $self->study;

    $sample->alias          ( $study->submitter_name . '-' . $study->alias . '-' . $self->strain_name );
    $sample->scientific_name( $scientific_name->($self->strain_name) );
    $sample->common_name    ( $scientific_name->($self->strain_name) );
    $sample->description    ( $scientific_name->($self->strain_name) );
    $sample->title          ( $scientific_name->($self->strain_name) );
    $sample->taxon_id       ( $taxon_id       ->($self->strain_name) );
    
    $sample->attributes( 
      {
        'ENA-CHECKLIST' => 'ERC000011',
      }
    );
    $sample->experiment( $self->experiment );          

#   # List of Moose::Meta::Attribute
#   #
#   my @attribute = $study->meta->get_all_attributes;
#   
#   foreach my $current_attribute (@attribute) {
#   
#     my $attribute_name = $current_attribute->name;
#     my $build_method   = "build_${attribute_name}";
#     
#     $study->$attribute_name( $self->$build_method );
#   }  
    return $sample;
  
}

1;
