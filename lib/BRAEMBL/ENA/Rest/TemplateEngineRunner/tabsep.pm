package BRAEMBL::ENA::Rest::TemplateEngineRunner::tabsep;

use Moose;
extends 'BRAEMBL::ENA::Rest::TemplateEngineRunner::html';

has 'output_file_extension' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'txt',
);

has 'template_factory' => (
  is      => 'rw', 
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
      my $self = shift;
      return {
          all_metadata => File::Spec->join($self->template_dir, 'all_metadata.txt'),
        };
  },
);

1;
