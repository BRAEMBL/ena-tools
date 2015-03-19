package BRAEMBL::JavaClassRunner;

use Moose;

use System::ShellRunner;
use BRAEMBL::DefaultLogger;

has 'java_main_class' => (
  is       => 'rw', 
  isa      => 'Str',
  required => 1,
);

has 'logger' => (
  is       => 'rw', 
  builder  => sub {
    return get_logger;
  }
);

sub check_dependencies {

  my $self = shift;

  my @dependency = qw( java ant );

  my $dependencies_satisfied = 1;
  foreach my $current_dependency (@dependency) {

    my $current_dependency_location = `which $current_dependency`;

    if ($current_dependency_location) {
      $self->logger->info("Found $current_dependency in path: " . $current_dependency_location);
    } else {
      $self->logger->fatal("Couldn't find $current_dependency in path!");
      $dependencies_satisfied = undef;
    }
  }
  die unless ($dependencies_satisfied);
}

sub run {

  my $self = shift;  
  my $logger = $self->logger;
  
  $self->check_dependencies;

  $logger->info("Compiling java file using ant");
  my $stdout = System::ShellRunner::run_cmd("ant compile");
  $logger->info($stdout);

  my $jar_file_directory = 'jar';

  opendir(my $dh, $jar_file_directory) || die "can't opendir $jar_file_directory: $!";
  my @jar_file_list = map { $jar_file_directory . '/' . $_ } sort grep { $_ !~ /^\.+$/ } readdir($dh);
  closedir $dh;
  my $jar_file_bit = join ':', @jar_file_list;

  my $cmd_line_parameters = join ' ', @ARGV;

  my $java_main_class = $self->java_main_class;

  my $cmd = qq(java -cp $jar_file_bit:build/ $java_main_class $cmd_line_parameters);

  $logger->info("Runnning $cmd");
  $stdout = System::ShellRunner::run_cmd("$cmd");
  $logger->info("Java has completed. The output is:\n" . $stdout);
}

1;
