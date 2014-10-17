package Template::Plugin::AsTabSep;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;

    $self->{ _DYNAMIC } = 1;

    # first arg can specify filter name
    $self->install_filter($self->{ _ARGS }->[0] || 'AsTabSep');

    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    my @line = split "\n", trim($text);
    use String::Util 'trim';
    
    my $tabsep = join "\t", map { trim($_) } @line;    

    return $tabsep;
}

1;
