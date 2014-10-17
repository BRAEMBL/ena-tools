package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::Metadata::SampleAttributes;

use Moose::Role;

has 'sample_attributes_trigger_on' => (
  is      => 'rw', 
  isa     => 'Bool',
);

has 'sample_attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',
  trigger => sub {
  
    my $self = shift;
    my $value = shift;
    
    return if ($self->sample_attributes_trigger_on);    
    $self->sample_attributes_trigger_on(1);
    
    $self->sample_attributes(
      _cast_hash_of_arrays_into_hash_of_hashes(
	$self->sample_attributes
      )
    );
    
    $self->sample_attributes_trigger_on(0);
  }
);

has 'sample_ids' => (
  is      => 'rw', 
  isa     => 'HashRef',
);

sub _cast_hash_of_arrays_into_hash_of_hashes {

  my $sample_attributes = shift;;

  foreach my $sample_name (keys %$sample_attributes) {
    my $array_ref = $sample_attributes->{$sample_name};
    my %hash = @$array_ref;
    $sample_attributes->{$sample_name} = \%hash;
  }
  
  return $sample_attributes;
}

1;
