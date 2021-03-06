#!/usr/bin/env perl
=head1 serialise_study.pl

=head2 SYNOPSIS

Script to generate xml files necessary to submit metadata to ENA's REST service.

=head2 How to run this script

=over

    export PERL5LIB=$PWD/lib:$PWD/project_lib

    color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1

    authenticated_url=<Set this to your authenticated url at ENA see L<What is an Authenticated URL?>>

    time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.bacterial_submission.cfg -authenticated_url $authenticated_url

=back

=head2 What is an Authenticated URL?

This is the url you will use to address the REST service. The REST service has to know who you are, so you need a special url that proves to the REST service that you have authenticated with the credentials of your ENA account. This is how you get an authenticated url:

Quote:

=over

    All SRA REST submission functionality can be accessed programmatically using curl.

    First, you need to create an authenticated URL. Please follow the steps given below.

    Go to: https://www.ebi.ac.uk/ena/submit/drop-box/submit/  (Please don't remove the last slash '/' in the URL)
    Authenticate using your drop box name and password. 
    After successful login you should see the message:  'Submission xml not specified'. 
    Copy the URL. This is your authenticated URL, for example:

    https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/?auth=ERA%20era-drop...

    This URL can be used in curl to access and authenticate against the SRA REST service.
    
    Update: New accounts don't come with a drop box account anymore. See here 
    how to generate an authenticated url for them:
    
    https://www.ebi.ac.uk/ena/submit/programmatic-submission

=back

Source: L<https://www.ebi.ac.uk/ena/about/training/sra_rest_tutorial#part4>

=cut

use strict;
use Carp;
use Data::Dumper;
use File::Spec;
use File::Basename;
use Digest::MD5;
use Hash::Util qw(lock_keys);
use Getopt::Long;

=head2 Command line parameters

=cut

=head3 -config_file

The configuration file with the metadata that you want to submit. There are metadata demo files in the "metadata" subdirectory. Choose the one that matches your project best, make a copy and replace the values with your own metadata.

If the config_file parameter is omitted, the script will try to read from STDIN.

This can be used to generate configuration files automatically. In studies, in which the samples have been generated by varying experimental conditions, but most of the metadata is the same, it can be convenient to create a configuration file template and use a script that generates the final configuration file for all the samples from it automatically. This can be piped to the script directly.

=cut

my $config_file;


=head3 -authenticated_url

Authenticated url which allows submission of metadata to the BRAEMBL account. This script will not submit anything to ENA. The url is used only to build the commands at the end of the script which you can run by copy and paste.

See L<What is an Authenticated URL?>>

=cut

my $authenticated_url = '';

=head3 -no_md5

Skip computation of md5 sums. Submission of files to ENA won't work without md5 sums. This can be useful when testing your setup. If you don't set this, md5 sums will be generated and the script will be slow.

=cut

my $no_md5;


=head3 -help

Prints this documentation.

=cut

my $help;

=head3 -format

Select for which formats files should be generated. Options are:

=over

=item sra_xml: These are the xml files that are used for submission of the metadata to the ENA's REST service.

=item html: This is an html file that summarises your metadata. You can use this to check, if the metadata you are about to sbumit, looks right. The file will have placeholders where the accessions from ENA are supposed to be. After submission you can use the script "insert_values_from_ENA.pl" to replace these with the real accessions that were assigned to the objects of your submission.

=item tabsep: This is an tab separated file with the same information as the html one. It has the same placeholders as well. It is designed to be easily parseable so it can be used by scripts later on.

=back 

You can specify more than one format like this: C<-format sra_xml html>

If format is not specified, all formats will be generated.

=cut

my $report_style = 'human';

=head3 -report_style

Set this to 'machine', if you are running this script embedded within some automated pipline. Default: 'human'

It will affect how the results are reported to you. If you set 'human' you get complete, human readable sentences, otherwise you get a report that is optimised for parsing.

When set to 'machine', all logging messages are sent to stderr.

