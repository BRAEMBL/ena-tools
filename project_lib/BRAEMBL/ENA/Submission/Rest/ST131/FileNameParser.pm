package BRAEMBL::ENA::Submission::ST131::FileNameParser;

use Moose;

sub parse {

    my $self = shift;
    my $name = shift;
    # 702DAABXX_s18_7_1_sequence.txt.bz2

    # In general, files from the AGRF will have this format:
    #
    # <sample_name>_<flowcell_ID>_<index>_<lane>_<readNum>_fastq.gz
    #
    # This one is different though.
    #

    #my $sample_name my $flowcell_ID my $index my $lane my $readNum
    
    use File::Basename;
    my $basename = basename($name);

    (
        my $run_name,
        my $strain_name,
        my $lane_1,
        my $lane_2,
        my $rest_of_it
    ) = split '_', $basename;
    
    if (!$strain_name) {
        my $dirname = dirname($name);
        confess("Can't parse strain name in file $basename in directory $dirname!");
    }

    my $result = {
        run_name    => $run_name,
        strain_name => $strain_name,
        lane_1      => $lane_1,
        lane_2      => $lane_2,
        rest_of_it  => $rest_of_it,
        run_identifier => "${lane_1}_${lane_2}"
    };

    use Hash::Util qw( lock_keys );
    lock_keys(%$result);

    return $result;
};

1
;