#!/usr/bin/perl

package Regrid;

=pod

=head1 NAME

Regrid - Regrid gridded binary data to a 1/8th degree format required by grids-to-climdivs

=head1 SYNOPSIS

 use Regrid qw(regrid);
 
 my $binary_data_file    = "/some/path/to/data/file"
 my $grib2_template_file = "/some/path/to/grib2/template/file"
 my $output_file         = "/where/you/want/output/to/go"
 
 my $error = regrid($grib2_template_file,$binary_data_file,$output_file);

=head1 DESCRIPTION

The Regrid package is part of the grids-to-climdivs project. It provides the functionality to convert unformatted binary gridded data files to a special 1/8th degree grid used by the project to map gridpoints onto climate divisions.

=head1 REQUIREMENTS

=over 3

=item * L<wgrib2|https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/> must be installed on your system

=back

=head1 METHODS

Regrid.pm provides one method used to convert binary data to the format needed by grids-to-climdivs to produce climate divisions data.

=head2 regrid

 my $error = regrid($template,$input,$output,[$rpn]);

Given a grib2 "template" file (filename set to $template) with dimensions matching an unformatted binary data file (filename set to $input), writes unformatted binary data regridded to 1/8th degree lat/lon to the filename passed in as $output. If $output exists it will be overwritten.

The template, input, and output arguments are required. A fourth option, "rpn" can be supplied. The method uses wgrib2 to regrid the binary data, and wgrib2 can take a -rpn (reverse Polish notation) argument useful for things like unit conversions. The user can pass the reverse Polish notation conversion information via this argument.

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 03FEB2022

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
	$wgrib2 = `which wgrib2`; chomp $wgrib2;
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
	my $error        = system("$wgrib2 -d 1 $template -import_ieee $input -no_header -little_endian -undefine_val 9999. $rpn -set_date 19710101 -set_grib_type j -set_scaling -1 0 -grib_out $grib_orig_fn > /dev/null");
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

