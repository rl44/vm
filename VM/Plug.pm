
package VM::Plug;
use strict;

use VM::Config;
use IO::File;

sub plug {

	my $quiet = shift;
	my $machine = shift;
	my $switch = shift;
	my $pos = shift;

	my $socket = $switch->socket_path;
	my $mac = $machine->mac_addr($pos);

	$machine->qemu_mon_cmd("host_net_add vde vlan=$pos,sock=$socket",
				$quiet					);
	my $mon_out = $machine->qemu_mon_cmd(
		"pci_add auto nic model=virtio,vlan=$pos,macaddr=$mac", $quiet);

	my ($bus, $slot) = $mon_out =~ /OK domain \d+, bus (\d+), slot (\d+)/;

	warn "bus ? slot ?" if !defined($bus) or !defined($slot);

	my $desc_path = $machine->mpath."/eth$pos";
	my $desc_file = new IO::File;
	warn "$desc_path: $!" unless $desc_file->open(">$desc_path");
	print $desc_file "$bus:$slot\n";
	$desc_file->close();
}

sub unplug {

	my $quiet = shift;
	my $machine = shift;
	my $pos = shift;

	my $desc_path = $machine->mpath."/eth$pos";
	my $desc_file = new IO::File;
	warn "$desc_path: $!" unless $desc_file->open("<$desc_path");
	my $l = <$desc_file>; chomp($l);
	$desc_file->close();
	warn "$desc_file: [$l]" unless length($l)>1;

	$machine->qemu_mon_cmd("pci_del $l", $quiet);
	$machine->qemu_mon_cmd("host_net_remove $pos vde.$pos", $quiet);
}

1;

