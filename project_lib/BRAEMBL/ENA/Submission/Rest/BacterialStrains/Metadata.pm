package BRAEMBL::ENA::Submission::Rest::BacterialStrains::Metadata;

use Moose;
with 'BRAEMBL::ENA::Submission::Metadata::Roles::Common';
with 'BRAEMBL::ENA::Submission::Rest::BacterialStrains::BacterialMetadata';
with 'BRAEMBL::ENA::Submission::Rest::BacterialStrains::BacterialRnaSeqFiles';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::PairedEnd';
with 'BRAEMBL::ENA::Submission::Metadata::Roles::SingleExperiment';

1
;
