#!/usr/bin/perl

package Data::BinaryUtils;

=pod

=head1 NAME

Data::BinaryUtils - A set of utilities to help prepare gridded binary data for conversion to climate divisional data

=head1 SYNOPSIS

 use Data::BinaryUtils qw(flipbytes regrid)

=head1 DESCRIPTION

=head1 REQUIREMENTS

=head1 METHODS

=head2 flipbytes

=head2 regrid

=head1 AUTHOR

Adam Allgood

This documentation was last updated on:29MAR2022

=cut

use strict;
use warnings;
use Carp qw(carp cluck croak confess);
use Scalar::Util qw(looks_like_number reftype);
require File::Temp;
use File::Temp ();
use File::Temp qw(:seekable);
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(flipbytes regrid);

my $wgrib2;

BEGIN {
        $wgrib2 = `which wgrib2`; chomp $wgrib2;
        unless($wgrib2) { confess "Data::BinaryUtils requires wgrib2 to be installed on your system"; }
}

sub flipbytes {


}

sub regrid {
	confess "Three arguments required" unless(@_ >= 2);
	my $config = shift;
	my $map    = shift;
	my $output = shift;
	if(reftype($config)) { confess "Invalid config argument" unless reftype($config) eq 'HASH'; }
	else                 { confess "Invalid config argument"; }
	confess "Config argument is missing parameters" unless(exists $config->{"input.template"} and exists $config->{"input.file"} and exits $config->{"input.headers"} and exists $config->{"input.missing"} and exists $config->{"output.rpn"});
	my $template  = $config->{"input.template"};
	my $input     = $config->{"input.file"};
	my $header    = $config->{"input.headers"};
	my $missing   = $config->{"input.missing"};
	my $rpn       = $config->{"output.rpn"};
	confess "$template must be an existing file" unless(-s $template);
	confess "$input must be an existing file"    unless(-s $input);
	if($rpn) { $rpn = " -rpn \"$rpn\""; }
	else     { $rpn = "";               }
	confess "$map is invalid" unless($map eq 'CONUS' or $map eq 'AK-HI');

	# --- Import binary dataset into grib2 format ---
	
	my $work_dir  = File::Temp->newdir();
	my $grib_orig = File::Temp->new(DIR => $work_dir);
	my $grib_orig_fn = $grib_orig->filename;
	my $error        = system("$wgrib2 -d 1 $template -import_ieee $input -$header -$byteorder -undefine_val $missing$rpn -set_date 19710101 -set_grib_type j -set_scaling -1 0 -grib_out $grib_orig_fn > /dev/null");
	if($error) { confess "Could not import $input into grib2 format"; }

	# --- Regrid data to the map grid ---

	my $grib_rg      = File::Temp->new(DIR => $work_dir);
	my $grib_rg_fn   = $grib_rg->filename;

	if($map eq 'CONUS') {
		$error = system("$wgrib2 $grib_orig_fn -set_grib_type jpeg -new_grid_winds earth -new_grid latlon 230:601:0.125 20:241:0.125 $grib_rg_fn > /dev/null");
		if($error) { confess "Could not regrid grib2 version of $input"; }
	}
	else                {
		$error = system("$wgrib2 $grib_orig_fn -set_grib_type jpeg -new_grid_winds earth -new_grid latlon 0.083333:2160:0.166667 -89.916667:1080:0.166667 $grib_rg_fn > /dev/null");
		if($error) { confess "Could not regrid grib2 version of $input"; }
	}

	# --- Export regridded data into unformatted binary format ---

	$error = system("$wgrib2 $grib_rg_fn -no_header -bin $output > /dev/null");
	if($error) { confess "Could not create binary file $output"; }

	return 0;
}

1;

