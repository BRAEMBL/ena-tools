package BRAEMBL::ENA::Submission::Metadata::Roles::Common;

use Moose::Role;

with 'BRAEMBL::ENA::Submission::Metadata::Roles::Library';

=head1 center_name, broker_name, run_center

http://www.ebi.ac.uk/ena/about/sra_preparing_metadata

The center_name attribute defines the submitting institution. The center names are controlled acronyms provided to the account holders when the account is first generated for an institute. If the submitter is brokering a submission for another institute, the center name should reflect the institute where the data was generated. Brokers should request a special broker account and provide their center name acronym in the broker_name attribute. If the sequencing has been contracted to another partly, the run_center or analysis_center attributes can be used to provide this information.

=cut

has 'center_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'broker_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'run_center' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'existing_study_type' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'hold_until_date' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'study_alias' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'study_type' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'title' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'abstract' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'scientific_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'common_name' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'taxon_id' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'read_file_suffix' => (
  is      => 'rw', 
  isa     => 'Str',
);

has 'sample' => (
  is      => 'rw', 
  isa     => 'HashRef',  
  trigger => \&convert_configured_attributes_to_hashref,
);

has 'sample_attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',  
  trigger => \&convert_configured_attributes_to_hashref,
);

has 'experiment_attributes' => (
  is      => 'rw', 
  isa     => 'HashRef',  
  trigger => \&convert_configured_attributes_to_hashref,
);

sub convert_configured_attributes_to_hashref {

  my $self  = shift;
  my $value = shift;

  foreach my $current_id (keys %{$value}) {

    my $temp_array = $value->{$current_id};
    my %hash = @$temp_array;
    $value->{$current_id} = \%hash;
    
  }
  return $value;

}



1;
