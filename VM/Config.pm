
package VM::Config;
use strict;
use Exporter 'import';
our @EXPORT = qw(	$VM_BASE $QEMU_PREFIX $BIOS $CPU $MEM
			$QEMU_OPTS $QEMU $DISK_OPTS $QEMU_IMG
			$BASE_IMAGE $RUN $USER $PASSWORD $PROMPT
			$HALT_CMD $POWERDOWN_MSG $OS_POWERDOWN
			$VDE_SWITCH $SLIRPVDE $VDE_PROMPT $VDE_PLUG
			$WIREFILTER $WIREFILTER_PROMPT
			$ARCH
			$SOCAT_PREFIX $SOCAT
			$KEY_DIR $OPENSSL $SSL_KEYSIZE
			$SSL_CA_EXPIRY_DAYS $SSL_SERVER_CERT_EXPIRY_DAYS
			$SSL_CLIENT_CERT_EXPIRY_DAYS                     );

our $VM_BASE = $ENV{'VM_BASE'};
our $ARCH = $ENV{'ARCH'};
our $VM_ENGINE = $ENV{'VM_ENGINE'};

# our $QEMU_PREFIX = '/tmp/qemu';
our $QEMU_PREFIX = "$VM_BASE/qemu-kvm-$ARCH";
our $BIOS = "-bios $QEMU_PREFIX/share/qemu/bios.bin";

our $CPU = $VM_ENGINE eq 'kvm' ?
		  '-cpu host -enable-kvm'
		: '-cpu qemu32 -no-kvm';

our $MEM = "-m 128m";
our $QEMU_OPTS = '-S -nographic -usb -net none -balloon virtio -daemonize';
our $QEMU_LIB = "LD_LIBRARY_PATH=$QEMU_PREFIX/lib";
our $QEMU = "$QEMU_LIB $QEMU_PREFIX/bin/qemu $CPU $BIOS $MEM $QEMU_OPTS";
our $DISK_OPTS = ',if=virtio,index=0,media=disk,boot=on';
our $QEMU_IMG = "$QEMU_LIB $QEMU_PREFIX/bin/qemu-img";
#our $BASE_IMAGE = '/tmp/ubuntu-11.10-mini2.qcow2';

our $BASE_IMAGE = "$VM_BASE/debian-$ARCH.qcow2";
$BASE_IMAGE = "$VM_BASE/debian-i686.qcow2" if $VM_ENGINE eq 'qemu';

our $RUN = '/tmp/vm-'.$ENV{'USER'};
our $USER = 'root';
our $PASSWORD = 'rootme';
our $PROMPT = "\n$USER\@".'\S+?:.+[\$\#] ';
our $HALT_CMD = "halt";
our $POWERDOWN_MSG = "Power down";
our $OS_POWERDOWN = 1;

our $VDE_PREFIX = "$VM_BASE/vde-$ARCH";
our $VDE_LIB = "LD_LIBRARY_PATH=$VDE_PREFIX/lib";
our $VDE_SWITCH = "$VDE_LIB $VDE_PREFIX/bin/vde_switch";
our $VDE_PROMPT = 'vde\$ ';
our $SLIRPVDE = "$VDE_LIB $VDE_PREFIX/bin/slirpvde";
our $VDE_PLUG = "$VDE_LIB $VDE_PREFIX/bin/vde_plug";
our $WIREFILTER = "$VDE_LIB $VDE_PREFIX/bin/wirefilter";
our $WIREFILTER_PROMPT = 'VDEwf\$ ';

our $SOCAT_PREFIX = "$VM_BASE/socat-$ARCH";
our $SOCAT_LIB = "LD_LIBRARY_PATH=$SOCAT_PREFIX";
our $SOCAT = "$SOCAT_LIB $SOCAT_PREFIX/bin/socat";

our $KEY_DIR = "$VM_BASE/keys";

our $OPENSSL = "openssl";
our $SSL_KEYSIZE = 1024;
our $SSL_CA_EXPIRY_DAYS = 365;
our $SSL_SERVER_CERT_EXPIRY_DAYS = 30;
our $SSL_CLIENT_CERT_EXPIRY_DAYS = 30;

1;


