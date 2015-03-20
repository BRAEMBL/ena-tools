Description
===========

Ena-tools is a collection of scripts to help data submitters with common tasks when submitting metadata to the European Nucleotide Archive (ENA). 

For submitting metadata about studies to SRA see the script serialise_study.pl in the scripts directory. It uses ENA's REST service which is useful for submitting batches of samples and generates a receipt in html format for keeping a record of the accessions that have been assigned.

When submitting annotated transcript assemblies, it is necessary to provide bam files as supporting evidence showing how the transcripts were constructed from the reads. The scripts in scripts/samtools can be useful when preparing these bam files.

Disclaimer
==========

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, SUPPORT AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Copyright (c) 2015 BRAEMBL
