package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::AttributeUnits;

use Moose::Role;
use BRAEMBL::DefaultLogger;

with 'System::ShellRunner';

sub attribute_units {

  my $self               = shift;
  my $checklist_xml_file = shift;

  $self->checklist_file($checklist_xml_file);
  
  my $value_to_units = $self->from_file;

  return $value_to_units;
}

# has 'attribute_units' => (
#   is      => 'rw',
#   isa     => 'HashRef', 
#   default => sub { return shift->from_file; },
#   lazy    => 1,
# );

has 'checklist_file' => (
  is      => 'rw',
  isa     => 'Str', 
  default => "checklists/ERC000025.xml"
);

sub from_file {

  my $self = shift;

  my $xslt_stylesheet = &xslt_stylesheet;
  my $checklist = $self->checklist_file;  
  
  # Should produce something like this:
  # xsltproc ./xslt/value_units_from_checklist.xslt ERC000013.xml
  #
  my $cmd = "xsltproc $xslt_stylesheet $checklist";
  my $output;
  
  eval {
    $output = run_cmd($cmd);
  };
  if ($@) {
    get_logger->info("There was an error executing: $cmd");
  };
  
  my %value_to_units = $self->parse_value_to_units($output);
  return \%value_to_units;
}

sub parse_value_to_units {

  my $self   = shift;
  my $output = shift;
  
  my @line = split "\n", $output;
  my %value_to_units;
  
  foreach my $current_line (@line) {
  
    my @field = split "\t", $current_line;
    (my $value, my @unit) = @field;    
    $value_to_units{$value} = \@unit;  
  }
  return %value_to_units;
}

sub xslt_stylesheet {

  use File::Basename;
  my $dir             = File::Spec->join(dirname(__FILE__), 'AttributeUnits');
  my $xslt_stylesheet = File::Spec->join($dir, 'value_units_from_checklist.xslt');

  use Carp;
  confess("Can't find xslt stylesheet!") unless(-e $xslt_stylesheet);
  return $xslt_stylesheet
}

1;
