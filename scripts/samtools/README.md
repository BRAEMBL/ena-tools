Description
===========

- select_alignments_from_sam.pl: A script for creating a sam file by selecting alignments from an existing sam file.
- revcomp_sam_alignments.pl: A script for creating a sam file based on an existing one, but where some of the alignments have been reverse complemented.

Use in data submission
======================

When submitting assembled transcripts to ENA, the bam file describing how the sequences were constructed from the reads must be submitted as supporting evidence along with the transcripts.

Transcript sequences have to be submitted in the correct orientation. They can not be submitted reverse complemented. The orientation of the transcripts is known, because the annotated gene sequence must be on the forward strand. ENA does not accept transcripts with a gene annotated on the reverse strand. However, the assembler that created the contigs from the reads does not know the orientation of a transcript, so the orientation of the contigs is arbitrary when they are created by the assembler.

If some of the contigs are reverse complemented to get the transcript sequences, then the alignment in the bam file will no longer describe it anymore. A new bam file has to be created for the transcript sequences.

These scripts can help with preparing a bam file for submission. If you are not submitting all the assembled sequences, the script select_alignments_from_sam.pl can be used to select the alignments for the sequences you want to submit.

The script revcomp_sam_alignments.pl can be used to reverse complement the alignments of those contigs that had to be reverse complemented to get the transcript sequences.

Example
=======

Convert the bam file to sam format:

~~~
samtools view -h <bam_file_from_assembler> > <$tempdir/assembly_build_instructions.sam>
~~~

Create sam file with with relevant alignments only

~~~
./scripts/samtools/select_alignments_from_bam.pl \
--select <file with names of contigs to be included in the final sam file, one name per line> \
--sam $tempdir/assembly_build_instructions.sam \
--out $tempdir/filtered.sam
~~~

Reverse complement contigs to get transcript sequences

~~~
./scripts/samtools/revcomp_bam_alignments.pl \
--revcomp <file with names of contigs that should be reverse complemented, other alignments will remain unchanged> \
--sam $tempdir/filtered.sam \
--out $tempdir/transcript_build_instructions.sam
~~~

Check processed alignments
--------------------------

The following steps assume that samtools are in the PATH.

Convert the sam file generated in the previous step to bam format:

~~~
samtools view -b -S $tempdir/transcript_build_instructions.sam -o $tempdir/transcript_build_instructions_unsorted.bam
~~~

Prepare for viewing

~~~
samtools sort $tempdir/transcript_build_instructions_unsorted.bam $tempdir/transcript_build_instructions
samtools index $tempdir/transcript_build_instructions.bam
~~~

Check, if alignments look right:

~~~
samtools tview $tempdir/transcript_build_instructions.bam
~~~

These are the build instructions needed for the submission of an annotated transcript sequence assembly.
