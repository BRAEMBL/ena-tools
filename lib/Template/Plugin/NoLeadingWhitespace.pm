package Template::Plugin::NoLeadingWhitespace;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;

    $self->{ _DYNAMIC } = 1;

    # first arg can specify filter name
    $self->install_filter($self->{ _ARGS }->[0] || 'NoLeadingWhitespace');

    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    my @line = split "\n", $text;
    map { s/^\s+//g } @line;

    return join "\n", @line;
}

1;
