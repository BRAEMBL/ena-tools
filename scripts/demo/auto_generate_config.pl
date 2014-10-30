#!/usr/bin/env perl
=head1 auto_generate_config.pl

=head2 Description

Script to demonstrate automatically generating a configuration file.
  
This demo script shows how one can automatically generate a configuration file for the serialize_study script. This can be helpful, when the number of samples is large and the metadata for every sample varies. One can set the metadata that is fixed for all studies once in a template like this and then use a script to insert the values that can change from sample to sample. 

The code is not particularly beautiful or configurable. This type of script is meant to be used to generate a configuration file for a particular study, so in all likelihood it will be used for production only once.

=head2 Setup

=over

    export PERL5LIB=$PWD/lib:$PWD/project_lib

=back

=head2 Run

Make a preliminary check, if the script does what you want by looking at the configuration it generates:

  perl scripts/demo/auto_generate_config.pl | less
  
Then pipe it to serialise_study.pl to generate the submission files. Use the receipt in html format generated here to check that your data is accurate.
 
  perl scripts/demo/auto_generate_config.pl | perl scripts/serialise_study.pl -no_md5 -output_dir test
  
The placeholders for the accessions might be in the way, if you are only using the receipt for checking. You can get rid of them like this:
  
  perl -p -i -e 's/ENA_external_accession_for_.+?_goes_here/TBA/g;' -e 's/ENA_accession_for_.+?_goes_here/TBA/g' test/html/all_metadata.html
  
=cut

use strict;
use Carp;
use Data::Dumper;
use File::Spec;
use File::Basename;
use Hash::Util qw(lock_keys);
use BRAEMBL::DefaultLogger;
use List::MoreUtils qw{ zip };

#
# This is the file that will be used as a template for generating the final
# configuration file.
#
my $template_for_configuration_file = 'metadata/demo.for_using_template_to_create_config.cfg';

#
# Output is meant to be piped to serialize_study.pl, so logger is configured 
# to write to stderr.
#
# Another option would be to write to stdout, but prefix all lines with a hash.
#
# Here we do both.
#
my $logger_config = <<EOF
log4perl.logger=DEBUG, ScreenErr

log4perl.appender.ScreenErr=Log::Log4perl::Appender::Screen
log4perl.appender.ScreenErr.stderr=1
log4perl.appender.ScreenErr.Threshold=DEBUG
log4perl.appender.ScreenErr.Filter=ErrorFilter
log4perl.appender.ScreenErr.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.ScreenErr.layout.ConversionPattern=# %d %p> %M{2}::%L - %m%n

log4perl.filter.ErrorFilter = Log::Log4perl::Filter::LevelRange
log4perl.filter.ErrorFilter.LevelMin = TRACE
log4perl.filter.ErrorFilter.LevelMax = FATAL
log4perl.filter.ErrorFilter.AcceptOnMatch = true

EOF
;

Log::Log4perl->init( \$logger_config );

#
# The script is meant to be run without parameters, but just in case someone
# tries to get help:
#
my $help;
use Getopt::Long;
my $result = GetOptions(
  { "help" => \$help },
  'help',
);

if ($help) {
    system('perldoc', $0);
    exit;
}

my $logger = &get_logger;

my $metadata = &metadata;

my @header = qw(
  sample_id
  material
  genotype
  origin
  n_treatment
  block
  plant
  date
);

my %metadata_hash;

#
# Generate a hash from the metadata.
#
foreach my $current_metadata (@$metadata) {

  my %hash = zip @header, @$current_metadata;
  lock_keys(%hash);
  $metadata_hash{$hash{sample_id}} = \%hash;
}
lock_keys(%metadata_hash);

my %sample_id_to_directory_prefix = &sample_id_to_directory_prefix;

my %directory_prefix_to_sample_id = reverse %sample_id_to_directory_prefix;
lock_keys(%directory_prefix_to_sample_id);

my @directory = keys %directory_prefix_to_sample_id;

