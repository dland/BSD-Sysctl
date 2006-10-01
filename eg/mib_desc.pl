#! /usr/local/bin/perl
#
# mib_info.pl - check that the lookup cache is sane
# Copyright (C) 2006 David Landgren, all rights reserved.

use warnings;
use strict;

use lib qw( blib/lib blib/arch );
use BSD::Sysctl 'sysctl_description';

for my $mib (@ARGV) {
    if (my $val = sysctl_description($mib)) {
        print "$mib = $val\n";
    }
}
