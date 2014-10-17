package BRAEMBL::ModuleLoader;

use Moose::Role;
use Module::Load;

sub load_or_confess {
  my $module = shift;
  eval {
    load $module;
  };
  confess(
    "Can't load module: $module!\n"
    . "PERL5LIB=" . $ENV{PERL5LIB}
    . "\n"
    . $@
  )
    if ($@);
}

sub load_and_instantiate {

  my $module = shift;  
  my @constructor_args = @_;
  load_or_confess($module);
  
  my $object;
  eval {
    $object = $module->new(@constructor_args);
  };
  if ($@) {
    confess($@);
  }
  return $object;
}


1
;