#
# Prepare the values that will be inserted into the final configuration file.
#
my %sample_id_to_sample_submission_metadata;
SAMPLE: foreach my $current_sample_id (keys %sample_id_to_directory_prefix) {
  
  my $experimental_setup_id = $sample_id_to_directory_prefix{$current_sample_id};
  
  my $current_metadata = $metadata_hash{$current_sample_id};
  
  # So order doesn't get messed up during the lexical sorting of strings
  # constructed with this number later on.
  #
  my $display_sample_id = sprintf("%03d", $current_sample_id);
  $logger->info($display_sample_id);
  
  my $DNA_RNA_Source = $current_metadata->{material} eq "Soil" ? "soil" : "root";

  my $read_file_subdir =  $experimental_setup_id . '_' . $current_sample_id . '/'
      . $current_sample_id . '_' . $experimental_setup_id . '.sff.gz';
  
  my $read_file = 
      '/local/path/to/files/'
      . $read_file_subdir
  ;
  
  my $read_file_ftp = 
      '/ftp/path/at/ENA/'
      . $read_file_subdir
  ;
  
  my $sample_submission_metadata = {
  
    # This is used for sorting, so has to be zero padded
    sample_id       => $display_sample_id, 
    sample_name     => "sample_${display_sample_id}",
    scientific_name => $DNA_RNA_Source eq 'root' ?
	"Rhizosphere associated fungal metagenome" :
	"Soil associated fungal metagenome"
      ,
    title           => $DNA_RNA_Source eq 'root' ?
	ucfirst("Fungal community in the rhizosphere of a plant genotype (" . $current_metadata->{genotype} . ")") :
	ucfirst("Fungal community in the $DNA_RNA_Source in which a plant genotype (" . $current_metadata->{genotype} . ") was grown")
      ,
    common_name     => "Mold on lillies",
    description     => 
	$DNA_RNA_Source eq 'root' ?
	"Amplicon sequencing of fungi from the rhizosphere of the a plant genotype (" . $current_metadata->{genotype} . ")" :
	"Amplicon sequencing of fungi from the $DNA_RNA_Source in which a plant genotype (" . $current_metadata->{genotype} . ") was grown"
      ,
    taxon_id                => 
	$DNA_RNA_Source eq 'root' ? 
	939928 : 
	410658
      ,
    DNA_RNA_Source          => $DNA_RNA_Source,
    genotype                => $current_metadata->{genotype},
    collection_date         => 
	$current_metadata->{date} eq "Dez_2014" ? 
	"2014-12" : 
	"2014-06"
      ,
    chemical_administration => 
	$current_metadata->{n_treatment} eq 'Low_N' ?
	"Low application of nitrogen fertiliser" :
	"High application of nitrogen fertiliser"
      ,
    fertilizer_regimen      => 
	$current_metadata->{n_treatment} eq 'Low_N' ?
	"20-40 kg urea N/hectare/year applied 05 Jun 2013 and 24 Dez 2013" :
	"160-180 kg urea N/hectare/year applied 05 Jun 2013 and 24 Dez 2013"
      ,
    experiment_id           => $current_sample_id,
    library_name            => "Library_${display_sample_id}",
    read_id                 => "read_" . $display_sample_id,
    experimental_setup_id   => $experimental_setup_id,
    
    field_grown_on  => "Field number " . $current_metadata->{block},
    plant_replicate => "Replicate number " . $current_metadata->{plant},
    
    read_file => $read_file,
    read_file_ftp => $read_file_ftp
  };
  
  $sample_id_to_sample_submission_metadata{$display_sample_id} = $sample_submission_metadata;  
}


use Template;
my $template = Template->new();

my $config;
$template->process(
    $template_for_configuration_file,
    {
      sample_id_to_sample_submission_metadata => \%sample_id_to_sample_submission_metadata,
    },
    \$config
);

print $config;
$logger->info("Done.");
exit;

=head2 study_id_to_directory_prefix

