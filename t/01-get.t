# 01-get.t
# Basic sanity checks for BSD::Sysctl
#
# Copyright (C) 2006, 2009 David Landgren

use strict;
use Test::More tests => 29;

use BSD::Sysctl qw(sysctl sysctl_exists);

ok(BSD::Sysctl::_mib_exists('kern.maxproc'), 'mib exists');

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ostype');
    ok($sysctl_info, 'mib lookup kern.ostype');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::CTLTYPE_STRING, '... display format type STRING');
    is_deeply(\@oid, [1, 1], '... oid 1.1');
}

{
    my $ostype = sysctl('kern.ostype');
    is($ostype, "FreeBSD");
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.ipc.maxsockbuf');
    ok($sysctl_info, 'mib lookup kern.ipc.maxsockbuf');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::CTLTYPE_ULONG, '... display format type ULONG');
    is_deeply(\@oid, [1, 30, 1], '... oid 1.30.1');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('kern.geom.confxml');
    ok($sysctl_info, 'mib lookup kern.geom.confxml');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::CTLTYPE_STRING, '... display format type STRING');
    my $confxml = sysctl('kern.geom.confxml');
    ok($confxml, 'value of "kern.geom.confxml" is defined');
    like($confxml, qr(^\s*<([^>]+)>.*</\1>\s*$)m, 'value of "kern.geom.confxml" is XML');
}

{
    my $sysctl_info = BSD::Sysctl::_mib_info('vm.zone_stats');
    ok($sysctl_info, 'mib lookup vm.zone_stats');
    my ($fmt, @oid) = unpack( 'i i/i', $sysctl_info );

    is($fmt, BSD::Sysctl::CTLTYPE_OPAQUE, '... display format type OPAQUE');
    my $zst = sysctl('vm.zone_stats');
    ok($zst, 'value of "vm.zone_stats" is defined');
    my $maxid = sysctl('kern.smp.maxid');
    cmp_ok($maxid, '>', 1, "max CPU id is meaningful");

    # struct uma_stream_header
    my ($version, $maxcpus, $count, $pad) = unpack('L4', $zst);
    is ($version, 1, 'uma stream version');
    is ($maxcpus, $maxid + 1, 'uma max cpus');
    cmp_ok($count, '>', 10, 'uma keg/zone count');
    is ($pad, 0, 'uma pad');
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
    my $sysctl_openfiles = BSD::Sysctl->new('kern.openfiles');
    my $nr_files = $sysctl_openfiles->get();
    cmp_ok($nr_files, '>', 0, "got the number of open files ($nr_files, in case you were wondering)");
    $nr_files = $sysctl_openfiles->get();
    cmp_ok($nr_files, '>', 0, "got the number of open files again (now $nr_files)");
}

is(scalar(keys %BSD::Sysctl::MIB_CACHE), 8, 'cached mib count')
    or do { diag("cached: [$_]") for sort keys %BSD::Sysctl::MIB_CACHE };
