# 02-set.t
# Advanced sanity checks for BSD::Sysctl
#
# Copyright (C) 2006 David Landgren

use strict;
use Test::More tests => 5;

use BSD::Sysctl qw(sysctl sysctl_set);

SKIP: {
    skip( 'TEST_BSD_SYSCTL_NAME environment variable not set', 5 )
        unless exists $ENV{TEST_BSD_SYSCTL_NAME};
    skip( 'TEST_BSD_SYSCTL_VALUE environment variable not set', 5 )
        unless exists $ENV{TEST_BSD_SYSCTL_VALUE};

    my $var   = $ENV{TEST_BSD_SYSCTL_NAME};
    my $value = $ENV{TEST_BSD_SYSCTL_VALUE};

    my $original = sysctl($var);
    ok(defined($original), "able to read $var") or diag "err=$!";

    skip( 'Not running as root (this is probably a sane choice for you)', 4 )
        if $<;

    my $ret = sysctl_set($var, $value);
    ok(defined($ret), "able to set $var to $value") or diag "err=$!";

    my $new = sysctl($var);
    is( $new, $value, "read back the new value" );

    $ret = sysctl_set($var, $original);
    ok(defined($ret), "able to reset $var to $original") or diag "err=$!";

    $new = sysctl($var);
    is( $new, $original, "read back the old value" );
}
