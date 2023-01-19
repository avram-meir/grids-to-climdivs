#!/usr/bin/perl

=pod

=head1 NAME

merge-conus-ak-hi - Merge separate climdivs files that have CONUS, AK, and HI data

=head1 SYNOPSIS

 merge-conus-ak-hi.pl [-c|-a|-h|-o]
 merge-conus-ak-hi.pl -h
 merge-conus-ak-hi.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -alaska, -a         Climdivs file that contains Alaska data          filename
 -conus, -c          Climdivs file that includes CONUS data           filename
 -hawaii, -ha        Climdivs file that includes Hawaii data          filename


 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation
 -output, -o         Output filename for merged data                  filename

=head1 DESCRIPTION

=head2 PURPOSE

=head2 REQUIREMENTS

=over 3

=item * Perl v5.10 or later

=back

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 15JAN2023

=cut

use strict;
use warnings;
use Getopt::Long;


use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
require File::Temp;
use File::Temp ();
use File::Temp qw(:seekable);
use Scalar::Util qw(blessed looks_like_number openhandle reftype);
use Pod::Usage;
use Date::Manip;
use Config::Simple;
use utf8;

# --- Identify script ---

my($script_name,$script_path,$script_suffix);
BEGIN { ($script_name,$script_path,$script_suffix) = fileparse(__FILE__, qr/\.[^.]*/); }

# --- Get the command-line options ---

my $alaska_file = '';
my $conus_file  = '';
my $hawaii_file = '';
my $help        = undef;
my $manual      = undef;
my $output_file = '';

GetOptions(
    'alaska|a=s'     => \$alaska_file,
    'conus|c=s'      => \$conus_file,
    'hawaii|ha=s'    => \$hawaii_file,
    'help|h'         => \$help,
    'manual|man'     => \$manual,
    'output|o=s'     => \$output_file,
);

# --- Handle options -help or -manual ---

if($help or $manual) {
	my $verbose = 0;
	if($manual) { $verbose = 2; }

	pod2usage( {
		-message => ' ',
		-exitval => 0,
		-verbose => $verbose,
	} );

}

my $opts_failed = '';

# --- Validate i/o file args ---

unless($alaska_file)    { $opts_failed = join("\n",$opts_failed,'Option -alaska must be supplied'); }
unless(-s $alaska_file) { $opts_failed = join("\n",$opts_failed,'Option -alaska must be set to an existing file'); }

unless($conus_file)     { $opts_failed = join("\n",$opts_failed,'Option -conus must be supplied'); }
unless(-s $conus_file)  { $opts_failed = join("\n",$opts_failed,'Option -conus must be set to an existing file'); }

unless($hawaii_file)    { $opts_failed = join("\n",$opts_failed,'Option -hawaii must be supplied'); }
unless(-s $hawaii_file) { $opts_failed = join("\n",$opts_failed,'Option -hawaii must be set to an existing file'); }

unless($output_file)    { $opts_failed = join("\n",$opts_failed,'Option -output must be supplied'); }

# --- Handle failed options ---

if($opts_failed) {

	pod2usage( {
		-message => "$opts_failed\n",
		-exitval => 1,
		-verbose => 0,
	} );

}

# --- Create output directory if needed ---

my($output_name,$output_path,$output_suffix) = fileparse($output_file, qr/\.[^.]*/);
unless(-d $output_path) { mkpath($output_path) or die "Could not create directory $output_path - $! - exiting"; }

# --- Get climdivs ---

my $climdivs_file = $script_path."/../lib/climdivs/climdivs363.txt";
open(CLIMDIVS,'<',$climdivs_file) or die "Could not open $climdivs_file for readiing - $! - exiting";
my @climdivs_contents = <CLIMDIVS>; chomp @climdivs_contents;
close(CLIMDIVS);
my @climdivs;

foreach my $line (@climdivs_contents) {
    my($num,$climdiv,$name) = split(/\|/,$line);
    push(@climdivs,$climdiv);
}

# --- Get input data ---

open(ALASKA,'<',$alaska_file) or die "Could not open $alaska_file for reading - $! - exiting";
open(CONUS,'<',$conus_file)   or die "Could not open $conus_file for reading - $! - exiting";
open(HAWAII,'<',$hawaii_file) or die "Could not open $hawaii_file for reading - $! - exiting";

my @alaska_contents = <ALASKA>; chomp @alaska_contents;
close(ALASKA);
my @conus_contents  = <CONUS>;  chomp @conus_contents;
close(CONUS);
my @hawaii_contents = <HAWAII>; chomp @hawaii_contents;
close(HAWAII);

shift @alaska_contents;
my $header = shift @conus_contents;
shift @hawaii_contents;

my(%alaska,%conus,%hawaii);

foreach my $line (@alaska_contents) {
    my($cd,$val) = split(/\|/,$line);
    $alaska{$cd} = $val;
}

foreach my $line (@conus_contents) {
    my($cd,$val) = split(/\|/,$line);
    $conus{$cd} = $val;
}

foreach my $line (@hawaii_contents) {
    my($cd,$val) = split(/\|/,$line);
    $hawaii{$cd} = $val;
}

# --- Output merged climdivs data ---

open(OUTPUT,'>',$output_file) or die "Could not open $output_file for writing - $! - exiting";
print OUTPUT "$header\n";

foreach my $climdiv (@climdivs) {
    my $val = -999;

    if($climdiv =~ /AK/ and exists $alaska{$climdiv} and abs($alaska{$climdiv}) < 100000)    { $val = $alaska{$climdiv}; }
    elsif($climdiv =~ /HI/ and exists $hawaii{$climdiv} and abs($hawaii{$climdiv}) < 100000) { $val = $hawaii{$climdiv}; }
    elsif(exists $conus{$climdiv} and abs($conus{$climdiv}) < 100000) { $val = $conus{$climdiv}; }

    print OUTPUT join('|',$climdiv,$val)."\n";
}

close(OUTPUT);

print "\n$output_file written!\n";
exit 0;

