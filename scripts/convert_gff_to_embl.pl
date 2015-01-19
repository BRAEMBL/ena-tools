#!/usr/bin/env perl
=head1 convert_gff_to_embl.pl

=head2 SYNOPSIS

  ENA expects annotation to be submitted in gzipped EMBL format, but it often comes in gff format.
  
  This script can be used to convert annotation from gff to embl format.  

=head2 Dependencies

  Needs bioperl:
  
  wget http://bioperl.org/DIST/BioPerl-1.6.1.tar.gz
  tar xzvf BioPerl-1.6.1.tar.gz  
  export PERL5LIB=$PERL5LIB:$(readlink -f BioPerl-1.6.1)

=head2 Usage:

  perl scripts/convert_gff_to_embl.pl --gff_file annotation.gff --fasta_file sequence_only.fasta | gzip > annotation.embl.gz

=cut

use strict;
use Carp;
use Data::Dumper;
use Hash::Util qw(lock_keys);
use Bio::SeqIO;
use Bio::Tools::GFF;
use Getopt::Long;

my $gff_file;
my $fasta_file;
my $help;

# Mapping of command line paramters to variables
my %config_hash = (
    "gff_file=s"   => \$gff_file,
    "fasta_file=s" => \$fasta_file,
    "help"         => \$help,
);

# Loading command line paramters into variables and into a hash.
my $result = GetOptions(%config_hash);

if ($help) {
    system('perldoc', $0);
    exit;
}

die "Missing mandatory parameter --gff_file!"   unless($gff_file);
die "Missing mandatory parameter --fasta_file!" unless($fasta_file);

die "Can't find file $gff_file!"   unless(-f $gff_file);
die "Can't find file $fasta_file!" unless(-f $fasta_file);


my $in  = Bio::SeqIO->new(
  -file   => $fasta_file,
  -format => 'Fasta'
);

my %seqname_to_seq_obj;

while ( my $seq = $in->next_seq() ) {
  $seqname_to_seq_obj{$seq->id} = $seq;
}
lock_keys(%seqname_to_seq_obj);

my $parser = Bio::Tools::GFF->new(
  -gff_version => 3,
  -file        => $gff_file
);

while (my $feature = $parser->next_feature()) {

  my $seqname = $feature->seq_id;
  my $seq_obj = $seqname_to_seq_obj{$seqname};
  
  $seq_obj->add_SeqFeature($feature);
}

my $output_stream = Bio::SeqIO->new(-fh => \*STDOUT, -format => 'EMBL');

foreach my $current_seq_name (keys %seqname_to_seq_obj) {

  $output_stream->write_seq($seqname_to_seq_obj{$current_seq_name});

}
