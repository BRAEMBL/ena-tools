package System::ShellRunner;

use Moose::Role;

sub run_cmd {

    #my $self = shift;
    my $cmd  = shift;
    my $test_for_success = shift;

    my $param_ok = (!defined $test_for_success) || (ref $test_for_success eq 'ARRAY');

    confess("Parameter error! If test_for_success is set, it must be an array of hashes!") 
      unless ($param_ok);
    
    my $stdout = `$cmd`;

    my $execution_failed = $? == -1;    
    confess("Could not execute command:\n$cmd\n")
      if ($execution_failed);

    my $program_died = $? & 127;
    confess(
        sprintf (
            "Child died with signal %d, %s coredump\n",
            ($? & 127), ($? & 128) ? 'with' : 'without'
        )
    ) if ($program_died);

    my $exit_value = $? >> 8;
    my $program_completed_successfully = $exit_value == 0;
    confess("exited with value $exit_value")
        if (!$program_completed_successfully);

    if ($test_for_success) {

      foreach my $current_test_for_success (@$test_for_success) {

        confess('Type error') unless(ref $current_test_for_success eq 'HASH');

        use Hash::Util qw( lock_hash );
        lock_hash(%$current_test_for_success);

        my $current_test = $current_test_for_success->{test};
        confess('Test must be a sub!') unless (ref $current_test eq 'CODE');

        my $test_succeeded = $current_test->();

        confess(
            "The following command failed:\n"
            . "\n" . $cmd . "\n\n"
            . "Reason: " . $current_test_for_success->{fail_msg} . "\n"
        ) unless($test_succeeded);
      }
    }
    return $stdout;
}

1;