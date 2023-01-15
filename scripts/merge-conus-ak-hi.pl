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

my($output_name,$output_path,$output_suffix) = fileparse($output_file, qr/\.[^.]*/); }
unless(-d $output_path) { mkpath($output_path) or die "Could not create directory $output_path - $! - exiting"; }

# --- Get input data ---





# --- Pull information from the configuration file ---

my $config = Config::Simple->new($config_file)->vars();

# --- List of allowed variables that can be in the config file ---

my %allowed_vars = (
        APP_PATH => "$script_path..",
        DATA_IN  => $ENV{DATA_IN},
        DATA_OUT => $ENV{DATA_OUT},
);

# --- Parse variables and date wildcards in the config file params ---

foreach my $param (keys %$config) {

	if(ref($config->{$param}) eq 'ARRAY') {

		for(my $i=0; $i<scalar(@{$config->{$param}}); $i++) {
			$config->{$param}[$i] = parse_param($config->{$param}[$i],$day);
		}

	}
	else {
		$config->{$param} = parse_param($config->{$param},$day);
	}

}

# --- QC the config file params ---

unless(-s $config->{'input.file'}) {
	die "The input.file ".$config->{'input.file'}." in $config_file does not exist - exiting";
}

unless($config->{'input.ngrids'} eq int($config->{'input.ngrids'}) and $config->{'input.ngrids'} > 0) {
	die "The input.ngrids param in $config_file is invalid - exiting";
}

# Bugfix - the code assumes that output.grids, output.files, and output.descriptions are 
# all array refs, but if ngrids=1 then these will be scalars. So let's just force them to 
# always be array refs.

$config->{'output.grids'}        = [ $config->{'output.grids'} ]        if ref($config->{'output.grids'}) ne 'ARRAY';
$config->{'output.files'}        = [ $config->{'output.files'} ]        if ref($config->{'output.files'}) ne 'ARRAY';
$config->{'output.descriptions'} = [ $config->{'output.descriptions'} ] if ref($config->{'output.descriptions'}) ne 'ARRAY';

unless(scalar(@{$config->{'output.grids'}}) <= $config->{'input.ngrids'}) {
    die "The number of items in output.grids exceeds the value of input.ngrids in $config_file - exiting";
}

unless(scalar(@{$config->{'output.grids'}}) == scalar(@{$config->{'output.files'}}) and scalar(@{$config->{'output.grids'}}) == scalar(@{$config->{'output.descriptions'}})) {
    die "The number of items in output.grids, output.files, and output.descriptions do not match in $config_file - exiting";
}

# --- Split the input file into ngrids pieces ---

# This is assumes the input file is pure unformatted binary so that it'll divide evenly into input_ngrids pieces

my $npieces     = $config->{'input.ngrids'};
my $binary_file = $config->{'input.file'};
my $split_dir   = File::Temp->newdir();

open(SPLIT, "split -n $npieces --verbose $binary_file $split_dir/input 2>&1 |") or die "Could not split $binary_file into $npieces pieces for processing - exiting";

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

# --- Loop through the input pieces and create climdivs data for the requested grids ---

my $counter  = 0;
my $work_dir = File::Temp->newdir();

foreach my $og (@{$config->{'output.grids'}}) {
	print "Converting grid $og of $npieces in $binary_file to climate divisions\n";

	my $input_fn   = $input_files[$og-1];
	my $conus_fh   = File::Temp->new(DIR => $work_dir);
	my $akhi_fh    = File::Temp->new(DIR => $work_dir);

	# --- Regrid the input data to match the CONUS map if needed ---
	
	my $conus_fn = $input_fn;

	if($config->{'input.rgconus'}) {
		$conus_fn = $conus_fh->filename;
		regrid($input_fn,$config,'CONUS',$conus_fn);
	}

	# --- Regrid the input data to match the AK-HI map if needed ---
	
	my $akhi_fn = $input_fn;

	if($config->{'input.rgakhi'}) {
		$akhi_fn = $akhi_fh->filename;
		regrid($input_fn,$config,'AK-HI',$akhi_fn);
	}

	# --- Get climate divisions data from the gridded data ---

	open(CONUS,'<',$conus_fn) or die "Could not open $conus_fn for reading - $! - exiting";
	binmode(CONUS);
	my $conus_grid = join('',<CONUS>);
	close(CONUS);
	open(AKHI,'<',$akhi_fn) or die "Could not open $akhi_fn for reading - $! - exiting";
	binmode(AKHI);
	my $akhi_grid  = join('',<AKHI>);
	close(AKHI);
	my $climdivs = GridToClimdivs->new();
	$climdivs->set_missing($config->{'input.missing'});
	$climdivs->set_conus_data(\$conus_grid);
	$climdivs->set_akhi_data(\$akhi_grid);
	my $climdivs_data = $climdivs->get_data();

	# --- Write climate divisions data to file ---
	
	my $output_file = "$output/".$config->{'output.files'}[$counter];
	my($output_name,$output_path,$output_suffix) = fileparse($output_file, qr/\.[^.]*/);
	unless(-d $output_path) { mkpath $output_path or die "Could not create directory $output_path - $! - exiting"; }
	open(OUTPUT,'>',$output_file) or die "Could not open $output_file for writing - $! - exiting";
	print OUTPUT join('|','STCD',$config->{'output.descriptions'}[$counter])."\n";
	my @stcd = $climdivs->get_climdivs_list();

	foreach my $stcd (@stcd) {
		my $value = $climdivs_data->{$stcd};
		if($config->{'output.rpn'}) { $value = rpn_calc(join(':',$value,$config->{'output.rpn'}),':'); }
		print OUTPUT join('|',$stcd,sprintf("%.3f",$value))."\n";
	}

	print "$output_file written!\n";
	$counter++;
}

# --- End of script ---

sub parse_param {
	my $param = shift;
	my $day   = shift;

	# --- List of allowed variables that can be in the config file ---

	my %allowed_vars = (
		APP_PATH => "$script_path..",
		DATA_IN  => $ENV{DATA_IN},
		DATA_OUT => $ENV{DATA_OUT},
	);

	my $param_parsed = $param;
	$param_parsed    =~ s/\$(\w+)/exists $allowed_vars{$1} ? $allowed_vars{$1} : 'illegal000BLORT000illegal'/eg;
	if($param_parsed =~ /illegal000BLORT000illegal/) { die "Illegal variable found in $param"; }
	return $day->printf($param_parsed);
}

exit 0;

