#! /usr/local/bin/perl
#
# mib_show.pl - Fetch a sysctl variable and display the results
# Copyright (C) 2006 David Landgren, all rights reserved.

use warnings;
use strict;
use lib qw( blib/lib blib/arch );

use BSD::Sysctl 'sysctl';

for my $mib (@ARGV) {
    if (defined(my $res = sysctl($mib))) {
        if (ref($res) eq 'HASH') {
            print "$mib = {\n";
            print "  $_ => $res->{$_}\n" for sort keys %$res;
            print "}\n";
        }
        elsif (ref($res) eq 'ARRAY') {
            print "$mib = [@$res]\n";
        }
        else {
            print "$mib = $res\n";
        }
    }
    else {
        warn "$mib: no such mib\n";
    }
}
