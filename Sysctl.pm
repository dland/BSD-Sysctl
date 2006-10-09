# BSD::Sysctl.pm - Access BSD sysctl(8) information directly
#
# Copyright (C) 2006 David Landgren, all rights reserved.

package BSD::Sysctl;

use strict;
use warnings;

use Exporter;
use XSLoader;

use vars qw($VERSION @ISA %MIB_CACHE %MIB_SKIP @EXPORT_OK);

$VERSION = '0.05';
@ISA     = qw(Exporter);

use constant FMT_A           =>  1;
use constant FMT_INT         =>  2;
use constant FMT_UINT        =>  3;
use constant FMT_LONG        =>  4;
use constant FMT_ULONG       =>  5;
use constant FMT_N           =>  6;
use constant FMT_BOOTINFO    =>  7;
use constant FMT_CLOCKINFO   =>  8;
use constant FMT_DEVSTAT     =>  9;
use constant FMT_ICMPSTAT    => 10;
use constant FMT_IGMPSTAT    => 11;
use constant FMT_IPSTAT      => 12;
use constant FMT_LOADAVG     => 13;
use constant FMT_MBSTAT      => 14;
use constant FMT_NFSRVSTATS  => 15;
use constant FMT_NFSSTATS    => 16;
use constant FMT_NTPTIMEVAL  => 17;
use constant FMT_RIP6STAT    => 18;
use constant FMT_TCPSTAT     => 19;
use constant FMT_TIMEVAL     => 20;
use constant FMT_UDPSTAT     => 21;
use constant FMT_VMTOTAL     => 22;
use constant FMT_XINPCB      => 23;
use constant FMT_XVFSCONF    => 24;
use constant FMT_STRUCT_CDEV => 25;

push @EXPORT_OK, 'sysctl';
sub sysctl {
    my $mib = shift;
    return undef unless exists $MIB_CACHE{$mib} or _mib_info($mib);
    return _mib_lookup($mib);
}

push @EXPORT_OK, 'sysctl_set';
sub sysctl_set {
    my $mib = shift;
    return undef unless exists $MIB_CACHE{$mib} or _mib_info($mib);
    return _mib_set($mib, $_[0]);
}

push @EXPORT_OK, 'sysctl_exists';
sub sysctl_exists {
    return _mib_exists($_[0]);
}

push @EXPORT_OK, 'sysctl_description';
sub sysctl_description {
    return _mib_description($_[0]);
}

sub new {
    my $class = shift;
    my $name  = shift;
    return undef unless exists $MIB_CACHE{$name} or _mib_info($name);
    return bless \$name, $class;
}

sub get {
    my $self = shift;
    return _mib_lookup($$self);
}

sub set {
    my $self = shift;
    return _mib_set($$self, @_);
}

XSLoader::load 'BSD::Sysctl', $VERSION;

=head1 NAME

BSD::Sysctl - Manipulate kernel sysctl variables on BSD-like systems

=head1 VERSION

This document describes version 0.05 of BSD::Sysctl, released
2006-10-09.

=head1 SYNOPSIS

  use BSD::Sysctl 'sysctl';

  # exact values will vary
  print sysctl('kern.lastpid'); # 20621

  my $loadavg = sysctl('vm.loadavg');
  print $loadavg->[1]; # 0.1279 (5 minute load average)

  my $vm = sysctl('vm.vmtotal');
  print "number of free pages: $vm->{pagefree}\n";

=head1 DESCRIPTION

C<BSD::Sysctl> offers a native Perl interface for fetching sysctl
values that describe the kernel state of BSD-like operating systems.
This is around 80 times faster than scraping the output of the
C<sysctl(8)> program.

This module handles the conversion of symbolic sysctl variable names
to the internal numeric format, and this information, along with
the details of how to format the results, are cached. Hence, the
first call to C<sysctl> requires three system calls, however,
subsequent calls require only one call.

=head1 ROUTINES

=over 4

=item sysctl

Perform a sysctl system call. Takes the symbolic name of a sysctl
variable name, for instance C<kern.maxfilesperproc>, C<net.inet.ip.ttl>.
In most circumstances, a scalar is returned (in the event that the
variable has a single value).

In some circumstances a reference to an array is returned, when the
variable represents a list of values (for instance, C<kern.cp_time>).

In other circumstances, a reference to a hash is returned, when the
variable represents a heterogeneous collection of values (for
instance, C<kern.clockrate>, C<vm.vmtotal>). In these cases, the
hash key names are reasonably self-explanatory, however, passing
familiarity with kernel data structures is expected.

A certain number of opaque variables are fully decoded (and the
results are returned as hashes), whereas the C<sysctl> binary renders
them as a raw hexdump (for example, C<net.inet.tcp.stats>).

=item sysctl_set

Perform a system call to set a sysctl variable to a new value.

  if( !sysctl_set( 'net.inet.udp.blackhole', 1 )) {
     warn "That didn't work: $!\n";
  }