=cut
sub sample_id_to_directory_prefix {
  return qw(
    3	experimental_setup_no_2
    4	experimental_setup_no_3
    5	experimental_setup_no_4
    6	experimental_setup_no_5
    7	experimental_setup_no_6
    8	experimental_setup_no_7
    10	experimental_setup_no_10
    11	experimental_setup_no_11
    12	experimental_setup_no_13
    13	experimental_setup_no_14
    14	experimental_setup_no_15
    15	experimental_setup_no_16
    16	experimental_setup_no_17
    17	experimental_setup_no_18
    18	experimental_setup_no_19
    19	experimental_setup_no_20
    20	experimental_setup_no_21
    21	experimental_setup_no_22
    22	experimental_setup_no_23
    23	experimental_setup_no_24
    24	experimental_setup_no_25
    25	experimental_setup_no_26
    26	experimental_setup_no_27
    27	experimental_setup_no_28
    28	experimental_setup_no_29
    29	experimental_setup_no_30
    30	experimental_setup_no_31
    31	experimental_setup_no_32
    32	experimental_setup_no_33
    33	experimental_setup_no_34
    34	experimental_setup_no_35
    35	experimental_setup_no_36
    36	experimental_setup_no_37
    37	experimental_setup_no_38
    38	experimental_setup_no_39
    39	experimental_setup_no_40
    40	experimental_setup_no_41
    41	experimental_setup_no_42
    42	experimental_setup_no_43
    43	experimental_setup_no_44
    44	experimental_setup_no_45
    45	experimental_setup_no_46
    46	experimental_setup_no_47
    47	experimental_setup_no_48
    48	experimental_setup_no_49
    49	experimental_setup_no_50
    51	experimental_setup_no_52
    52	experimental_setup_no_53
    53	experimental_setup_no_54
    54	experimental_setup_no_55
    55	experimental_setup_no_56
    56	experimental_setup_no_57
    57	experimental_setup_no_58
    58	experimental_setup_no_59
    59	experimental_setup_no_60
    60	experimental_setup_no_61
    61	experimental_setup_no_62
    62	experimental_setup_no_63
    63	experimental_setup_no_64
    64	experimental_setup_no_65
    65	experimental_setup_no_66
    66	experimental_setup_no_67
    67	experimental_setup_no_68
    68	experimental_setup_no_69
    69	experimental_setup_no_70
    70	experimental_setup_no_71
    71	experimental_setup_no_72
    72	experimental_setup_no_73
    9	experimental_setup_no_88
    145	experimental_setup_no_2
    146	experimental_setup_no_3
    147	experimental_setup_no_4
    148	experimental_setup_no_5
    149	experimental_setup_no_6
    150	experimental_setup_no_7
    152	experimental_setup_no_10
    153	experimental_setup_no_11
    154	experimental_setup_no_13
    155	experimental_setup_no_14
    156	experimental_setup_no_15
    157	experimental_setup_no_16
    158	experimental_setup_no_17
    159	experimental_setup_no_18
    160	experimental_setup_no_19
    161	experimental_setup_no_20
    162	experimental_setup_no_21
    163	experimental_setup_no_22
    164	experimental_setup_no_23
    165	experimental_setup_no_24
    166	experimental_setup_no_25
    167	experimental_setup_no_26
    168	experimental_setup_no_27
    169	experimental_setup_no_28
    170	experimental_setup_no_29
    171	experimental_setup_no_30
    172	experimental_setup_no_31
    173	experimental_setup_no_32
    174	experimental_setup_no_33
    175	experimental_setup_no_34
    176	experimental_setup_no_35
    177	experimental_setup_no_36
    178	experimental_setup_no_37
    179	experimental_setup_no_38
    180	experimental_setup_no_39
    181	experimental_setup_no_40
    182	experimental_setup_no_41
    183	experimental_setup_no_42
    184	experimental_setup_no_43
    185	experimental_setup_no_44
    186	experimental_setup_no_45
    187	experimental_setup_no_46
    188	experimental_setup_no_47
    189	experimental_setup_no_48
    190	experimental_setup_no_49
    191	experimental_setup_no_50
    193	experimental_setup_no_52
    194	experimental_setup_no_53
    195	experimental_setup_no_54
    196	experimental_setup_no_55
    197	experimental_setup_no_56
    198	experimental_setup_no_57
    199	experimental_setup_no_58
    200	experimental_setup_no_59
    201	experimental_setup_no_60
    202	experimental_setup_no_61
    203	experimental_setup_no_62
    204	experimental_setup_no_63
    205	experimental_setup_no_64
    206	experimental_setup_no_65
    207	experimental_setup_no_66
    208	experimental_setup_no_67
    209	experimental_setup_no_68
    210	experimental_setup_no_69
    211	experimental_setup_no_70
    212	experimental_setup_no_71
    213	experimental_setup_no_72
    214	experimental_setup_no_73
    215	experimental_setup_no_74
    216	experimental_setup_no_75
    );
}

