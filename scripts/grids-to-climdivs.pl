#!/usr/bin/perl

=pod

=head1 NAME

grids-to-climdivs - Create climate divisions data from gridded data and write to a directory

=head1 SYNOPSIS

 grids-to-climdivs.pl [-c|-d|-o]
 grids-to-climdivs.pl -h
 grids-to-climdivs.pl -man

 [OPTION]            [DESCRIPTION]                                    [VALUES]

 -config, -c         Configuration file containing information        filename
                     describing the input dataset and output 
                     filename
 -date, -d           Date argument                                    YYYYMMDD
 -help, -h           Print usage message and exit
 -manual, -man       Display script documentation
 -output, -o         Output directory where the climate divisions 
                     data will be written. Default location if none 
                     supplied is ../work

=head1 DESCRIPTION

=head2 PURPOSE

=head2 REQUIREMENTS

=over 3

=item * Perl v5.10 or later

=item * Date::Manip installed from CPAN

=back

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 23FEB2022

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
use Config::Simple;

# --- Identify script ---

my($script_name,$script_path,$script_suffix);
BEGIN { ($script_name,$script_path,$script_suffix) = fileparse(__FILE__, qr/\.[^.]*/); }

# --- Application library packages ---

use lib "$script_path../lib/perl";
use Regrid qw(regrid);
use GridToClimdivs qw(get_climdivs);

# --- Get the command-line options ---

my $config      = '';
my $date        = ParseDateString('today');  # Defaults to today's date if no -date option is supplied
my $help        = undef;
my $manual      = undef;
my $output      = "$script_path../output";   # Defaults to this directory if no -output option is supplied

GetOptions(
	'config|c=s'     => \$config,
	'date|d=s'       => \$date,
	'help|h'         => \$help,
	'manual|man'     => \$manual,
	'output|o=s'     => \$output,
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

# --- Process failed options ---

if($opts_failed) {

	pod2usage( {
		-message => "$opts_failed\n",
		-exitval => 1,
		-verbose => 0,
	} );

}

print $day->printf("The date argument is %Y %m %d")."\n";

# --- Pull information from the configuration file ---

my $config_params  = Config::Simple->new($config);
my $input_file     = $config_params->param("input.file");
my $input_template = $config_params->param("input.template");
my $output_file    = $config_params->param("output.file");

# --- List of allowed variables in the config file ---

my %allowed_vars = (
	APP_PATH => "$script_path..",
	DATA_IN  => $ENV{DATA_IN},
	DATA_OUT => $ENV{DATA_OUT},
);

# --- Parse any allowed variables in the config file params ---

$input_file     =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;
$input_template =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;
$output_file    =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;

if($input_file =~ /illegal000BLORT000illegal/ or $input_template =~ /illegal000BLORT000illegal/ or $output_file =~ /illegal000BLORT000illegal/) {
	die "Illegal variable(s) found in $config - exiting";
}

# --- Parse any date info in the config file params ---

$input_file        = $day->printf($input_file);
$input_template    = $day->printf($input_template);
$output_file       = $day->printf($output_file);

print "\n";
print "Input file:     $input_file\n";
print "Input template: $input_template\n";
print "Output file:    $output_file\n";

# --- Do something cool ---

print "Hello, world!\n";

exit 0;

