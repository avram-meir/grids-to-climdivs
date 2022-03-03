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
require File::Temp;
use File::Temp ();
use File::Temp qw(:seekable);
use Scalar::Util qw(blessed looks_like_number openhandle);
use Pod::Usage;
use Date::Manip;
use Config::Simple;
use utf8;

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

print "Running grids-to-climdivs for ".$day->printf("%Y%m%d")." and $config\n";

# --- Process failed options ---

if($opts_failed) {

	pod2usage( {
		-message => "$opts_failed\n",
		-exitval => 1,
		-verbose => 0,
	} );

}

# --- Create output directory if needed ---

unless(-d $output) { mkpath($output) or die "Could not create directory $output - exiting"; }

# --- Pull information from the configuration file ---

my $config_params  = Config::Simple->new($config);
my $input_file     = $config_params->param("input.file");
my $input_template = $config_params->param("input.template");
my $input_endian   = lc($config_params->param("input.byteorder"));
my $input_missing  = $config_params->param("input.missing");
my $input_headers  = $config_params->param("input.headers");
my $input_rpn      = $config_params->param("input.rpn");
my $input_regrid   = $config_params->param("input.regrid");
my $input_ngrids   = $config_params->param("input.ngrids");
my @output_grids   = $config_params->param("output.grids");
my @output_files   = $config_params->param("output.files");
my @output_descs   = $config_params->param("output.descriptions");

# --- List of allowed variables that can be in the config file ---

my %allowed_vars = (
	APP_PATH => "$script_path..",
	DATA_IN  => $ENV{DATA_IN},
	DATA_OUT => $ENV{DATA_OUT},
);

# --- Parse allowed variables and date wildcards in the config file params ---

my $output_grids = join(',',@output_grids);
my $output_files = join(',',@output_files);
my $output_descs = join(',',@output_descs);

foreach ($input_file,$input_template,$input_regrid,$input_ngrids,$output_grids,$output_files,$output_descs) {
	$_     =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;
	if($_  =~ /illegal000BLORT000illegal/) { die "Illegal variable(s) found in $config - exiting"; }
	$_     = $day->printf($_);
}

@output_grids = split(',',$output_grids);
@output_files = split(',',$output_files);
@output_descs = split(',',$output_descs);

# --- Parse list params and perform sanity checks ---

unless($input_ngrids eq int($input_ngrids) and $input_ngrids > 0) { die "Invalid input::ngrids param in $config - exiting"; }
unless(scalar(@output_grids) <= $input_ngrids) { die "The param output::grids must be less than or equal to input::ngrids - exiting"; }
unless(scalar(@output_grids) == scalar(@output_files) and scalar(@output_grids) == scalar(@output_descs)) { die "The number of elements in output::grids, output::files and output::descriptions must match - exiting"; }
unless($input_endian eq 'big_endian' or $input_endian eq 'little_endian') { die "The param input::byteorder is invalid - exiting"; }
my $headers = 'no_header';
if($input_headers) { $headers = 'header'; }

# --- Check that input file exists ---

unless(-s $input_file) { die "Binary input file $input_file not found - exiting"; }

# --- Split the input file into ngrids pieces ---

# This is assumes the input file is pure unformatted binary so that it'll divide evenly into input_ngrids pieces

my $split_dir = File::Temp->newdir();

open(SPLIT, "split -n $input_ngrids --verbose $input_file $split_dir/input 2>&1 |") or die "Could not split $input_file into separate grids - $! - exiting";

my @input_files;

while (<SPLIT>) {
	if ( /^creating file (.*)$/ ) {
		my $split_file = $1;
		$split_file    =~ s/[\p{Pi}\p{Pf}'"]//g;  # Remove every type of quotation mark
		$split_file    =~ s/[^[:ascii:]]//g;      # Remove non-ascii characters
		push(@input_files, $split_file);
	}
	else {
		warn "Warning: this output line from split was not parsed: $_";
	}
}

close(SPLIT);

# --- Loop through the desired output grids ---

my $counter = 0;

foreach my $output_grid (@output_grids) {
	print "Converting grid $output_grid of $input_ngrids to climate divisions\n";

	my $input_fn   = $input_files[$output_grid-1];

	# --- Regrid the input data to 1/8th degree matching the grid-to-climdiv map ---

	my $regrid_dir = File::Temp->newdir();
	my $regrid_fh  = File::Temp->new(DIR => $regrid_dir);
	my $regrid_fn  = $regrid_fh->filename;

	if($input_regrid) {
		regrid($input_template,$input_fn,$headers,$input_endian,$input_missing,$regrid_fn,$input_rpn);
		$input_fn = $regrid_fn;
	}

	# --- Convert the gridded data to the climate divisions ---

	open(GRID,'<',$input_fn) or die "Could not open binary data file $input_fn - exiting";
	binmode(GRID);
	my $grid = join('',<GRID>);
	close(GRID);

	my $climdivs = get_climdivs(\$grid);

	# --- Write climate divisions data to file ---
	
	my $output_file = "$output/".$output_files[$counter];
	my($output_name,$output_path,$output_suffix) = fileparse($output_file, qr/\.[^.]*/);
	unless(-d $output_path) { mkpath $output_path or die "Could not create directory $output_path - $! - exiting"; }
	open(OUTPUT,'>',$output_file) or die "Could not open file in $output_file for writing - exiting";
	print OUTPUT join('|','STCD',$output_descs[$counter])."\n";
	my @divs = sort { $a <=> $b } keys %{$climdivs};
	foreach my $div (@divs) { print OUTPUT join('|',$div,sprintf("%.3f",$climdivs->{$div}))."\n"; }

	print "$output_file written!\n";
	$counter++;
}

exit 0;

