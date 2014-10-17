package BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::Metadata;

use Moose;

with 'BRAEMBL::ENA::Submission::Metadata::Roles::Common';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::PairedEnd';
with 'BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::Metadata::SampleAttributes';
with 'BRAEMBL::ENA::Submission::Rest::MetagenomicsSamples::Metadata::RnaSeqFiles';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::SingleExperiment';

1
;
