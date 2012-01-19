#!/usr/bin/perl
#

# Ce script reprend l'esprit d'un script configure dans ses objectifs. En plus
# d'un script configure (tel que généré par autoconf), il a pour objectif de
# permettre une installation d'un environnement fonctionnel de manière
# autonome, sans nécessiter la présence d'autre chose que ce script.
#
# Il peut être exécuté directement sous une forme :
#
#             wget -q -O- URL | perl
#
#                    ou
#
#             curl -L URL | perl
#

# FIXME : permettre que l'interpréteur perl soit ailleurs que dans /usr/bin/perl
#         à modifier dans bin/*
#
# TBC ...
#

my $SCRIPT_BASE_GIT_URL = 'http://github.com/rl44/vm';
# my $SCRIPT_BASE_RAW_URL = 'https://raw.github.com/rl44/vm/master/dists/current.tar.gz';
my $SCRIPT_BASE_RAW_URL = 'http://ubuntuone.com/4Ew4g6z9J9y0HG33FaeO3b';

# sortie de find . -type f | cut -c3- | sed 's/^/q{/;s/$/},/' | grep -v .git
my @BASE_CONTENTS = (
		q{bootstrap.pl},
		q{bin/monitor},
		q{bin/virtfs_umount},
		q{bin/start_switch},
		q{bin/on_monitor},
		q{bin/plug_usb},
		q{bin/terminal-ttyS0},
		q{bin/wirefilter_console},
		q{bin/start_vnc_machine},
		q{bin/switch_console},
		q{bin/start_wirefilter},
		q{bin/on},
		q{bin/terminal},
		q{bin/on_switch},
		q{bin/virtfs_mount},
		q{bin/stop_switch},
		q{bin/unplug_usb},
		q{bin/plug},
		q{bin/hostssl-pki},
		q{bin/on_wirefilter},
		q{bin/unplug},
		q{bin/plug_slirp},
		q{bin/stop_machine},
		q{bin/start_machine},
		q{bin/vde2pcap},
		q{bin/stop_wirefilter},
		q{bin/vde_plug},
		q{README.en},
		q{dotme},
		q{Changelog},
		q{VM/Plug.pm},
		q{VM/Config.pm},
		q{VM/VDE.pm},
		q{VM/Qemu.pm},
		q{VM/Util.pm},
		q{VM/Wirefilter.pm},
		q{TODO},
		q{keys/index.txt},
		q{keys/server1.conf},
		q{keys/serial},
		q{exemples/exemple01.sh},
		q{COPYING},
		q{README},
		q{tests/test-functions.dotme},
		q{tests/pki/test02.sh},
		q{tests/pki/test-ssl.dotme},
		q{tests/pki/test03.sh},
		q{tests/pki/test01.sh},
);

my $verbose = 1;
$verbose = undef if grep {/-q/} @ARGV;

# répertoire de destination

my $destination = "vm";

# Vérifier la présence des modules perl (use ...;) utilisés dans les différents
# programmes.
#

# FIXME : installer automatiquement les modules manquants (cpan)
#

ensure_perl_modules(qw(Time::HiRes IO::Socket::UNIX Exporter IO::File
                       English));

sub ensure_perl_modules {

    my @modules = @_;
    print "Checking perl modules...\n" if($verbose);

    for my $m (@modules) {
        print "\t$m... " if $verbose;
        eval qq{use $m;};
        if($@) {
            die "$@";
        }
        else {
            print "ok\n" if $verbose;
        }
    }
}

# Création d'un répertoire d'installation
#

print "Checking if directory $destination exists... " if $verbose;

unless(-w "$destination") {
	mkdir "$destination" or die("mkdir(): $destination: $!");
	print "created\n" if $verbose;
}
else {
	print "ok\n" if $verbose;
}

print "Changing working directory to $destination... " if $verbose;
chdir "$destination" or die("chdir(): $destination: $!");
print "ok\n" if $verbose;

# Vérification d'un certain nombre de commandes nécessaires au chargement
# et à l'exécution des composants
#

unless(ensure_command(q{socat -V},
                      qr{socat version 1\.7|socat version 2}s,
		              q{socat version}))        { 

	# TODO : faire mieux que ça...
	#

	warn("install socat by your own (with SSL support)\n");
	die("socat >= v1.7 needed");
}

unless(ensure_command(q{socat -h},
                      q{openssl:},
		              q{socat compiled with OpenSSL})) {

	warn("socat with SSL support needed for some functions");
}

unless(ensure_command(q{wget --version}, qr{GNU [Ww]get \d}s, q{wget})) {

	die("wget required by this installer");
}

sub ensure_command {

    my $command = shift;
    my $expected_output = shift;
    my $comment = shift;

    $comment = $command unless length($comment);

    print "Checking for $comment... " if $verbose;
    my $output = qx{$command 2>&1};

    if($output =~ m{$expected_output}g) {
        print "ok\n" if $verbose;
        return 1;
    }
    else {
        print "no\n" if $verbose;
        return 0;
    }
}

# Files
#

unless(ensure_file("bootstrap.pl")) {

	if(ensure_command('git --version', qr{^git version \d}, 'git')) {

		# git clone dans un répertoire "vm"
		#

		print "chdir to .. ...";
		if(chdir('..')) {
			print "ok\n";
		}
		else {
			die(qq{chdir(".."): $!});
		}
		print "git clone $SCRIPT_BASE_GIT_URL ...\n";
		system(qq{git clone "$SCRIPT_BASE_GIT_URL"});
		print "chdir to vm ...";
		if(chdir('vm')) {
			print "ok\n";
		}
		else {
			die(qq{chdir(".."): $!});
		}
	}

	unless(ensure_file("bootstrap.pl")) {

			print "Downloading ...\n";
			system(qq{wget -O- "$SCRIPT_BASE_RAW_URL" | tar xvfz -});
			for my $f (@BASE_CONTENTS) {
					unless(ensure_file("$f")) {
						die "Error downloading $f";
					}
			}
	}
}

sub ensure_file {

	my $path = shift;

    print "Checking for $path... " if $verbose;
	if(-r "$path") {
		print "ok\n";
		return 1;
	}
	else {
		print "not found\n";
		return 0;
	}
}

