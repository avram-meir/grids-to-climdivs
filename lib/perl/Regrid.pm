#!/usr/bin/perl

package Regrid;

=pod


=cut

use strict;
use warnings;
use Carp;
require File::Temp;
use File::Temp ();
use File::Temp qw/ :seekable /;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(regrid);

my $wgrib2;

BEGIN {
	$wgrib2 = `which wgrib2`;
	unless($wgrib2) { confess "Package wgrib2 must be installed on your system"; }
}

sub regrid {
	confess "Minimum of 3 arguments are required (template, input, output)" unless(@_ >= 3);
	my $template  = shift;
	my $input     = shift;
	my $output    = shift;
	my $rpn       = undef;
	if(@_) { $rpn = shift; }

	confess "$template is not a valid file" unless(-s $template);
	confess "$input is not a valid file"    unless(-s $input);

	if($rpn) { $rpn = " -rpn \"$rpn\""; }
	else     { $rpn = "";               }

	my $work_dir = File::Temp->newdir();

	# --- Import binary dataset into grib2 format ---
	
	my $grib_orig    = File::Temp->new(DIR => $work_dir);
	my $grib_orig_fn = $grib_orig->filename;
	my $error        = system("$wgrib2 -d 1 $template -import_ieee $input -undefine_val 9999. $rpn -set_date 19710101 -set_grid_type j -set_scaling -1 0 -grib_out $grib_orig_fn > /dev/null");
	if($error) { confess "Could not import $input into grib2 format"; }

	# --- Regrid datavto 1/8th degree grid ---
	
	my $grib_rg      = File::Temp->new(DIR => $work_dir);
	my $grib_rg_fn   = $grib_rg->filename;
	$error = system("$wgrib2 $grib_orig_fn -set_grib_type jpeg -new_grid_winds earth -new_grid latlon 230:601:0.125 20:241:0.125 $grib_rg_fn > /dev/null");
	if($error) { confess "Could not regrid grib2 version of $input"; }

	# --- Export regridded data into unformatted binary format ---
	
	$error = system("$wgrib2 $grib_rg_fn -no_header -bin $output > /dev/null");
	if($error) { confess "Could not create binary file $output"; }

	return 0;
}

1;

