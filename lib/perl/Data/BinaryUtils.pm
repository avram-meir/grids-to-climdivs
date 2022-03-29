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


}

1;

