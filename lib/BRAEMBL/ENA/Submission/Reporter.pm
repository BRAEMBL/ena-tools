package BRAEMBL::ENA::Submission::Reporter;

use Moose;

has 'report_format' => (
  is       => 'rw', 
  isa      => 'Str',
  required => 1,
);

has 'compute_md5' => (
  is       => 'rw', 
  isa      => 'Bool',
  default  => 0,
);

has 'report_buffer' => (
  is       => 'rw', 
  isa      => 'Str',
  default  => '',
);

has 'metadata' => (
  is       => 'rw', 
  required => 1,
);

has 'authenticated_url' => (
  is       => 'rw', 
  default  => '<No authenticated url was given>',
  trigger  => \&deref_scalar,
);

has 'report_writer' => (
  is       => 'rw', 
  lazy     => 1,
  builder  => 'report_writer_builder',
);

sub report_writer_builder {

  my $self = shift;

  use BRAEMBL::ENA::Submission::ReportWriter::human;
  use BRAEMBL::ENA::Submission::ReportWriter::machine;      

  my $report_format = $self->report_format;

  return "BRAEMBL::ENA::Submission::ReportWriter::$report_format"->new( 
    reporter => $self 
  );
}


sub deref_scalar {
    my $self  = shift;
    my $value = shift;
    
    if (ref $value eq 'SCALAR') {    
      $self->authenticated_url(${$self->authenticated_url});
    }
  }

sub add {

    my $self           = shift;
    my $output_format  = shift;
    my $generated_file = shift;
    
    my $report_format = $self->report_format;
    
    my $method = "print_report_$output_format";
    my $report = $self->report_writer->$method($generated_file);
    
    $self->report_buffer( $self->report_buffer .  $report );

}

sub report {

    my $self = shift;
    return $self->report_buffer;
}

1;
