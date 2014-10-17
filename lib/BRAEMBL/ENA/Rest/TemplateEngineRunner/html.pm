package BRAEMBL::ENA::Rest::TemplateEngineRunner::html;

use Moose;
extends 'BRAEMBL::ENA::Rest::TemplateEngineRunner::Base';

has 'output_file_extension' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'html',
);

has 'template_factory' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return {
          all_metadata => File::Spec->join($self->template_dir, 'all_metadata.html'),
        };
  },
);

sub apply_templates {

    my $self  = shift;
    my $study = shift;
    
    my $output_dir = $self->output_dir;
    
    use Template;
    use Template::Stash;
    
    $Template::Stash::HASH_OPS->{ key_value_list } = sub {
        my $hash = shift;        
        
        my @item;
        foreach my $current_key (keys %$hash) {
            push @item, "$current_key=" . $hash->{$current_key};
        }
        return join ',', @item;
    };

    $Template::Stash::SCALAR_OPS->{ link_friendly_chars } = sub {
        my $string = shift;
        
        $string =~ tr/, /__/;
#         $string =~ s/,/_/g;
#         $string =~ s/ /_/g;
        
        return $string;
    };

    my $template = Template->new( 
        ENCODING     => 'utf8',
        ABSOLUTE     => 1, 
        RELATIVE     => 1,
        INCLUDE_PATH => File::Spec->join($self->template_dir),
        PLUGIN => {
            AsTabSep            => 'Template::Plugin::AsTabSep',
            NoEmptyLines        => 'Template::Plugin::NoEmptyLines',
            NoLeadingWhitespace => 'Template::Plugin::NoLeadingWhitespace',
            # HtmlEntities        => 'Template::Plugin::HtmlEntities',
        }
    );

    my $template_var = {
        study  => $study,
    };
    
    my %generated_file;

    use File::Path qw(make_path);
    make_path($output_dir);
    
    use Hash::Util qw( lock_keys );
    
    foreach my $current_template (keys %{$self->template_factory}) {
    
        my $xml;
        
        #open my $handle, '<:encoding(UTF-8)', $self->template_factory->{$current_template}
        #  or die "Can't open for reading: $!";

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
