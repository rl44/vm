
package VM::Qemu;
use strict;

use VM::Util;
use VM::Config;
use IO::Socket::UNIX;
use IO::File;
use English;

sub new {

	my $class = shift;
	my $self = {};
	$self->{'id'} = shift;
	bless($self, $class);
	return $self;
}

sub id {

	return $_[0]->{'id'};
}

sub mpath {

	return "$RUN/m/".$_[0]->id;
}

sub ttyS1_path {

	my $self = shift;

	return $self->mpath."/ttyS1";
}

sub ttyS0_path {

	my $self = shift;
	
	return $self->mpath."/ttyS0";
}

sub tty_path {

	return $_[0]->ttyS1_path;
}

sub monitor_path {

	my $self = shift;

	return $self->mpath."/monitor";
}

sub shared_path {

	my $self = shift;

	return $self->mpath."/shared";
}

sub _mac_prefix {

	my $self = shift;

	my $from_ip = qx(ip -o addr ls dev eth0);
	$from_ip =~ s/^.+?inet \d+\.\d+\.\d+\.(\d+).+$/$1/s;
	$from_ip = 0 unless $from_ip > 0;
	my $from_pid = $PROCESS_ID;

	my $mac_prefix = sprintf("52:54:%02x:%02x:%02x",
					$from_ip,
					$from_pid >> 8,
					$from_pid & 0xff  );

	my $macpath = $self->mpath."/macaddr";
	my $macfile = new IO::File;
	warn "$macpath: $!" unless $macfile->open(">$macpath");
	print $macfile "$mac_prefix\n";
	$macfile->close();
}

sub mac_prefix {

	my $self = shift;

	my $macpath = $self->mpath."/macaddr";
	my $macfile = new IO::File;
	warn "$macpath: $!" unless $macfile->open("<$macpath");
	my $prefix = <$macfile>;
	chomp $prefix;

	return $prefix;
}

sub mac_addr {

	my $self = shift;
	my $pos = shift;

	return sprintf("%s:%02d", $self->mac_prefix, $pos);
}

sub spawn_qemu {

	my $self = shift;
	my $quiet = shift;

	my $id = $self->{'id'};

	my $cmd = $quiet ? \&cmd_quiet : \&cmd;
	my $quiet_stderr = $quiet ? ' >/dev/null 2>&1' : '';

	&$cmd('mkdir -p '.$self->mpath);

	my $disk = $self->mpath."/disk.qcow2";
	&$cmd("$QEMU_IMG create -f qcow2 $disk -b $BASE_IMAGE $quiet_stderr");

	my $drive = "-drive file=$disk$DISK_OPTS";
	my $serial0 = "-serial unix:".$self->ttyS0_path.",server,nowait";
	my $serial1 = "-serial unix:".$self->ttyS1_path.",server,nowait";
	my $monitor = "-monitor unix:".$self->monitor_path.",server,nowait";

	&$cmd("mkdir -p ".$self->shared_path);
	my $virtfs = "-virtfs local,path=".$self->shared_path
			.",security_model=mapped,mount_tag=virtfs";

	&$cmd("$QEMU -name $id $drive $serial0 $serial1 $monitor $virtfs $quiet_stderr");

	$self->_mac_prefix;
}

sub spawn_qemu_vnc {

	my $self = shift;
	my $port = shift;
	my $quiet = shift;

	my $id = $self->{'id'};

	my $cmd = $quiet ? \&cmd_quiet : \&cmd;
	my $quiet_stderr = $quiet ? ' >/dev/null 2>&1' : '';

	&$cmd('mkdir -p '.$self->mpath);

	my $disk = $self->mpath."/disk.qcow2";
	&$cmd("$QEMU_IMG create -f qcow2 $disk -b $BASE_IMAGE $quiet_stderr");

	my $drive = "-drive file=$disk$DISK_OPTS";
	my $serial0 = "-serial unix:".$self->ttyS0_path.",server,nowait";
	my $serial1 = "-serial unix:".$self->ttyS1_path.",server,nowait";
	my $monitor = "-monitor unix:".$self->monitor_path.",server,nowait";

	my $vnc = "-vnc :$port,lossy -vga vmware";

	&$cmd("$QEMU -name $id $drive $serial0 $serial1 $monitor $vnc $quiet_stderr");

	$self->_mac_prefix;
}

