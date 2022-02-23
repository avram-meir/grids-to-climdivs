#!/usr/bin/perl

=pod

=head1 NAME

create-products - Template perl script

=head1 SYNOPSIS

 create-products.pl [--d]
 create-products.pl -h
 create-products.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -date, -d           Date argument                                    YYYYMMDD
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation

=head1 DESCRIPTION

=head2 PURPOSE

=head2 REQUIREMENTS

=over 3

=item * Perl v5.10 or later

=item * Date::Manip installed from CPAN

=back

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 02FEB2022

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use Scalar::Util qw(blessed looks_like_number openhandle);
use Pod::Usage;
use Date::Manip;

# --- Identify script ---

my($script_name,$script_path,$script_suffix);
BEGIN { ($script_name,$script_path,$script_suffix) = fileparse($0, qr/\.[^.]*/); }

# --- Get the command-line options ---

my $date        = ParseDateString('today');  # Defaults to today's date if no -date option is supplied
my $help        = undef;
my $manual      = undef;

GetOptions(
	'date|d=s'       => \$date,
	'help|h'         => \$help,
	'manual|man'     => \$manual,
);

# --- Process options -help or -manual if invoked ---

if($help or $manual) {
	my $verbose = 0;
	if($manual) { $verbose = 2; }

	pod2usage( {
		-message => ' ',
		-exitval => 0,
		-verbose => $verbose,
	} );

}

# --- Validate date argument ---

my $day = ParseDateString($date);
unless($day) { die "Invalid -date argument $date - exiting"; }

# --- Do something cool ---

print "Hello, world!\n";

exit 0;

