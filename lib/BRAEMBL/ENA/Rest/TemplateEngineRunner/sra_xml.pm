package BRAEMBL::ENA::Rest::TemplateEngineRunner::sra_xml;

use Moose;
extends 'BRAEMBL::ENA::Rest::TemplateEngineRunner::Base';

has 'template_format' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'xml',
);

has 'output_file_extension' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'xml',
);

has 'template_factory' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return {
          study      => File::Spec->join($self->template_dir, 'study.xml'),
          sample     => File::Spec->join($self->template_dir, 'sample.xml'),
          run        => File::Spec->join($self->template_dir, 'run.xml'),
          experiment => File::Spec->join($self->template_dir, 'experiment.xml'),
          submission => File::Spec->join($self->template_dir, 'submission.xml'),
      };
  },
);

sub apply_templates {

    my $self  = shift;
    my $study = shift;
    
    my $output_dir = $self->output_dir;
    
    use Template;

    my $template = Template->new( 
        ENCODING     => 'utf8',
        ABSOLUTE     => 1, 
        RELATIVE     => 1,
        INCLUDE_PATH => File::Spec->join($self->template_dir),
        PLUGIN => {
            AsTabSep            => 'Template::Plugin::AsTabSep',
            NoEmptyLines        => 'Template::Plugin::NoEmptyLines',
            NoLeadingWhitespace => 'Template::Plugin::NoLeadingWhitespace',
            #HtmlEntities        => 'Template::Plugin::HtmlEntities',
        }
    );

    my $template_var = {
        study  => $study,
    };
    
    my %generated_file;
    
    $generated_file{submission} = {};

    use File::Path qw(make_path);
    make_path($output_dir);
    
    my @action_source_type = qw(study sample experiment run);

    foreach my $current_action ('VALIDATE', 'ADD', 'HOLD') {
    
        $generated_file{submission}{$current_action} = "$output_dir/submission_${current_action}." . $self->output_file_extension;

        $template_var->{action} = $current_action;
        $template_var->{action_source_type} = \@action_source_type;

        my $xml;

        $template->process(
            $self->template_factory->{submission},
            $template_var,
            \$xml
        )
            || confess ($template->error());

        my $fh = new IO::File;
        if ($fh->open(">" . $generated_file{submission}{$current_action})) {
            $fh->print($xml);
            $fh->close;
        }            
    }
    foreach my $current_action ('MODIFY') {
    
        foreach my $current_source_type (@action_source_type) {
    
            $generated_file{submission}{"${current_action}_${current_source_type}"}
              = "$output_dir/submission_${current_action}_${current_source_type}." . $self->output_file_extension;

            $template_var->{action} = $current_action;
            $template_var->{action_source_type} = [ $current_source_type ];

            my $xml;

            $template->process(
                $self->template_factory->{submission},
                $template_var,
                \$xml
            )
                || confess ($template->error());

            my $fh = new IO::File;
            if (
                  $fh->open(
                      '>' . $generated_file{submission}{ "${current_action}_${current_source_type}" }
                  )
            ) {
                $fh->print($xml);
                $fh->close;
            }
        }
    }
    use Hash::Util qw( lock_keys );
    lock_keys(%{$generated_file{submission}});
    
    foreach my $current_template (keys %{$self->template_factory}) {    
        next if ($current_template eq 'submission');
    
        my $xml;

        $template->process(
            $self->template_factory->{$current_template},
            $template_var,
            \$xml
        )
            || confess ($template->error());

        $generated_file{$current_template} = "$output_dir/$current_template." . $self->output_file_extension;
            
        my $fh = new IO::File;
        if ($fh->open(">" . $generated_file{$current_template})) {
            $fh->print($xml);
            $fh->close;
        }            

    }
    lock_keys(%generated_file);    
    return \%generated_file;
}


1;
