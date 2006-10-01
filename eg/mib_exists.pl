#! /usr/local/bin/perl
#
# see whether a given name exists as a sysctl variable.
# Copyright (C) David Landgren, all rights reserved.

use warnings;
use strict;

use lib qw( blib/lib blib/arch );
use BSD::Sysctl;

for my $mib (@ARGV) {
    print "$mib ", (
        BSD::Sysctl::_mib_exists($mib)
            ? 'exists'
            : 'does not exist'
        ),
        $/
    ;
}
