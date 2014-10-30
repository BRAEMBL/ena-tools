package BRAEMBL::ENA::Submission::Metadata::TypeConstraints;

use Moose::Util::TypeConstraints;

my @allowed_instrument_model = (
  '454 GS',
  '454 GS 20',
  '454 GS FLX',
  '454 GS FLX+',
  '454 GS FLX Titanium',
  '454 GS Junior',

  'Illumina Genome Analyzer',
  'Illumina Genome Analyzer II',
  'Illumina Genome Analyzer IIx',
  'Illumina HiSeq 2500',
  'Illumina HiSeq 2000',
  'Illumina HiSeq 1000',
  'Illumina MiSeq',
  'Illumina HiScanSQ',

  'unspecified',
);

enum 'allowed_instrument_model_enum' => \@allowed_instrument_model;

subtype 'instrument_model_type',
  as 'allowed_library_selection_enum',
  message { "Got $_, an instrument_model_type must be one of: " . (join ', ', @allowed_instrument_model) };

my @allowed_library_selection = (
  'RANDOM',
  'PCR',
  'RANDOM PCR',
  'RT-PCR',
  'HMPR',
  'MF',
  'repeat fractionation',
  'size fractionation',
  'MSLL',
  'cDNA',
  'ChIP',
  'MNase',
  'DNase',
  'Hybrid Selection',
  'Reduced Representation',
  'Restriction Digest',
  '5-methylcytidine antibody',
  'MBD2 protein methyl-CpG binding domain',
  'CAGE',
  'RACE',
  'MDA',
  'padlock probes capture method',
  'other',
  'unspecified',
);

enum 'allowed_library_selection_enum' => \@allowed_library_selection;

subtype 'library_selection_type',
  as 'allowed_library_selection_enum',
  message { "Got '$_', and library_strategy_type must be one of: " . (join ', ', @allowed_library_selection) };

my @allowed_library_strategy = (
  'WGS',
  'WGA',
  'WXS',
  'RNA-Seq',
  'miRNA-Seq',
  'ncRNA-Seq',
  'WCS',
  'CLONE',
  'POOLCLONE',
  'AMPLICON',
  'CLONEEND',
  'FINISHING',
  'ChIP-Seq',
  'MNase-Seq',
  'DNase-Hypersensitivity',
  'Bisulfite-Seq',
  'EST',
  'FL-cDNA',
  'CTS',
  'MRE-Seq',
  'MeDIP-Seq',
  'MBD-Seq',
  'Tn-Seq',
  'VALIDATION',
  'FAIRE-seq',
  'SELEX',
  'RIP-Seq',
  'ChIA-PET',
  'OTHER',
);

enum 'allowed_library_strategy_enum' => \@allowed_library_strategy;

subtype 'library_strategy_type',
  as 'allowed_library_strategy_enum',
  message { "Got $_, an allowed_library_strategy must be one of: " . (join ', ', @allowed_library_strategy) };

my @allowed_existing_study_type = (
    'Whole Genome Sequencing',
    'Metagenomics',
    'Transcriptome Analysis',
    'Resequencing',
    'Epigenetics',
    'Synthetic Genomics',
    'Forensic or Paleo-genomics',
    'Gene Regulation Study',
    'Cancer Genomics',
    'Population Genomics',
    'RNASeq',
    'Exome Sequencing',
    'Pooled Clone Sequencing',
    'Other',
);

enum 'allowed_existing_study_type_enum' => \@allowed_existing_study_type;

subtype 'existing_study_type',
  as 'allowed_existing_study_type_enum',
  message { "Got $_, an existing_study_type must be one of: " . (join ', ', @allowed_existing_study_type) . " If using \"Other\" please add new_study_type=\"TODO: add own term\" attribute."};

  my @allowed_library_layout = qw(
  SINGLE
  PAIRED
);

enum 'library_layout_type_enum' => \@allowed_library_layout;

subtype 'library_layout_type',
  as 'library_layout_type_enum',
  message { "A library_layout_type must be one of: " . join ', ', @allowed_library_layout };


my @allowed_platforms = qw(
  ILLUMINA
  LS454
);

enum 'platform_type_enum' => \@allowed_platforms;

subtype 'platform_type',
  as 'platform_type_enum',
  message { "A platform_type must be one of: " . join ', ', @allowed_platforms };

subtype 'references_by_id' => as 'ArrayRef[Str]';

coerce 'references_by_id',
  from 'Str',
  via sub {
    my $comma_separated_list = $_;    
    use String::Util 'trim';    
    my @references_by_id = map { trim($_) } split ',', $comma_separated_list;    
    return \@references_by_id;
  };


subtype 'HashRefOfExperiments' => as 'HashRef[BRAEMBL::ENA::Submission::Metadata::SingleExperiment]';

coerce 'HashRefOfExperiments',
  from 'HashRef',
  via sub {
    my $configured_experiments = $_;
    
    my $new_hash = {};
    use BRAEMBL::ENA::Rest::Experiment;
    foreach my $experiment_name (keys %$configured_experiments) {
    
      my $new_key = $experiment_name;
      
      $new_key =~ s/experiment_//;
    
      $new_hash->{$new_key}
	= BRAEMBL::ENA::Submission::Metadata::SingleExperiment->new(
	  %{$configured_experiments->{$experiment_name}}
	);
    }

    return $new_hash;
  };

1;
