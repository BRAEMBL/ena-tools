Description
===========

- convert_gff_to_embl.pl: A simple script that can be used to convert annotation from gff to embl format. 
- serialise_study.pl and
- insert_values_from_ENA.pl: Scripts to help submit metadata to the sequence read archive (SRA) at ENA.

Submission of metadata to SRA
=============================

Users can choose one of the sample configuration files in the metadata directory that is of a similar type as their own study, e.g. `metadata/demo.default_study_type_1.cfg`.

Then they make a copy and change the values in it to those of their own study. The script is run with this configuration file like this:

```bash
time color perl scripts/serialise_study.pl -config_file metadata/demo.default_study_type_1.cfg -authenticated_url https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere
```

If all goes well, you will see an output like this:

```bash
2014/10/20 15:47:07 INFO> SampleBuilder.remove_units::140 - Using checklist ERC000011
2014/10/20 15:47:07 INFO> SampleBuilder.remove_units::149 - Using checklist checklists/ERC000011.xml for processing attributes of sample 1
2014/10/20 15:47:07 INFO> Serialiser.serialise_study::51 - Creating submission files for: Genome of an organism
2014/10/20 15:47:07 INFO> Serialiser.serialise_study::52 - Results will be written to scripts/../auto_submission/demo.default_study_type_1
To see a summary of the metadata in tab separated format, run:

gedit scripts/../auto_submission/demo.default_study_type_1/tabsep/all_metadata.txt

To validate, add or modify your data via ENA's REST service you can run one of the following commands:

  - For the VALIDATE action, run this:

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_VALIDATE.xml" -F "STUDY=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/study.xml" -F"SAMPLE=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/sample.xml" -F"EXPERIMENT=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/experiment.xml" -F"RUN=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/run.xml"  https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

  - For the ADD action, run this:

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_ADD.xml" -F "STUDY=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/study.xml" -F"SAMPLE=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/sample.xml" -F"EXPERIMENT=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/experiment.xml" -F"RUN=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/run.xml"  https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

  - If you want to MODIFY your submission, use the one for the object type you want to change:

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_MODIFY_experiment.xml" -F "EXPERIMENT=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/experiment.xml" https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_MODIFY_run.xml" -F "RUN=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/run.xml" https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_MODIFY_sample.xml" -F "SAMPLE=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/sample.xml" https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

curl -F "SUBMISSION=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/submission_MODIFY_study.xml" -F "STUDY=@scripts/../auto_submission/demo.default_study_type_1/sra_xml/study.xml" https://www.ebi.ac.uk/ena/submit/drop-box/submit/?auth=secretauthenticationstringhere | xmlstarlet fo | tee last_receipt.Genome_of_an_organism.xml 

Md5 sums were not computed for the files, so submission will fail. If you want md5 sums to be generated, don't set the -no_md5 option on the command line.
To see a summary of the metadata as html, run:

firefox scripts/../auto_submission/demo.default_study_type_1/html/all_metadata.html

real	0m0.524s
user	0m0.280s
sys	0m0.108s
```

As the script suggests, you can open the preliminary receipt in firefox like this:

```bash
# Copy and pasted from script output
firefox scripts/../auto_submission/demo.default_study_type_1/html/all_metadata.html
```

And check, if the metadata is correct. If all is well, you can run the VALIDATE action by copy and pasting the command the script has generated. This will send the xml files to ENA for validations, but it will not store any data. If validation was successfull, you can run the ADD action to store the data at ENA.

Finally you can use the `scripts/insert_values_from_ENA.pl` script to insert the accessions returned from ENA into the receipt so you have documentation of your submission.

Checking out the script
=======================

Clone the git repository like this:

```bash
git clone https://github.com/BRAEMBL/ena-tools.git
```

This will create a new directory "ena-tools":

```bash
cd ena-tools/
```

Dependencies
============

Perl dependencies
-----------------

The script uses the following perl modules:

  * Config::General
  * Template
  * String::Util
  * File::Slurp
  * Mouse
  * Moose
  * Moose::Util::TypeConstraints
  * List::AllUtils
  * Set::Scalar
  * Log::Log4perl

You can install them by running

```
sudo cpan
```

then for every module you need, type "install" + modulename, e.g.:

```
install Config::General
```

I also recommend installing xmlstarlet. On Ubuntu, you can install it like this:

```
sudo apt-get install xmlstarlet
```

Running the script
==================

Setup environment
-----------------

If you have cd'ed into the directory with `cd ena-tools/` after checking out, you can set you `PERL5LIB` like this:

```
export PERL5LIB=$PWD/lib
```

I like setting this:

```
color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
```

which will make anything written to `STDERR` appear in red on the console.

Script documentation
--------------------

The script has pod documentation, you can get it like this:

```bash
./scripts/serialise_study.pl -help
```

Which will show you how to 

  * generate a configuration file, 
  * use the script to generate xml files for submission to ENA and
  * the commands to validate and submit the metadata.

For testing purposes, you can run the script with one of the demo files provided:

```bash

time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.default_study_type_1.cfg -authenticated_url $authenticated_url

time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.bacterial_submission.cfg -authenticated_url $authenticated_url

time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.metagenomics_samples.cfg -authenticated_url $authenticated_url
```

The files referenced in the configuration files don't actually exist, so generation of md5 sums is turned off (`-no_md5` option).
  
If you followed the steps successfully, ENA's REST service will send you a receipt and if you used one of the commands the script suggested, the receipt will be in `last_receipt.${study_name}.xml`. Where `study_name` is the name of your configuration file without the suffix ".cfg".

The script will also have generated a report summarising the metadata you have submitted in html and tab separated format.
  
After the submission
--------------------

For simplicity, set

```bash
study_name=<Name of your configuration file without the suffix ".cfg">
```

If you are using the default settings, you should have the following files (Test, by copy and pasting the block below):

```bash
#
# The receipt sent by ENA
#
ls -lah last_receipt.${study_name}.xml
#
# The metadata in html format
#
ls -lah auto_submission/${study_name}/html/all_metadata.html
#
# The metadata in tab separated format
#
ls -lah auto_submission/${study_name}/tabsep/all_metadata.txt
```

to the file name of the receipt of your last submission.

Now you can use the script `scripts/insert_values_from_ENA.pl` to insert the values returned from ENA like this:

```bash
xmlstarlet tr xslt/receipt_to_mapping.xslt receipts/${study_name}.xml | perl scripts/insert_values_from_ENA.pl auto_submission/${study_name}/html/all_metadata.html > auto_submission/${study_name}/html/metadata.${study_name}.html
 
xmlstarlet tr xslt/receipt_to_mapping.xslt receipts/${study_name}.xml | perl scripts/insert_values_from_ENA.pl auto_submission/${study_name}/tabsep/all_metadata.txt > auto_submission/${study_name}/tabsep/metadata.${study_name}.txt
```

If you check the files

```bash
firefox auto_submission/${study_name}/html/all_metadata.html
gedit auto_submission/${study_name}/tabsep/all_metadata.txt
```

you should see the metadata together with the accessions returned from ENA.
