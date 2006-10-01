use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

if ($Config{osname} ne 'freebsd') {
    die "This module does not support the ($Config{osname}) platform.\n";
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

open my $out_h, '>', 'bsd-sysctl.h' or die "Cannot open C header for output: $!\n";

print $out_h <<EOH;
/* bsd-sysctl.h -- defines for BSD::Sysctl
 *
 * Copyright (C) 2006, David Landgren, all rights reserved.
 * This file genned by $0 at @{[scalar gmtime]}
 */

EOH

open my $out_pl, '>', 'bsd-sysctl.pl' or die "Cannot open Perl header for output: $!\n";

print $out_pl <<EOH;
# bsd-sysctl.pl -- constants for BSD::Sysctl
#
# Copyright (C) 2006, David Landgren, all rights reserved.
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
    NAME => 'BSD::Sysctl',
    VERSION_FROM => 'Sysctl.pm',
    PREREQ_PM => { 'XSLoader' => 0 },
);
