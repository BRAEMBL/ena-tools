#!/usr/bin/env perl
=head1 prepare_submission_fasta.pl

=head2 SYNOPSIS

=head2 How to run this script

=over

    export PERL5LIB=$PWD/lib:$PWD/project_lib

    color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
    
    # Redirect 2>/dev/null to suppress warnings that are irrelevant for this.
    #
    ./scripts/arachnoserver/prepare_submission_fasta.pl \
      --features "/home/michael/spider_toxin_devel/qfab_package/245/245coordinatesAllForward.tsv" \
      --assembly "/home/michael/spider_toxin_devel/qfab_package/245/245_reverse_complement_Assembly.fa" \
      --organism "Hadronyche infensa" \
      --assembly_name HI \
      --assembly_method MIRA \
      --sequencing_technology "454 GS" \
      --sra_study_accession ERP005525 \
      --sra_sample_accession ERS431088 \
    
=back

=head2 Parameters

=head3 -features
=cut

=head3 -assembly
=cut

use strict;
use Carp;
use Data::Dumper;
use Getopt::Long;
use List::MoreUtils qw{ zip };
use Hash::Util qw(lock_keys);

my $feature_file;
my $fasta_file;
my $organism;
my $assembly_name;
my $assembly_method;
my $sequencing_technology;
my $sra_study_accession;
my $sra_sample_accession;
my $help;

# Mapping of command line parameters to variables
my %config_hash = (
    "features"              => \$feature_file,
    "organism"              => \$organism,
    "assembly_name"         => \$assembly_name,
    "assembly_method"       => \$assembly_method,
    "sequencing_technology" => \$sequencing_technology,
    "sra_study_accession"   => \$sra_study_accession,
    "sra_sample_accession"  => \$sra_sample_accession,
    "help"                  => \$help,
);

# Loading command line parameters into variables and into a hash.
my $result = GetOptions(
  \%config_hash, 
  'features=s',
  'organism=s',
  'assembly_name=s',
  'assembly_method=s',
  'sequencing_technology=s',
  'sra_study_accession=s',
  'sra_sample_accession=s',
  'help',
);

if ($help) {
    system('perldoc', $0);
    exit;
}

die "Missing mandatory parameter --feature!"  unless($feature_file);
die "Can't find file $feature_file!" unless(-f $feature_file);

use Bio::Seq;
use Bio::SeqIO;

my $seq_out = Bio::SeqIO->new(
  -fh     => \*STDOUT,
  -format => 'Fasta'
);

open my $IN, $feature_file;
my @genelist = parse_tsv($IN);

foreach my $current_gene (@genelist) {
  my $header = join '',
	"[Organism=$organism]",
	"[Name for the assembly=$assembly_name]",
	"[Assembly method=$assembly_method]",
	"[Sequencing technology=$sequencing_technology]",
	"[SRA Study Accession=$sra_study_accession]",
	"[SRA Sample Accession=$sra_sample_accession]",
	'[Contig/Isotig name=' . $current_gene->{seq_name} . ']',
	'[product=' . $current_gene->{product} . ']',
	'[5\' CDS location='. $current_gene->{start} .']',
	'[3\' CDS location='. $current_gene->{end} .']',
	"[partial at 5' ? (yes/no)=no]",
	"[partial at 3' ? (yes/no)=no]",
	"[Translation table=1]";
  
  my $seq_obj = Bio::Seq->new(
    -id  => $header,
    -seq => $current_gene->{nt_seq},
  );
  $seq_out->write_seq($seq_obj);
}

exit;

sub parse_tsv {

  my $fh = shift;

  my @header = qw(
    seq_name
    product
    aa_seq_1
    aa_seq_2
    aa_seq_3
    nt_seq
    start
    end
  );

  my @genelist;
  open my $fh, $feature_file;
  while (my $current_line = <$IN>) {
    chomp($current_line);
    my @f = split "\t", $current_line;
    my %hash = zip @header, @f;
    lock_keys(%hash);
    push @genelist, \%hash;
  }
  return @genelist;
}
