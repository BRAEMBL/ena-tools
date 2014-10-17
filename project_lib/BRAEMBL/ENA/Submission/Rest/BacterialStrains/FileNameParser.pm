package BRAEMBL::ENA::Submission::Rest::BacterialStrains::FileNameParser;

use Moose;

extends 'BRAEMBL::ENA::Submission::FileNameParser::GenericFileAndStrainLists';

has 'suffix' => (
  is      => 'rw', 
  isa     => 'Str',
  lazy    => 1,
  default => sub { 
      my $self = shift;
      return $self->metadata->read_file_suffix
  }
  
);

sub create_run_identifier {

    my $self = shift;
    my $name = shift;

    use File::Basename;
    # Strip the directory name and the suffix
    #
    my $basename = basename($name, $self->suffix);
    
    # Looks like we can't assign better aliases once they have been added.
    # Commenting this out for now, but should use this code for the next study
    # with paired end files.
    #
    if (undef) {
        # Can be R1 or R2 depending on which one of the two files from the paired 
        # end run happened to come first. There is no point in having this and it
        # would just be confusing, so removing it here.
        #
        my $regex_1_worked = $basename =~ s/_R.$//;
        my $regex_2_worked = $basename =~ s/_R._001$//;
        
        my $one_of_the_regexes_worked = $regex_1_worked || $regex_2_worked;
        
        if (!$one_of_the_regexes_worked) {
            confess "Couldn't parse $basename!";
        }
    }
    return $basename;
}

1
;