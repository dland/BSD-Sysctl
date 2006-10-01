# 01-basic.t
# Basic sanity checks for BSD::Sysctl
#
# Copyright (C) 2006 David Landgren

use strict;
use Test::More tests => 4;

my $fixed = 'The scalar remains the same';
$_ = $fixed;

BEGIN { use_ok('BSD::Sysctl', qw(sysctl sysctl_exists)); }

SKIP: {
	skip( 'Test::Pod not installed on this system', 1 )
		unless do {
			eval { require Test::Pod; import Test::Pod };
			$@ ? 0 : 1;
		};
	pod_file_ok( 'Sysctl.pm' );
};

SKIP: {
	skip( 'Test::Pod::Coverage not installed on this system', 1 )
		unless do {
			eval { require Test::Pod::Coverage; import Test::Pod::Coverage };
			$@ ? 0 : 1;
		};
	pod_coverage_ok( 'BSD::Sysctl', 'POD coverage is go' );
};

is($_, $fixed, '$_ has not been modified');
