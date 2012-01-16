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

sub ensure_command {

    my $command = shift;
    my $expected_output = shift;

    print "Checking for $command... " if $verbose;
    my $output = qx{$command 2>&1};
    if($command =~ m{$expected_output}) {
        print "ok\n" if $verbose;
        return 1;
    }
    else {
        print "no\n" if $verbose;
        return 0;
    }
}