=cut

my $output_dir;

=head3 -output_dir

Directory into which the generated file should be written. By default they will go into the "auto_submission" folder of this checkout's directory. If the directory doesn't exist, it will be created for you.

=cut

=head2 Advanced command line parameters

The following parameters can be used for debugging. The script can print the data about the study in the different stages of processing it. The data is transformed a couple of times internally during the run of the script.

=over

=item Parsing of the configuration file: This is done by Config::General. See the result by using the -dump_configuration parameter.

=item Creation of a metadata object from the data parsed from the configuration file, this can be inspected with the -dump_metadata parameter.

=item Creation of a study object. This object structure represents the study as perl objects. This is what will be used to drive the template engine that creates the final output files selected in the -format option.

=back

=cut

my $dump_configuration;
=head3 -dump_configuration

If set, the parsed configuration file will be serialised as perl code and printed to screen using Data::Dumper. Then the script will terminate. No files will be created.

=cut

my $dump_metadata;
=head3 -dump_metadata

If set, the metadata object generated from you configuration file will be serialised as perl code and printed to screen using Data::Dumper. Then the script will terminate. No files will be created.

=cut

my $dump_study;
=head3 -dump_study

If set, the study object generated from you configuration file will be serialised as perl code and printed to screen using Data::Dumper. Then the script will terminate. No files will be created.

=cut

=head2 Documentation

You can get prettier versions of this documentation by running one of these commands:

=over

    podviewer scripts/serialise_study.pl
    podbrowser scripts/serialise_study.pl
    pod2html scripts/serialise_study.pl > serialise_study_documentation.html ; firefox serialise_study_documentation.html

=back

=head2 Copyright (c) 2014 BRAEMBL

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


=cut

my @allowed_format = qw( tabsep sra_xml html );
my @format;

# Mapping of command line paramters to variables
my %config_hash = (
    "no_md5"             => \$no_md5,
    "authenticated_url"  => \$authenticated_url,
    "config_file"        => \$config_file,
    "help"               => \$help,
    "format"             => \@format,
    "output_dir"         => \$output_dir,
    "report_style"       => \$report_style,
    "dump_study"         => \$dump_study,
    "dump_metadata"      => \$dump_metadata,
    "dump_configuration" => \$dump_configuration, 
    
);

# Loading command line paramters into variables and into a hash.
my $result = GetOptions(
  \%config_hash, 
  'authenticated_url=s',
  'config_file=s',
  'format:s{,}',
  'output_dir:s',
  'no_md5',
  'help',
  'report_style=s',
  'dump_study',
  'dump_metadata',
  'dump_configuration',  
);

# Create a hash with command line options, %config_hash above has pointers to
# variables, so using those makes code look messy later.
#
my %command_line_parameter;
foreach my $current_key (keys %config_hash) {
  if (ref $config_hash{$current_key} eq 'SCALAR') {
    $command_line_parameter{$current_key} = ${$config_hash{$current_key}};
  }
  if (ref $config_hash{$current_key} eq 'ARRAY') {
    $command_line_parameter{$current_key} = @{$config_hash{$current_key}};
  }  
  if (ref $config_hash{$current_key} eq 'HASH') {
    $command_line_parameter{$current_key} = %{$config_hash{$current_key}};
  }  
}
#print Dumper(\%command_line_parameter); exit;

#
# ---------- Start parameter checking and munging
#

use BRAEMBL::DefaultLogger;
my $logger = &get_logger;

if ($report_style eq 'machine' ) {

    my $logger_config = <<EOF
log4perl.logger=DEBUG, ScreenErr

log4perl.appender.ScreenErr=Log::Log4perl::Appender::Screen
log4perl.appender.ScreenErr.stderr=1
log4perl.appender.ScreenErr.Threshold=DEBUG
log4perl.appender.ScreenErr.Filter=ErrorFilter
log4perl.appender.ScreenErr.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.ScreenErr.layout.ConversionPattern=%d %p> %M{2}::%L - %m%n

log4perl.filter.ErrorFilter = Log::Log4perl::Filter::LevelRange
log4perl.filter.ErrorFilter.LevelMin = TRACE
log4perl.filter.ErrorFilter.LevelMax = FATAL
log4perl.filter.ErrorFilter.AcceptOnMatch = true

EOF
;

    Log::Log4perl->init( \$logger_config );

}

