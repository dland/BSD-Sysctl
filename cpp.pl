if (/^#include (.+)$/) {
	open FILE, $1  or die "open $!";
	while (<FILE>) { print; };
	close FILE;
	next;
};
