#! /usr/local/bin/perl


use warnings;
use strict;

use lib qw( blib/lib blib/arch );
use BSD::Sysctl;

for my $mib (@ARGV) {
    if (my $info = BSD::Sysctl::_mib_info($mib)) {
        my ($fmtkey, @oid) = unpack( 'i i/i', $info );
        print "$mib => ", join('.', @oid), " (fmt=$fmtkey)\n";
    }
    else {
        warn "no such mib: $mib\n";
    }
}
