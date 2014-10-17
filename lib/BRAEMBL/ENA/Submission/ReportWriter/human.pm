package BRAEMBL::ENA::Submission::ReportWriter::human;

use Moose;

has 'reporter' => (
  is       => 'rw', 
  isa      => 'BRAEMBL::ENA::Submission::Reporter',
  required => 1,
);

sub print_report_html {

    my $self = shift;
    my $generated_file = shift;
    
    my $report =     
      "To see a summary of the metadata as html, run:\n\n"
    . "firefox " . $generated_file->{all_metadata} . "\n";
    
    return $report;
}

sub print_report_tabsep {

    my $self = shift;
    my $generated_file = shift;
    
    my $report =
      "To see a summary of the metadata in tab separated format, run:\n\n"
    . "gedit " . $generated_file->{all_metadata} . "\n\n";
    
    return $report;
}

sub print_report_sra_xml {

    my $self = shift;
    my $generated_file = shift;
    
    my $authenticated_url = $self->reporter->authenticated_url;
    my $study_alias       = $self->reporter->metadata->study_alias;
    my $compute_md5       = $self->reporter->compute_md5;
    
    my $file_friendly_study_alias = $study_alias;
    $file_friendly_study_alias =~ tr/, /__/;
    
    my $report =
    
      "To validate, add or modify your data via ENA's REST service you can run one of the following commands:\n\n"
    . "  - For the VALIDATE action, run this:\n\n";

    my $cmd = qq(curl -F "SUBMISSION=\@$generated_file->{'submission'}->{VALIDATE}" -F "STUDY=\@$generated_file->{'study'}" -F"SAMPLE=\@$generated_file->{'sample'}" -F"EXPERIMENT=\@$generated_file->{'experiment'}" -F"RUN=\@$generated_file->{'run'}"  $authenticated_url);
    
    $report .= "$cmd | xmlstarlet fo | tee last_receipt.${file_friendly_study_alias}.xml \n\n";    
    $report .= "  - For the ADD action, run this:\n\n";

    $cmd = qq(curl -F "SUBMISSION=\@$generated_file->{'submission'}->{ADD}" -F "STUDY=\@$generated_file->{'study'}" -F"SAMPLE=\@$generated_file->{'sample'}" -F"EXPERIMENT=\@$generated_file->{'experiment'}" -F"RUN=\@$generated_file->{'run'}"  $authenticated_url);
    
    $report .= "$cmd | xmlstarlet fo | tee last_receipt.${file_friendly_study_alias}.xml \n\n";    
    $report .= "  - If you want to MODIFY your submission, use the one for the object type you want to change:\n\n";
    
    my @action_source_type = qw(study sample experiment run);
    
    foreach my $current_source_type (sort @action_source_type) {
    
        my $submission_file = $generated_file->{submission}->{"MODIFY_${current_source_type}"};        
        my $uc_source_type = uc($current_source_type);        
        my $cmd = qq(curl -F "SUBMISSION=\@${submission_file}" -F "$uc_source_type=\@$generated_file->{$current_source_type}" $authenticated_url);
        
        $report .= "$cmd | xmlstarlet fo | tee last_receipt.${file_friendly_study_alias}.xml \n\n";

    }

    if (!$compute_md5) {

        $report .= "Md5 sums were not computed for the files, so submission will fail. If you want md5 sums to be generated, don't set the -no_md5 option on the command line.\n";

    }
    return $report;
}

1;
