package BRAEMBL::ENA::Submission::ReportWriter::machine;

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
      "html=" . $generated_file->{all_metadata} . "\n";    
    return $report;
}

sub print_report_tabsep {

    my $self = shift;
    my $generated_file = shift;
    
    my $report =
      "tabsep=" . $generated_file->{all_metadata} . "\n";    
    
    return $report;
}

sub print_report_sra_xml {

    my $self = shift;
    my $generated_file = shift;
    
    my $authenticated_url = $self->reporter->authenticated_url;
    my $study_alias       = $self->reporter->metadata->study_alias;
    my $compute_md5       = $self->reporter->compute_md5;
    
    my $report =
    
        "sra_xml_study=$generated_file->{'study'}\n"
      . "sra_xml_sample=$generated_file->{'sample'}\n"
      . "sra_xml_experiment=$generated_file->{'experiment'}\n"
      . "sra_xml_run=$generated_file->{'run'}\n";

    my $cmd = qq(curl -F "SUBMISSION=\@$generated_file->{'submission'}->{VALIDATE}" -F "STUDY=\@$generated_file->{'study'}" -F"SAMPLE=\@$generated_file->{'sample'}" -F"EXPERIMENT=\@$generated_file->{'experiment'}" -F"RUN=\@$generated_file->{'run'}"  $authenticated_url);
    
    $report .= "sra_xml_validate_cmd=$cmd\n";    

    $cmd = qq(curl -F "SUBMISSION=\@$generated_file->{'submission'}->{ADD}" -F "STUDY=\@$generated_file->{'study'}" -F"SAMPLE=\@$generated_file->{'sample'}" -F"EXPERIMENT=\@$generated_file->{'experiment'}" -F"RUN=\@$generated_file->{'run'}"  $authenticated_url);
    
    $report .= "sra_xml_add_cmd=$cmd\n";    
    
    my @action_source_type = qw(study sample experiment run);
    
    foreach my $current_source_type (sort @action_source_type) {
    
        my $submission_file = $generated_file->{submission}->{"MODIFY_${current_source_type}"};        
        my $uc_source_type = uc($current_source_type);
        my $cmd = qq(curl -F "SUBMISSION=\@${submission_file}" -F "$uc_source_type=\@$generated_file->{$current_source_type}" $authenticated_url);
        
        $report .= "sra_xml_submission_${current_source_type}_cmd=$cmd\n";
    }
    return $report;
}

1;