sub metadata {

  return [
    [ qw( 1	Roots	G_1X	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 2	Roots	G_1X	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 3	Roots	G_1X	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 4	Roots	G_1X	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 5	Roots	G_1X	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 6	Roots	G_1X	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 7	Roots	G_1X	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 8	Roots	G_1X	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 9	Roots	G_1X	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 10	Roots	G_1X	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 11	Roots	G_1X	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 12	Roots	G_1X	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 13	Roots	G_2Y	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 14	Roots	G_2Y	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 15	Roots	G_2Y	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 16	Roots	G_2Y	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 17	Roots	G_2Y	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 18	Roots	G_2Y	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 19	Roots	G_2Y	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 20	Roots	G_2Y	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 21	Roots	G_2Y	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 22	Roots	G_2Y	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 23	Roots	G_2Y	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 24	Roots	G_2Y	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 25	Roots	G_3Z	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 26	Roots	G_3Z	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 27	Roots	G_3Z	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 28	Roots	G_3Z	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 29	Roots	G_3Z	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 30	Roots	G_3Z	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 31	Roots	G_3Z	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 32	Roots	G_3Z	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 33	Roots	G_3Z	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 34	Roots	G_3Z	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 35	Roots	G_3Z	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 36	Roots	G_3Z	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 37	Soil	G_1X	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 38	Soil	G_1X	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 39	Soil	G_1X	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 40	Soil	G_1X	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 41	Soil	G_1X	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 42	Soil	G_1X	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 43	Soil	G_1X	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 44	Soil	G_1X	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 45	Soil	G_1X	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 46	Soil	G_1X	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 47	Soil	G_1X	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 48	Soil	G_1X	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 49	Soil	G_2Y	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 50	Soil	G_2Y	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 51	Soil	G_2Y	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 52	Soil	G_2Y	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 53	Soil	G_2Y	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 54	Soil	G_2Y	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 55	Soil	G_2Y	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 56	Soil	G_2Y	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 57	Soil	G_2Y	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 58	Soil	G_2Y	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 59	Soil	G_2Y	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 60	Soil	G_2Y	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 61	Soil	G_3Z	Taedong	High_N	1	1	Dez_2014) ],
    [ qw( 62	Soil	G_3Z	Taedong	High_N	1	2	Dez_2014) ],
    [ qw( 63	Soil	G_3Z	Taedong	High_N	2	1	Dez_2014) ],
    [ qw( 64	Soil	G_3Z	Taedong	High_N	2	2	Dez_2014) ],
    [ qw( 65	Soil	G_3Z	Taedong	High_N	3	1	Dez_2014) ],
    [ qw( 66	Soil	G_3Z	Taedong	High_N	3	2	Dez_2014) ],
    [ qw( 67	Soil	G_3Z	Taedong	Low_N	1	1	Dez_2014) ],
    [ qw( 68	Soil	G_3Z	Taedong	Low_N	1	2	Dez_2014) ],
    [ qw( 69	Soil	G_3Z	Taedong	Low_N	2	1	Dez_2014) ],
    [ qw( 70	Soil	G_3Z	Taedong	Low_N	2	2	Dez_2014) ],
    [ qw( 71	Soil	G_3Z	Taedong	Low_N	3	1	Dez_2014) ],
    [ qw( 72	Soil	G_3Z	Taedong	Low_N	3	2	Dez_2014) ],
    [ qw( 145	Roots	G_1X	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 146	Roots	G_1X	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 147	Roots	G_1X	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 148	Roots	G_1X	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 149	Roots	G_1X	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 150	Roots	G_1X	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 151	Roots	G_1X	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 152	Roots	G_1X	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 153	Roots	G_1X	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 154	Roots	G_1X	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 155	Roots	G_1X	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 156	Roots	G_1X	Taedong	Low_N	3	2	Nov_2012) ],
    [ qw( 157	Roots	G_2Y	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 158	Roots	G_2Y	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 159	Roots	G_2Y	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 160	Roots	G_2Y	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 161	Roots	G_2Y	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 162	Roots	G_2Y	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 163	Roots	G_2Y	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 164	Roots	G_2Y	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 165	Roots	G_2Y	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 166	Roots	G_2Y	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 167	Roots	G_2Y	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 168	Roots	G_2Y	Taedong	Low_N	3	2	Nov_2012) ],
    [ qw( 169	Roots	G_XY	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 170	Roots	G_XY	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 171	Roots	G_XY	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 172	Roots	G_XY	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 173	Roots	G_XY	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 174	Roots	G_XY	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 175	Roots	G_XY	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 176	Roots	G_XY	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 177	Roots	G_XY	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 178	Roots	G_XY	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 179	Roots	G_XY	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 180	Roots	G_XY	Taedong	Low_N	3	2	Nov_2012) ],
    [ qw( 181	Soil	G_1X	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 182	Soil	G_1X	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 183	Soil	G_1X	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 184	Soil	G_1X	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 185	Soil	G_1X	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 186	Soil	G_1X	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 187	Soil	G_1X	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 188	Soil	G_1X	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 189	Soil	G_1X	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 190	Soil	G_1X	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 191	Soil	G_1X	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 192	Soil	G_1X	Taedong	Low_N	3	2	Nov_2012) ],
    [ qw( 193	Soil	G_2Y	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 194	Soil	G_2Y	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 195	Soil	G_2Y	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 196	Soil	G_2Y	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 197	Soil	G_2Y	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 198	Soil	G_2Y	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 199	Soil	G_2Y	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 200	Soil	G_2Y	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 201	Soil	G_2Y	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 202	Soil	G_2Y	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 203	Soil	G_2Y	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 204	Soil	G_2Y	Taedong	Low_N	3	2	Nov_2012) ],
    [ qw( 205	Soil	G_XY	Taedong	High_N	1	1	Nov_2012) ],
    [ qw( 206	Soil	G_XY	Taedong	High_N	1	2	Nov_2012) ],
    [ qw( 207	Soil	G_XY	Taedong	High_N	2	1	Nov_2012) ],
    [ qw( 208	Soil	G_XY	Taedong	High_N	2	2	Nov_2012) ],
    [ qw( 209	Soil	G_XY	Taedong	High_N	3	1	Nov_2012) ],
    [ qw( 210	Soil	G_XY	Taedong	High_N	3	2	Nov_2012) ],
    [ qw( 211	Soil	G_XY	Taedong	Low_N	1	1	Nov_2012) ],
    [ qw( 212	Soil	G_XY	Taedong	Low_N	1	2	Nov_2012) ],
    [ qw( 213	Soil	G_XY	Taedong	Low_N	2	1	Nov_2012) ],
    [ qw( 214	Soil	G_XY	Taedong	Low_N	2	2	Nov_2012) ],
    [ qw( 215	Soil	G_XY	Taedong	Low_N	3	1	Nov_2012) ],
    [ qw( 216	Soil	G_XY	Taedong	Low_N	3	2	Nov_2012) ],
  ]
}

