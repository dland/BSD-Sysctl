#! /usr/local/bin/perl
#
# mib_scan.pl - Check that we can scan through all the variables
# that sysctl(8) returns.
# Copyright (C) 2006 David Landgren, all rights reserved.

use strict;
use warnings;
use IO::Pipe;

use lib qw( blib/lib blib/arch );
use BSD::Sysctl 'sysctl';

my $s = IO::Pipe->new;
$s->reader(qw(/sbin/sysctl -Nao)) or die "Cannot open pipe from sysctl: $!\n";
while (<$s> ) {
    chomp;
    my $mib = $_;

    print "$mib: ";
    if (defined(my $res = sysctl($mib))) {
        if (ref($res) eq 'HASH') {
            print "{\n";
            print "  $_ => $res->{$_}\n" for sort keys %$res;
            print "}";
        }
        elsif (ref($res) eq 'ARRAY') {
            print "[@$res]";
        }
        else {
            print "$res";
        }
    }
    print "\n";
}
