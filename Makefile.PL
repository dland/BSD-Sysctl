use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $module_name = 'BSD::Sysctl';

if ($Config{osname} ne 'freebsd') {
    die "$module_name does not support the ($Config{osname}) platform.\n";
}

my $mapfile = 'mibfmt.map';
open my $map, '<', $mapfile or die "Cannot open $mapfile for input: $!\n";
my %define;
my $maxlen = 0;
while (<$map>) {
    chomp;
    next unless my ($key, $num, $str) = ($_ =~ /^(\S+)\t(\S+)\t(\S+)/);
    if ($str eq 'auto') {
        if ($key =~ /^[ST],(.*)/) {
            $str = 'FMT_' . uc($1);
        }
        else {
            die "$mapfile($.): cannot resolve auto name from $key\n";
        }
    }
    $maxlen = length($str) if $maxlen < length($str);
    $define{$key} = [$str, $num];
}

open my $out_h,  '>', 'bsd-sysctl.h'  or die "Cannot open C header for output: $!\n";
open my $out_pl, '>', 'bsd-sysctl.pl' or die "Cannot open Perl header for output: $!\n";

my $years = (gmtime)[5]+1900;
$years = ($years == 2006) ? $years : "2006-$years";

print $out_h <<EOH;
/* bsd-sysctl.h -- defines for $module_name
 *
 * Copyright (C) $years, David Landgren, all rights reserved.
 * This file genned by $0 at @{[scalar gmtime]}
 */

EOH

# bootinfo.h header file not available on the AMD64 platform
if (-r '/usr/include/machine/bootinfo.h') {
    print $out_h "#include <machine/bootinfo.h>\n";
}

print $out_pl <<EOH;
# bsd-sysctl.pl -- constants for $module_name
#
# Copyright (C) $years, David Landgren, all rights reserved.
# This file genned by $0 at @{[scalar gmtime]}

EOH

for my $key (sort keys %define) {
    printf $out_h "#define %-${maxlen}s %2d\n", @{$define{$key}};
    printf $out_pl "use constant %-${maxlen}s => %2d;\n", @{$define{$key}};
}

print $out_pl "\n1;\n";

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
);