=head2 all_directory_names  
=cut
sub all_directory_names {
  return qw(
    experimental_setup_no_10_10
    experimental_setup_no_10_152
    experimental_setup_no_11_11
    experimental_setup_no_11_153
    experimental_setup_no_13_12
    experimental_setup_no_13_154
    experimental_setup_no_14_13
    experimental_setup_no_14_155
    experimental_setup_no_15_14
    experimental_setup_no_15_156
    experimental_setup_no_16_157
    experimental_setup_no_17_158
    experimental_setup_no_17_16
    experimental_setup_no_18_159
    experimental_setup_no_18_17
    experimental_setup_no_19_160
    experimental_setup_no_19_18
    experimental_setup_no_20_161
    experimental_setup_no_20_19
    experimental_setup_no_21_162
    experimental_setup_no_21_20
    experimental_setup_no_2_145
    experimental_setup_no_22_163
    experimental_setup_no_22_21
    experimental_setup_no_2_3
    experimental_setup_no_23_164
    experimental_setup_no_23_22
    experimental_setup_no_24_165
    experimental_setup_no_24_23
    experimental_setup_no_25_166
    experimental_setup_no_25_24
    experimental_setup_no_26_167
    experimental_setup_no_26_25
    experimental_setup_no_27_168
    experimental_setup_no_27_26
    experimental_setup_no_28_169
    experimental_setup_no_28_27
    experimental_setup_no_29_170
    experimental_setup_no_29_28
    experimental_setup_no_30_171
    experimental_setup_no_30_29
    experimental_setup_no_31_172
    experimental_setup_no_31_30
    experimental_setup_no_3_146
    experimental_setup_no_32_173
    experimental_setup_no_32_31
    experimental_setup_no_33_174
    experimental_setup_no_33_32
    experimental_setup_no_3_4
    experimental_setup_no_34_175
    experimental_setup_no_34_33
    experimental_setup_no_35_176
    experimental_setup_no_35_34
    experimental_setup_no_36_177
    experimental_setup_no_36_35
    experimental_setup_no_37_178
    experimental_setup_no_37_36
    experimental_setup_no_38_179
    experimental_setup_no_38_37
    experimental_setup_no_39_180
    experimental_setup_no_39_38
    experimental_setup_no_40_181
    experimental_setup_no_40_39
    experimental_setup_no_41_182
    experimental_setup_no_41_40
    experimental_setup_no_4_147
    experimental_setup_no_42_183
    experimental_setup_no_42_41
    experimental_setup_no_43_184
    experimental_setup_no_43_42
    experimental_setup_no_44_185
    experimental_setup_no_44_43
    experimental_setup_no_4_5
    experimental_setup_no_45_186
    experimental_setup_no_45_44
    experimental_setup_no_46_187
    experimental_setup_no_46_45
    experimental_setup_no_47_188
    experimental_setup_no_47_46
    experimental_setup_no_48_189
    experimental_setup_no_48_47
    experimental_setup_no_49_190
    experimental_setup_no_49_48
    experimental_setup_no_50_191
    experimental_setup_no_50_49
    experimental_setup_no_5_148
    experimental_setup_no_51_50
    experimental_setup_no_52_193
    experimental_setup_no_52_51
    experimental_setup_no_53_194
    experimental_setup_no_53_52
    experimental_setup_no_54_195
    experimental_setup_no_54_53
    experimental_setup_no_55_196
    experimental_setup_no_55_54
    experimental_setup_no_5_6
    experimental_setup_no_56_197
    experimental_setup_no_56_55
    experimental_setup_no_57_198
    experimental_setup_no_57_56
    experimental_setup_no_58_199
    experimental_setup_no_58_57
    experimental_setup_no_59_200
    experimental_setup_no_59_58
    experimental_setup_no_60_201
    experimental_setup_no_60_59
    experimental_setup_no_61_202
    experimental_setup_no_6_149
    experimental_setup_no_61_60
    experimental_setup_no_62_203
    experimental_setup_no_62_61
    experimental_setup_no_63_204
    experimental_setup_no_63_62
    experimental_setup_no_64_205
    experimental_setup_no_64_63
    experimental_setup_no_65_206
    experimental_setup_no_65_64
    experimental_setup_no_66_207
    experimental_setup_no_66_65
    experimental_setup_no_6_7
    experimental_setup_no_67_208
    experimental_setup_no_67_66
    experimental_setup_no_68_209
    experimental_setup_no_68_67
    experimental_setup_no_69_210
    experimental_setup_no_69_68
    experimental_setup_no_70_211
    experimental_setup_no_70_69
    experimental_setup_no_71_212
    experimental_setup_no_7_150
    experimental_setup_no_71_70
    experimental_setup_no_72_213
    experimental_setup_no_72_71
    experimental_setup_no_73_214
    experimental_setup_no_73_72
    experimental_setup_no_74_215
    experimental_setup_no_75_216
    experimental_setup_no_7_8
    experimental_setup_no_88_9
    experimental_setup_no_89_151
  )
}
