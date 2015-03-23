package BRAEMBL::ENA::Submission::Rest::DefaultStudyType1::DomainObjectBuilder::SampleBuilder;

use Moose;
use BRAEMBL::DefaultLogger;
with 'BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::AttributeUnits';

has 'metadata' => (
  is      => 'rw', 
);

has 'study' => (
  is      => 'rw', 
  isa     => 'BRAEMBL::ENA::Rest::Study',
);

sub create_alias {

  my $self      = shift;
  my $sample_id = shift;
  
  my $sample_identifier;
  
  # Try to find a name to describe the sample.
  
  # Allow sample alias to be set explicitly. This can be necessary, if there 
  # are two samples with the same name in the same study.
  #
  if ($self->metadata->sample->{$sample_id}->{sample_alias}) {
    return $self->metadata->sample->{$sample_id}->{sample_alias};
  }
  else {
    if ($self->metadata->scientific_name) {
    
      $sample_identifier = $self->metadata->scientific_name;
      
    } else {

      if ($self->metadata->sample->{$sample_id}->{sample_name}) {
	$sample_identifier = $self->metadata->sample->{$sample_id}->{sample_name};
      } else {
	$sample_identifier = 'sample ' . $sample_id;
      }
    }
  }
  
  return join ', ', 
    $self->metadata->center_name,
    $self->study->alias,
    $sample_identifier,
}

sub construct_sample_by_id {

    my $self      = shift;
    my $sample_id = shift;

    $sample_id = 1 unless(defined $sample_id);
    
    use BRAEMBL::ENA::Rest::Sample;
    my $sample = BRAEMBL::ENA::Rest::Sample->new();

    my $study = $self->study;

    $sample->alias          ( $self->create_alias($sample_id) );
    $sample->common_name    ( $self->metadata->sample->{$sample_id}->{common_name} );
    $sample->description    ( $self->metadata->sample->{$sample_id}->{description} );
    $sample->title          ( 
      $self->metadata->sample->{$sample_id}->{title} ?
      $self->metadata->sample->{$sample_id}->{title} :
      $self->metadata->sample->{$sample_id}->{scientific_name}
    );
    $sample->taxon_id       ( $self->metadata->sample->{$sample_id}->{taxon_id} );
    $sample->scientific_name( $self->metadata->sample->{$sample_id}->{scientific_name} );
    
    $sample->experiment_id    ( $self->metadata->sample->{$sample_id}->{experiment_id} );
    $sample->internal_name    ( $self->metadata->sample->{$sample_id}->{sample_name} );
    
    
    if (
      exists $self->metadata->sample_attributes->{$sample_id}
    ) {
      my $sample_attributes = $self->metadata->sample_attributes->{$sample_id};
      confess('Type error!') unless(ref $sample_attributes eq 'HASH');
      $self->remove_empty_attributes($sample_attributes);
      $sample->attributes($sample_attributes);
    }

    if (
      exists $self->metadata->sample_attributes->{$sample_id}
      && $self->checklist_has_been_used($sample_id)
    ) {
      my $sample_attributes = $self->metadata->sample_attributes->{$sample_id};
      # Attribute units created as a side effect, must find a better solution 
      # for this in the future.
      #
      my $attribute_units = $self->remove_units($sample_id);
      $sample->attributes($sample_attributes);
      $sample->attribute_units($attribute_units);      
    }
    return $sample;  
}

sub construct {

    my $self = shift;
    
    my @sample_id = keys %{$self->metadata->sample};
    my %sample_hash;
    
    foreach my $current_sample_id (@sample_id) {      
      $sample_hash{$current_sample_id} = $self->construct_sample_by_id($current_sample_id);    
    }    
    return \%sample_hash;
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

sub checklist_has_been_used {

  my $self      = shift;
  my $sample_id = shift;
  
  confess('Missing sample_id parameter!') unless($sample_id);
  
  my $sample_attributes = $self->metadata->sample_attributes->{$sample_id};
  my $checklist_has_been_used = exists $sample_attributes->{'ENA-CHECKLIST'};
  
  return $checklist_has_been_used;  
}

sub remove_units {

  my $self              = shift;
  my $sample_id         = shift;
  
  confess('Missing sample_id parameter!') unless($sample_id);
  
  my $sample_attributes = $self->metadata->sample_attributes->{$sample_id};  
  confess('Type error!') unless(ref $sample_attributes eq 'HASH');
  
  my $logger = get_logger;
  
  unless ($self->checklist_has_been_used($sample_id)) {
    $logger->info("No checklist has been used, so units will not be processed by this script.");
    return;
  }
  
  my $checklist_accession = $sample_attributes->{'ENA-CHECKLIST'};
  $logger->info("Using checklist $checklist_accession");
  
  my $checklist_directory = 'checklists';  
  my $checklist_xml_file = $checklist_directory . '/' . $checklist_accession . '.xml';
  
  if (! -e $checklist_xml_file) {
    $logger->fatal("$checklist_xml_file doesn't exist!");
    die;
  }
  $logger->fatal("Using checklist $checklist_xml_file for processing attributes of sample $sample_id");
  
  my $attribute_units = $self->attribute_units($checklist_xml_file);
  
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
      $attribute_units->{$current_attribute} = $unit_in_this_attribute;
  }
  return $attribute_units;
}

1;
