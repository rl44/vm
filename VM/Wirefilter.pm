
package VM::Wirefilter;
use strict;

use VM::Config;
use VM::Util;
use VM::VDE;
use IO::Socket::UNIX;

sub new {

        my $class = shift;
        my $self = {};
        $self->{'id'} = shift;
        bless($self, $class);
        return $self;
}

sub mpath {

	my $self = shift;

	return "$RUN/f/".$self->{'id'};
}

sub management_path {

        my $self = shift;

        return $self->mpath."/mgmt";
}

sub spawn_wirefilter {

	my $self = shift;
	my $id = $self->{'id'};
	my $quiet = shift;
	my $vde1 = shift;
	my $vde2 = shift;

	my $cmd = $quiet ? \&cmd_quiet : \&cmd;

	&$cmd("mkdir -p ".$self->mpath);

	my $sock1 = $vde1->socket_path;
	my $sock2 = $vde2->socket_path;

	&$cmd("$WIREFILTER --daemon -M ".$self->management_path." -v $sock1:$sock2");
}

sub wirefilter_cmds {

        my $self = shift;
        my $quiet = shift;

        my $mon = new IO::Socket::UNIX($self->management_path);
        if(!$mon) {
                warn "vde_cmd(): ".$self->management_path.": $!";
                return;
        }

        my @chatscript = ();
        for my $cmd (@_) {
                push @chatscript, $WIREFILTER_PROMPT;
                push @chatscript, "$cmd\n";
        }

	        push @chatscript, $VDE_PROMPT; push @chatscript, "logout\n";

        my $chat = $quiet ? \&chat_quiet : \&chat_echo;

        &$chat($mon, [@chatscript]);

        $mon->close();
}

1;

