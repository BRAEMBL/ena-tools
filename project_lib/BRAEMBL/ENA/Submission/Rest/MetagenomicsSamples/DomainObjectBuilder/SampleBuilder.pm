package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::DomainObjectBuilder::SampleBuilder;

use Moose;
use BRAEMBL::DefaultLogger;

with 'BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::AttributeUnits';

has 'metadata' => (
  is      => 'rw', 
);

has 'sample_id' => (
  is      => 'rw', 
  isa     => 'Str',
  lazy    => 1,
  default => sub {       
      my $self = shift;
      return $self->metadata->sample_id;
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
  isa     => 'Maybe[Str]',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return $self->metadata->taxon_id;
  },
);

sub build_alias {

  my $self = shift;
  return $self->sample_id ;
}

sub construct {

    my $self      = shift;
    my $sample_id = shift;
    
    use BRAEMBL::ENA::Rest::Sample;
    my $sample = BRAEMBL::ENA::Rest::Sample->new();

    my $study = $self->study;
    
    $sample->alias          ( $self->metadata->center_name . '-' . $study->alias . '-' . $sample_id);
    if ($self->taxon_id) {
	$sample->taxon_id       ( $self->taxon_id );
    }
    
    if (exists $self->metadata->sample_attributes->{$sample_id}) {
    
      my $sample_attributes = $self->metadata->sample_attributes->{$sample_id};
      
      $self->remove_units($sample_attributes);
      $self->remove_empty_attributes($sample_attributes);
    
      $sample->attributes($sample_attributes);
      $sample->attribute_units($self->attribute_units);
      
    }
    $sample->experiment( $self->experiment );          

    return $sample;  
}

sub remove_empty_attributes {

  my $self              = shift;
  my $sample_attributes = shift;    
  
  ATTRIBUTE: foreach my $current_attribute (keys %$sample_attributes) {
  
    my $value = $sample_attributes->{$current_attribute};
  
    if ($value=~/^\s*$/) {
	delete $sample_attributes->{$current_attribute};
    }
  }
}

sub remove_units {

  my $self              = shift;
  my $sample_attributes = shift;    
  
  my $attribute_units = $self->attribute_units;
  
  #use Data::Dumper; print Dumper($attribute_units); exit;  
  
  ATTRIBUTE: foreach my $current_attribute (keys %$sample_attributes) {
  
      next ATTRIBUTE unless (exists $attribute_units->{$current_attribute});
      
      my $value = $sample_attributes->{$current_attribute};

      # If no value has been given, then no unit is necessary.
      next ATTRIBUTE unless ($value);
      
      my $unit  = $attribute_units->{$current_attribute};

      if (ref $unit ne 'ARRAY') {
	$unit = [$unit];
      }
      
      my $unit_found;
      my $unit_in_this_attribute;
      
      UNIT: foreach my $current_unit (@$unit) {
	my $current_unit_found = $value =~ s/\s*$current_unit$//;
	if ($current_unit_found) { 
	  $unit_found = 1;
	  $unit_in_this_attribute = $current_unit;
	  last UNIT;
	};
      }      

      if (!$unit_found) {
	get_logger->error("No valid unit found for ${current_attribute}. The value was: $value! Expected unit is one of: " . join ",", @$unit);
	next ATTRIBUTE
      }
      
      $sample_attributes->{$current_attribute} = $value;
      $self->attribute_units->{$current_attribute} = $unit_in_this_attribute;
  }
}

1;
