package BRAEMBL::ENA::Rest::TemplateEngineRunnerFactory;

use Moose;

=head2 create_template_engine_runner
=cut
sub create_template_engine_runner {

  my $self          = shift;
  my $template_type = shift;
  
  use Module::Load;

  my $module = "BRAEMBL::ENA::Rest::TemplateEngineRunner::${template_type}";
  load $module;  
  my $metadata = $module->new();
  
  return $metadata;
}


1;
