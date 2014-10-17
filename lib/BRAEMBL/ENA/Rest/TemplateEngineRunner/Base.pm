package BRAEMBL::ENA::Rest::TemplateEngineRunner::Base;

use Moose;

has 'template_dir' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'output_dir' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'not set',
);

has 'template_format' => (
  is      => 'rw', 
  isa     => 'Str',
  default => 'html',
);

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
      confess("Abstract attribute");
  }
);

sub apply_templates { 
    confess("Abstract method");
}


1;
