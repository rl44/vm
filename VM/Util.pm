
package VM::Util;
use strict;
use Exporter 'import';
our @EXPORT = qw(	&verb &cmd &cmd_quiet
			&chat &chat_echo &chat_quiet &chat_output
			&chat_output_quiet				);

sub verb {
	print @_;
	print "\n";
}

sub _cmd {

	my $cmd = $_[0];
	my $quiet = $_[1];

	verb "cmd(): $cmd" unless $quiet;

	system($cmd);

	if($? == -1) {
		warn "cmd(): $!";
	}
	elsif($? & 127) {
		warn 'cmd(): killed by signal '.($? & 127).' '.
		     (($? & 128) ? 'with' : 'without').' coredump';
	}
	elsif($? != 0) {
		warn 'cmd(): exit('.($? >> 8).')';
	}
}

sub cmd {

	_cmd($_[0], undef);
}

sub cmd_quiet {

	_cmd($_[0], 1);
}

sub _chat {

	my $echo = $_[0];
	my $with_output = $_[1];
	my $quiet = $_[2];
	my $fh = $_[3];
	my @chatscript = @{$_[4]};

	# warn "chatscript = [".join(", ", @chatscript)."]\n";

	my $oldout = $|; $| = 1;
	my $output = '';

	EXPECT: for(;;) {

		my $expect = shift @chatscript;
		my $send = shift @chatscript;

		last if !defined $expect or !defined $send;

		# verb "chat(): expect \"$expect\"";

		my $buf = '';

		if(length($expect) > 0) {
			for(;;) {

				#my $c = getc($fh);
				my $c;
				my $n = sysread($fh, $c, 4096);
				
				if($n < 1) {
					warn "chat(): read(): $!";
					last EXPECT;
				}

				print $c unless $quiet;
				$buf .= $c;

				last if $buf =~ /$expect/;
			}
		}

		$output .= $buf if $with_output;

		print $fh "$send";
		print "$send" if($echo);
	}

	#print "\n";

	$| = $oldout;

	return $output if $with_output;
}

sub chat {_chat(undef, undef, undef, @_);}
sub chat_echo {_chat(1, undef, undef, @_);}
sub chat_quiet {_chat(undef, undef, 1, @_);}
sub chat_output {_chat(0, 1, undef, @_);}
sub chat_output_quiet {_chat(0, 1, 1, @_);}

1;