Note: you must have C<root> privileges to perform this, otherwise
your request will be politely ignored.

=item sysctl_description

Returns the description of the variable, instead of the contents
of the variable. The information is only as good as the developers
provide, and everyone knows that developers hate writing documentation.

  my $mib = 'kern.ipc.somaxconn';
  print "$mib is ", sysctl_description($mib), $/;
  # prints the following:
  # kern.ipc.somaxconn is Maximum pending socket connection queue size

=item sysctl_exists

Check whether the variable name exists. Returns true or false
depending on whether the name is recognised by the system.

Checking whether a variable exists does not perform the conversion
to the numeric OID (and the attendant caching).

=back

=head1 METHODS

An object-oriented interface is also available. This allows you
to set up an object that stores the name of a C<sysctl> variable,
and then you can retrieve its value as often as needed.

  my $lastpid = BSD::Sysctl->new( 'kern.lastpid' );
  while (1) {
    print $lastpid->get(), $/;
    sleep 1;
  }

This is handy when you want to monitor a number of variables. Just
store the objects in an array and loop over them:

  my @var;
  for my $v (@ARGV) {
    push @var, BSD::Sysctl->new($v);
  }
  print join(' ', map {"$$_:" . $_->get} @var), $/;

Note: the internal implementation uses a blessed scalar. Thus, you
may recover the name of the variable by dereferencing the object
itself.

=over 8

=item new

Create a new BSD::Sysctl object. Takes the name of the C<sysctl>
variable to examine.

=item get

Returns the current value of the C<sysctl> variable.

  my $value = $variable->get();

=item set

Set the value of the C<sysctl> variable. Returns true on success,
C<undef> on failure.

  $variable->set(99);

=back

=head1 NOTES

Note: this is a beta release.

Yes, you could manipulate C<sysctl> variables directly from Perl
using the C<syscall> routine, however, you would have to have to
jump through various arduous hoops, such as performing the
string-E<gt>numeric OID mapping yourself, packing arrays of C<int>s
and generally getting the argument lists right. That would be a
considerable amount of hassle, and prone to error. This module makes
it easy.

No distinction between ordinary and opaque variables is made on
FreeBSD. If you ask for a variable, you get it (for instance,
C<kern.geom.confxml>). This is good.

When setting a variable to an integer value, the value is passed
to the C routine as is, which calls C<strtol> (or C<strtoul>) to
perform the conversion. The C routine checks to see whether the
conversion succeeds.

The alternative would have been to let Perl handle the conversion.
The problem with this is that Perl tries to do the right thing and
returns 0 in the event of an invalid conversion, and setting many
C<sysctl> variables to 0 could bring down a system (for instance,
maximum number of open files per process). This design makes the
module handle bad data more gracefully.

=head1 DIAGNOSTICS

  "invalid integer: '...'"

A variable was set via C<sysctl_set>, and the variable required an
integer value, however, the program was not able to convert the
input into anything that resembled an integer. Solution: check your
input.

Similar warnings occur with unigned ints, longs and unsigned longs.
In all cases, the variable retains its initial value.

  "uncached mib: [sysctl name]"

A sysctl variable name was passed to the internal function
C<_mib_lookup>, but C<_mib_lookup> doesn't now how to deal with it,
since C<_mib_info> has not been called for this variable name. This
is normally impossible if you stick to the public functions.

  "get sysctl [sysctl name] failed"

The kernel system call to get the value associated with a sysctl
variable failed. If C<sysctl ...> from the command line succeeds
(that is, using the C<sysctl(8)> program), this is a bug that should
be reported.

  "[sysctl name] unhandled format type=[number]"

The sysctl call returned a variable that we don't know how to format,
at least for the time being. This is a bug that should be reported.

=head1 LIMITATIONS

At the current time, only FreeBSD versions 4.x through 6.x are
supported.

I am looking for volunteers to help port this module to NetBSD and
OpenBSD (or access to such machines), and possibly even Solaris.
If you are interested in helping, please consult the README file
for more information.

=head1 BUGS

This is my first XS module. I may be doing wild and dangerous things
and not realise it. Gentle nudges in the right direction will be
gratefully received.

Some sysctl values are 64-bit quantities. I am not all sure that
these are handled correctly.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BSD-Sysctl|rt.cpan.org>.

A short snippet demonstrating the problem, along with the expected
and actual output, and the version of BSD::Sysctl used, will be
appreciated.

=head1 SEE ALSO

L<BSD::Resource> - process resource limit and priority functions.

L<IO::KQueue> - monitor changes on sockets, files, processes and signals.

=head1 ACKNOWLEDGEMENTS

Douglas Steinwand added support for the amd64 platform in release
0.04.

=head1 AUTHOR

David Landgren.

Copyright (C) 2006, all rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
