use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $module_name = 'BSD::Sysctl';

if ($Config{osname} ne 'freebsd') {
    die "OS unsupported ($Config{osname}). Here's a nickel, go buy yourself a real OS.\n";
}

my %define;
my $maxlen = 0;
my $num = 16;	# numbers below 16 are reserved for <sys/sysctl.h> CTLTYPE_*
while (<DATA>) {
    chomp;
    next if /^#/ || /^\s*$/;
    my $key = 'S,' . $_;
    my $str = 'CTLTYPE_' . uc($_);
    $maxlen = length($str) if $maxlen < length($str);
    $define{$key} = [$str, $num++];
}

open my $out_h,  '>', 'bsd-sysctl.h'  or die "Cannot open C header for output: $!\n";
open my $out_pl, '>', 'bsd-sysctl.ph' or die "Cannot open Perl header for output: $!\n";

open my $in_sys, '<', '/usr/include/sys/sysctl.h' or die "Cannot open sys/sysctl.h: $!\n";

while (<$in_sys>) {
    next unless (/^#define	(CTLTYPE_[A-Z0-9]+)\s+(0x[0-9a-f]+|[0-9]+)/);
    printf $out_pl "use constant %-${maxlen}s => %s;\n", $1, $2;
}

close $in_sys;

for my $key (sort keys %define) {
    printf $out_h "#define %-${maxlen}s %2d\n", @{$define{$key}};
    printf $out_pl "use constant %-${maxlen}s => %2d;\n", @{$define{$key}};
}

close $out_h;
close $out_pl;

WriteMakefile(
    NAME          => $module_name,
    AUTHOR        => 'David Landgren',
    ABSTRACT_FROM => 'Sysctl.pm',
    VERSION_FROM  => 'Sysctl.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'XSLoader' => 0
    },
    PM_FILTER     => 'perl -pe "if (/^\#include (.+)$$/) {		\
					open FILE, \\$$1 or		\
					    die \"open \\$$1\";		\
					while (<FILE>) { print; };	\
					close FILE;			\
					next;				\
				};"',
    clean => {
        FILES => 'bsd-sysctl.h bsd-sysctl.ph',
    },
    MIN_PERL_VERSION => '5.8.0',
);

__DATA__
#
# List of structures we are able to parse.
#
# This produces
#  -- bsd-sysctl.h (#defines for Sysctl.xs)
#  -- bsd-sysctl.ph (use constants for Sysctl.pm)

clockinfo
devstat
icmpstat
igmpstat
ipstat
loadavg
nfsrvstats
nfsstats
ntptimeval
rip6stat
tcpstat
timeval
udpstat
vmtotal
xinpcb
xvfsconf
