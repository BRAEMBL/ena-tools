#!/usr/bin/env perl
=head1 insert_values_from_ENA.pl

=head2 SYNOPSIS

  After submission via ENA's REST service, the server will return a receipt.
  
  This script can be used to insert the values in that receipt into the 
  summaries generated with the serialise_study.pl script.

=head2 Setup

Set PERL5LIB, if you haven't already done so:

=over

  export PERL5LIB=$PWD/lib

=back

The study_title is a file friendly version of the study_alias parameter you used in your file where spaces and commas have been replaced by underscores. It is the name of the subdirectory created for your study in the auto_submission directory.

=over

  study_title=demo_AGRF_Illumina_PE24x_D13N8ACXX

=back

=head2 Run

Use the script in a pipe to insert the values returned by ENA's REST service 
into the summaries in html and tab separated format:

=over

  xmlstarlet tr xslt/receipt_to_mapping.xslt last_receipt.${study_title}.xml | perl scripts/insert_values_from_ENA.pl auto_submission/${study_title}/html/all_metadata.html > auto_submission/${study_title}/html/metadata.${study_title}.html

  xmlstarlet tr xslt/receipt_to_mapping.xslt last_receipt.${study_title}.xml | perl scripts/insert_values_from_ENA.pl auto_submission/${study_title}/tabsep/all_metadata.txt > auto_submission/${study_title}/tabsep/metadata.${study_title}.txt

=back

Then check the results:

=over
  
  firefox auto_submission/${study_title}/html/metadata.${study_title}.html
  kate auto_submission/${study_title}/tabsep/metadata.${study_title}.txt

=back

=cut

use strict;
use Carp;
use Data::Dumper;
use File::Spec;
use File::Basename;
use Digest::MD5;
use Hash::Util qw(lock_keys);
use BRAEMBL::DefaultLogger;

my $logger = &get_logger;

my $template_file = shift;

my $should_print_help = $template_file eq '' || $template_file =~ m/help/;

if ($should_print_help) {
    system('perldoc', $0);
    exit;
}

my %substitutions;
LINE: while (my $current_line = <STDIN>) {
  
  chomp $current_line;

  # Skip empty lines
  next LINE if ($current_line =~ /^\w*$/);
  # Skip lines beginning with "-"
  next LINE if ($current_line =~ /^\-/);
  
  my @fields = split "\t", $current_line;
  
  confess("Unexpected number of fields in $current_line!") unless(@fields==2);
  
  my $placeholder = $fields[0];
  my $value       = $fields[1];
  
  $substitutions{$placeholder} = $value;
}


use File::Slurp;
my $text = read_file( $template_file ) ;

foreach my $current_placeholder (keys %substitutions) {

  $logger->debug("Substituting $current_placeholder");
  my $num_occurrences = $text =~ s/$current_placeholder/$substitutions{$current_placeholder}/g;
  $logger->debug("replaced $num_occurrences times.");

}


print $text;