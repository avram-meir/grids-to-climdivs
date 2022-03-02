#!/usr/bin/perl

=pod

=head1 NAME

update-dates - Update a list of dates based on an existing list, date arg, and scanning a period of dates prior to the date arg for the existence of grids-to-climdivs output files

=head1 SYNOPSIS

 update-dates.pl [-c|-d|-f|-p]
 update-dates.pl -h
 update-dates.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -config, -c         Configuration file containing information        filename
                     describing the grids-to-climdivs output 
                     filename
 -date, -d           Date argument                                    YYYYMMDD
 -help, -h           Print usage message and exit
 -file, -f           Filename containing list of dates. If none 
                     exists yet, one will be created
 -manual, -man       Display script documentation
 -output, -o         Output directory where the climate divisions 
                     data are located. Default location if none 
                     supplied is ../work
 -period, -p         Number of days prior to the date supplied by     Positive int
                     the -d argument to scan for missing 
                     grids-to-climdivs output files

=head1 DESCRIPTION

=head2 PURPOSE

=head2 REQUIREMENTS

=over 3

=item * Perl v5.10 or later

=item * Date::Manip installed from CPAN

=back

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 28FEB2022

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
use Scalar::Util qw(blessed looks_like_number openhandle);
use List::MoreUtils qw(uniq);
use Pod::Usage;
use Date::Manip;
use Config::Simple;

# --- Identify script ---

my($script_name,$script_path,$script_suffix);
BEGIN { ($script_name,$script_path,$script_suffix) = fileparse(__FILE__, qr/\.[^.]*/); }

# --- Get the command-line options ---

my $config      = '';
my $date        = ParseDateString('today');            # Defaults to today's date if no -date option is supplied
my $file        = "$script_path../output/dates.list";  # Defaults to this file if no -file option is supplied
my $help        = undef;
my $manual      = undef;
my $output      = "$script_path../output";             # Defaults to this directory if no -output option is supplied
my $period      = 30;                                  # Defaults to 30 days if no -period option is supplied

GetOptions(
	'config|c=s'     => \$config,
	'date|d=s'       => \$date,
	'file|f=s'       => \$file,
	'help|h'         => \$help,
	'manual|man'     => \$manual,
	'output|o=s'     => \$output,
	'period|p=i'     => \$period,
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

my $opts_failed = '';

# --- Validate config argument ---

unless($config)    { $opts_failed = join("\n",$opts_failed,'Option -config must be supplied'); }
unless(-s $config) { $opts_failed = join("\n",$opts_failed,'Option -config must be set to an existing file'); }

# --- Validate date argument ---

my $day = Date::Manip::Date->new();
my $err = $day->parse($date);
if($err) { $opts_failed = join("\n",$opts_failed,"Invalid -date argument: $date"); }

# --- Validate output argument ---

#unless(-d $output) { $opts_failed = join("\n",$opts_failed,"Invalid -output argument: $output - must be a directory"); }

# --- Process failed options ---

if($opts_failed) {

	pod2usage( {
		-message => "$opts_failed\n",
		-exitval => 1,
		-verbose => 0,
	} );

}

# --- Create a date list and add the date argument to it ---

my @dates;
push(@dates,$day->printf("%Y%m%d"));

# --- Load dates already stored in file if it exists ---

if(-s $file) {
	open(FILE,'<',$file) or die "Could not open $file for reading - $! - exiting";
	my @contents = <FILE>; chomp(@contents);
	close(FILE);

	foreach my $line (@contents) {
		my $fday = Date::Manip::Date->new();
		my $err  = $fday->parse($line);
		if($err) { warn "Skipping invalid date in $file : $line"; }
		else     { push(@dates,$fday->printf("%Y%m%d")); }
	}

}

# --- Get the output archive details from the config file ---

my $config_params = Config::Simple->new($config);
my @output_files  = $config_params->param("output.files");

my %allowed_vars = (
        APP_PATH => "$script_path..",
        DATA_IN  => $ENV{DATA_IN},
        DATA_OUT => $ENV{DATA_OUT},
);

my $output_files = join(',',@output_files);
$output_files    =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;
if($output_files =~ /illegal000BLORT000illegal/) { die "Illegal variable(s) found in $config - exiting"; }
@output_files = split(',',$output_files);

# --- Loop the dates in the period and search for missing/empty files ---

for(my $d=1; $d<=$period; $d++) {
	my $delta       = $day->new_delta();
	$delta->parse("$d days ago");
	my $archive_day = $day->calc($delta);

	# --- Loop output files in the archive and add date to list if any are missing ---
	
	foreach my $output_file (@output_files) {
		$output_file = $archive_day->printf($output_file);
		unless(-s "$output/$output_file") { push(@dates,$archive_day->printf("%Y%m%d")); }
	}

}

# --- Cull duplicate dates from the list and sort dates ---

@dates = uniq(@dates);
@dates = sort {$a <=> $b} @dates;

# --- Print new date list to file ---

open(FILE,'>',$file) or die "Could not open $file for writing - $! - exiting";
foreach my $date (@dates) { print FILE "$date\n"; }
close(FILE);

exit 0;

