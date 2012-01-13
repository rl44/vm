
package VM::VDE;
use strict;

use VM::Config;
use VM::Util;
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

	return "$RUN/s/".$self->{'id'};
}

sub management_path {

	my $self = shift;

	return $self->mpath."/mgmt";
}

sub socket_path {

	my $self = shift;
	
	return $self->mpath."/vde";
}

sub spawn_vde {

	my $self = shift;
	my $id = $self->{'id'};
	my $quiet = shift;

	my $cmd = $quiet ? \&cmd_quiet : \&cmd;

	&$cmd("mkdir -p ".$self->mpath);

	&$cmd("$VDE_SWITCH -d -s ".$self->socket_path." -M ".$self->management_path);
}

sub vde_cmds {

	my $self = shift;
	my $quiet = shift;
	
	my $mon = new IO::Socket::UNIX($self->management_path);
	if(!$mon) {
		warn "vde_cmd(): ".$self->management_path.": $!";
		return;
	}

	my @chatscript = ();
	for my $cmd (@_) {
		push @chatscript, $VDE_PROMPT;
		push @chatscript, "$cmd\n";
	}

	push @chatscript, $VDE_PROMPT; push @chatscript, "logout\n";

	my $chat = $quiet ? \&chat_quiet : \&chat_echo;

	&$chat($mon, [@chatscript]);

	$mon->close();
}

1;

