# 01-get.t
# Basic sanity checks for BSD::Sysctl
#
# Copyright (C) 2006 David Landgren

use strict;
use Test::More tests => 17;

use BSD::Sysctl qw(sysctl sysctl_exists);

ok(BSD::Sysctl::_mib_exists('kern.maxproc'), 'mib exists');

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ostype');
    ok($sysctl_info, 'mib lookup kern.ostype');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::FMT_A, '... display format type A');
    is_deeply(\@oid, [1, 1], '... oid 1.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ipc.maxsockbuf');
    ok($sysctl_info, 'mib lookup kern.ipc.maxsockbuf');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    # This is FMT_INT for FreeBSD 4.x, deal with it
    # is($fmt, BSD::Sysctl::FMT_ULONG, '... display format type ULONG');
    is_deeply(\@oid, [1, 30, 1], '... oid 1.30.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ipc.maxsockbuf');
    ok($sysctl_info, 'mib lookup kern.ipc.maxsockbuf');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    # This is FMT_INT for FreeBSD 4.x, deal with it
    # is($fmt, BSD::Sysctl::FMT_ULONG, '... display format type ULONG');
    is_deeply(\@oid, [1, 30, 1], '... oid 1.30.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('net.inet.ip.portrange.last');
    my $portrange_last = BSD::Sysctl::_mib_lookup('net.inet.ip.portrange.last');
    cmp_ok($portrange_last, '>',   1024, 'min value of net.inet.ip.portrange.last');
    cmp_ok($portrange_last, '<=', 65535, 'max value of net.inet.ip.portrange.last');
}

ok(sysctl_exists('kern.maxusers'), 'kern.maxusers exists');
ok(!sysctl_exists('kern.maxbananas'), 'kern.maxbananas does not exist');

{
    my $load_avg = sysctl('vm.loadavg');
    is(ref($load_avg), 'ARRAY', 'vm.loadavg is an array');
    is(scalar(@$load_avg), 3, 'vm.loadavg has 3 elements');
}

{
    my $lastpid = BSD::Sysctl->new('kern.lastpid');
    my $pid = $lastpid->get();
    ok(defined($pid), 'got the last pid');
    $pid = $lastpid->get();
    ok(defined($pid), 'got the last pid again');
}

is(scalar(keys %BSD::Sysctl::MIB_CACHE), 5, 'cached mib count')
    or do { diag("cached: [$_]") for sort keys %BSD::Sysctl::MIB_CACHE };
