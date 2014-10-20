
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

If you have cd'ed into the directory with `cd ena_submission/` after checking out, you can set you `PERL5LIB` like this:

```
export PERL5LIB=$PWD/lib
```

I like setting this:

```
color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
```

which will make anything written to STDERR appear in red on the console.

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
time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.bacterial_submission.cfg -authenticated_url $authenticated_url
time color perl scripts/serialise_study.pl -no_md5 -config_file metadata/demo.spider_toxin.cfg -authenticated_url $authenticated_url
```

The files referenced in the configuration files don't actually exist, so generation of md5 sums is turned off (`-no_md5` option).
  
If you followed the steps successfully, ENA's REST service will send you a receipt and if you used one of the commands the script suggested, the receipt will be in last_receipt.${study_name}.xml. Where study_name is the name of your configuration file without the suffix ".cfg".

The script will also have generated a report summarising the metadata you have submitted in html and tab separated format.
  
After the submission
--------------------

For simplicity, set

```bash
study_name=<Name of your configuration file without the suffix ".cfg">
```

If you are using the default settings, you should have the following files (Test, by copy and pasting the block belor):

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

Disclaimer
==========

```
Copyright (c) 2014 BRAEMBL

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, SUPPORT AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
