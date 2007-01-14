# 03-iterator.t
# Basic sanity checks for BSD::Sysctl
#
# Copyright (C) 2006 David Landgren

use strict;
use Test::More tests => 3;

use BSD::Sysctl;

my $it = BSD::Sysctl->iterator('kern.ipc');
ok( defined($it), 'defined a BSD::Sysctl iterator' );

SKIP: {
    my @sysctl = `sysctl -N kern.ipc`;
    skip( 'failed to backtick sysctl binary', 2 )
        unless @sysctl;
    my $x = $it->next;
    my $first = shift @sysctl;
    chomp $first;
    is( $first, $x, 'iterate kern.ipc' ) or do {
        diag( "bin: " . join( ' ', map{ord} split //, $first));
        diag( " xs: " . join( ' ', map{ord} split //, $x));
    };
    my $count;
    ++$count while $it->next;
    is( $count, scalar(@sysctl), 'number of elements in subtree' );
}
