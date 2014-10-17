package BRAEMBL::ENA::Submission::Rest::CoralGenome::FileNameParser;

use Moose;

extends 'BRAEMBL::ENA::Submission::FileNameParser::GenericFileAndStrainLists';

has 'metadata' => (
  is      => 'rw', 
);

sub parse {

    my $self = shift;
    my $name = shift;

    use File::Basename;
    
    my $basename = basename($name);
    
    my $result = {
        run_identifier => $basename
    };

    use Hash::Util qw( lock_keys );
    lock_keys(%$result);

    return $result;
};

1
;