#! /usr/local/bin/perl
#
# set_blackhole - set a variable
# Copyright (C) 2006 David Landgren, all rights reserved.

use warnings;
use strict;
use lib qw( blib/lib blib/arch );

use BSD::Sysctl qw(sysctl sysctl_set);

$< and die "Not running as root\n";

my $sysctl = 'net.inet.udp.blackhole';
my $val = sysctl( $sysctl );
print "$sysctl: $val\n";

my $new = shift;
my $ret = sysctl_set( $sysctl, defined $new ? $new : $val );
if ($ret) {
    $val = sysctl( $sysctl );
    print "$sysctl: $val\n";
}
else {
    print "error: \$!=$!\n";
}