sub qemu_mon_cmd {

	my $self = shift;
	my $id = $self->{'id'};
	my $cmd = shift;
	my $quiet = shift;
	my $mon_output = '';

	verb "qemu_mon_cmd(): $id: $cmd" unless $quiet;
	
	my $mon_path = $self->monitor_path;
	my $mon = new IO::Socket::UNIX($mon_path);
	if(!$mon) {
		warn "qemu_mon_cmd(): $mon_path: $!";
		return;
	}

	my $chat = $quiet ? \&chat_output_quiet : \&chat_output;

	$mon_output = &$chat($mon, [	'(qemu)' => "$cmd\n",
					'(qemu)' => ''		]);

	print "\n" unless $quiet;

	$mon->close();

	return $mon_output;
}

sub is_running {

	my $self = shift;
	my $quiet = shift;

	return 0 unless -r $self->monitor_path;

	my $status = $self->qemu_mon_cmd('info status', $quiet);
	return 0 unless $status =~ /VM status: running/;

	return 1;
}

sub plug_usb {

	my $self = shift;
	my $pos = shift;
	my $quiet = shift;

	$self->qemu_mon_cmd(
		"usb_add serial::unix:".$self->mpath."/ttyUSB$pos,server,nowait");
}

sub unplug_usb {

	my $self = shift;
	my $pos = shift;
	my $quiet = shift;

	my $qtree = $self->qemu_mon_cmd('info qtree', $quiet); 

	my @usb_dev = ();

	while($qtree =~ /\G.+?chardev = usbserial(\d+).+?addr ([\d\.]+)/sg) {

		my $pos = $1;
		my $addr = $2;

		$usb_dev[$pos-1] = $addr;

		warn("usb_dev[".($pos - 1)."]=$addr");
	}

	$self->qemu_mon_cmd("usb_del ".$usb_dev[$pos], $quiet);
}

sub commands_from_login {

	my $self = shift;
	my $id = $self->{'id'};
	my $quiet = shift;

	my $ttyS0_path = $self->ttyS0_path;
	my $ttyS0 = new IO::Socket::UNIX($ttyS0_path);
	if(!$ttyS0) {
		warn "command_from_login(): $ttyS0_path: $!";
		return;
	}

	my $chat = $quiet ? \&chat_quiet : \&chat;

	&$chat($ttyS0, [	'' => "\n",
			'login:' => "$USER\n",
			'Password:' => "$PASSWORD\n",
			map {$PROMPT => "$_\n"} @_,
			$PROMPT => "exit\n"		]);

	#while(my $cmd = shift) {
		#chat($ttyS0, [$PROMPT => "$cmd\n"]);
	#}

	#chat($ttyS0, [$PROMPT => "exit\n"]);

	$ttyS0->close();

	print "\n" unless $quiet;
}

sub halt_gracefully {

	my $self = shift;
	my $id = $self->{'id'};
	my $quiet = shift;

	my $ttyS0_path = $self->ttyS0_path;
	my $ttyS0 = new IO::Socket::UNIX($ttyS0_path);
	if(!$ttyS0) {
		warn "command_from_login(): $ttyS0_path: $!";
		return;
	}

	my $chat = $quiet ? \&chat_quiet : \&chat;
	my $cmd = $quiet ? \&cmd_quiet : \&cmd;

	&$chat($ttyS0, [	'' => "\n",
			'login:' => "$USER\n",
			'Password:' => "$PASSWORD\n",
			$PROMPT => "$HALT_CMD\n",
			# '\[sudo\] password for \S+:' => "$PASSWORD\n",
			$POWERDOWN_MSG => ''				]);

	$ttyS0->close();

	if(!$OS_POWERDOWN) {
		my $mon_path = $self->monitor_path;
		my $mon = new IO::Socket::UNIX($mon_path);
		if(!$mon) {
			warn "qemu_mon_cmd(): $mon_path: $!";
			return;
		}

		&$chat($mon, ['(qemu)' => "q\n"]);

		$mon->close();
	}

	&$cmd("rm -f ".$self->mpath."/macaddr");
	&$cmd("rm -f ".$self->mpath."/monitor");
	&$cmd("rm -f ".$self->mpath."/ttyS0");
	&$cmd("rm -f ".$self->mpath."/ttyS1");
	&$cmd("rm -f ".$self->mpath."/ttyUSB*");
}

sub start {

	my $self = shift;
	my $quiet = shift;

	$self->spawn_qemu($quiet);
	$self->qemu_mon_cmd('c', $quiet);
}

sub start_vnc {

	my $self = shift;
	my $port = shift;
	my $quiet = shift;

	$self->spawn_qemu_vnc($port, $quiet);
	$self->qemu_mon_cmd('c', $quiet);
}

1;

