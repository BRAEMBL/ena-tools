#!/usr/bin/env perl
=head1 select_alignements_from_sam.pl

=head2 SYNOPSIS

Creates a sam file with a subset of the alignments from an existing sam

=head2 How to run this script

=over

    # Note: You also need bioperl in your path, so this isn't really complete.

    export PERL5LIB=$PWD/lib

    color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1

    time color perl ./scripts/sam/select_alignments_from_sam.pl \
--select /home/michael/spider_toxin_devel/ena-tools/auto_submission/spider_toxin_transcriptome_3/all_annotated_transcripts.txt \
--sam /home/michael/spider_toxin_devel/out.sam \
--out /home/michael/spider_toxin_devel/ena-tools/filtered.sam

samtools view -b -S filtered.sam > filtered.bam

=back

=cut

use BRAEMBL::JavaClassRunner;
BRAEMBL::JavaClassRunner->new(
  java_main_class => 'braembl.samtools.SelectAlignments',  
)->run;

