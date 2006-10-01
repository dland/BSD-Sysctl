#! /usr/local/bin/perl
#
# mib_info.pl - check that the lookup cache is sane
# Copyright (C) 2006 David Landgren, all rights reserved.

use warnings;
use strict;

use lib qw( blib/lib blib/arch );
use BSD::Sysctl;

for my $mib (@ARGV) {
    if (BSD::Sysctl::_mib_exists($mib)) {
        my $info = BSD::Sysctl::_mib_info($mib);
        print "info $mib => [@{[unpack('i i/i', $info)]}]\n";
    }
    else {
        warn "no such mib: $mib\n";
    }
}

for my $k (sort keys %BSD::Sysctl::MIB_CACHE) {
    print "cache $k => [@{[unpack('i i/i', $BSD::Sysctl::MIB_CACHE{$k})]}]\n";
}

for my $mib (@ARGV) {
    if (my $val = BSD::Sysctl::_mib_lookup($mib)) {
        if (ref($val) eq 'HASH') {
            print "$mib = {\n";
            print "  $_ => $val->{$_}\n" for sort keys %$val;
            print "}\n";
        }
        else {
            print "$mib = $val\n";
        }
    }
}