my $parameters_are_fatal = 0;

# Check, if a format was specified that is not recognised by the script.
#
my @illegal_format 
  = grep { $_ }
  map {
    my $requested_format = $_; 
    my $requested_format_is_known = grep { $requested_format eq $_ } @allowed_format;
    
    if (!$requested_format_is_known) {
      $requested_format
    }
  } @format;

if (@illegal_format) {
    $logger->error("Unknown format: " . (join ', ', @illegal_format) );
    $logger->error("Format must be one of the following: " . (join ', ', @allowed_format) );
    $parameters_are_fatal = 1;
}

# If no format was specified, generate all formats.
#
if ((grep { $_ } @format) == 0) {
    @format = @allowed_format;
}

if ($help) {
    system('perldoc', $0);
    exit;
}

if (!$authenticated_url) {
    $logger->warn("Parameter authenticated_url has not been set, the commands printed at the end of the script for submission to ENA's REST API will not work without this.");
}

my $compute_md5 = !$no_md5;

if ($compute_md5) {
    $logger->info("Md5 sums will be computed.");
} else {
    $logger->warn("Md5 sums will not be computed. This is good for testing generation of the xml files, but you won't be able to submit the runs without correct md5 sums.");
}

if ($parameters_are_fatal) {
  $logger->fatal("Please check the error messages above.");
  $logger->fatal("For documentation, run this script with the --help parameter.");
  exit;
}

#
# ---------- End of parameter checking
#

if ($dump_configuration || $dump_metadata || $dump_study) {
  $Data::Dumper::Sortkeys = 1;
}

my $template_dir = File::Spec->catfile( dirname(__FILE__), '..', 'templates', 'serialisation' );

if (! defined $output_dir) {

    my $sub_dir;
    
    if (!$config_file) {
      $sub_dir = 'stdin';
    } else {
      $sub_dir = basename($config_file);
      $sub_dir =~ s/.cfg$//;    
    }
    $output_dir = File::Spec->catfile( dirname(__FILE__), '..', 'auto_submission', $sub_dir );
}

my $metadata_factory = BRAEMBL::ENA::Submission::MetadataFactory
  ->new( configuration_file => $config_file );

if ($dump_configuration) {
  print Dumper($metadata_factory->configuration_file_parsed);
  exit;
}

use BRAEMBL::ENA::Submission::MetadataFactory;
my $metadata = $metadata_factory->metadata;

if ($dump_metadata) {
  print Dumper($metadata);
  exit;
}

use BRAEMBL::ENA::Submission::Reporter;
my $reporter = BRAEMBL::ENA::Submission::Reporter->new( 
  report_format => $report_style,
  metadata      => $metadata,
  %config_hash
);

use BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::AbstractFactory;
my $abstractFactory = BRAEMBL::ENA::Submission::Rest::DomainObjectBuilder::AbstractFactory->new(
    metadata => $metadata,
    command_line_parameter => \%command_line_parameter,
);

my $director = $abstractFactory->create_director;
my $study = $director->construct;

if ($dump_study) {
  print Dumper($study);
  exit;
}

use BRAEMBL::ENA::Submission::Serialiser;
my $serialiser = BRAEMBL::ENA::Submission::Serialiser->new(
    compute_md5  => $compute_md5,
    template_dir => $template_dir,
    output_dir   => $output_dir,
);

$serialiser->serialise_study({
    metadata     => $metadata,
    format       => \@format,
    reporter     => $reporter,
    study        => $study,
});

print $reporter->report;

exit;


