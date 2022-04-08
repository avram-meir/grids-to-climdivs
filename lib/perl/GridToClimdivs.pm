#!/usr/bin/perl

package GridToClimdivs;

=pod

=head1 NAME

GridToClimdivs - Converts gridded data to the 363 U.S. climate divisions

=head1 SYNOPSIS

 use GridToClimdivs;
 
 my $climdivs = GridToClimdivs->new();
 my $grid0.125deg         = "/path/to/binary/data";
 my $grid0.1667deg        = "/path/to/other/binary/data";
 open($fh1,'<',$grid0.125deg);
 binmode($fh1);
 my $conus_grid           = join('',<$fh1>);
 close($fh1);
 $climdivs->set_conus_data($conus_grid);
 open($fh2,'<',$grid0.1667deg);
 binmode($fh2);
 my $akhi_grid            = join('',<$fh2>);
 close($fh2);
 $climdivs->set_akhi_data($akhi_grid);
 my $climdivs_data        = $climdivs->get_data();
 print "The value for the NORTHERN VALLEY division in Alabama is: ".$climdivs->{"AL01"};

=head1 DESCRIPTION

=head1 REQUIREMENTS

=head1 METHODS

=head2 get_climdivs

=head1 AUTHOR

Adam Allgood

This documentation was last updated on: 03FEB2022

=cut

use strict;
use warnings;
use Carp qw(carp croak cluck confess);
use Scalar::Util qw(blessed looks_like_number);
use File::Basename qw(fileparse basename);

my $package   = __FILE__;
my $conus_map = $package =~ s/\/lib\/perl\/GridToClimdivs.pm/\/lib\/map\/GridToClimdivs_CONUS.map/r;
my $akhi_map  = $package =~ s/\/lib\/perl\/GridToClimdivs.pm/\/lib\/map\/GridToClimdivs_AK-HI.map/r;
my $climdivs  = $package =~ s/\/lib\/perl\/GridToClimdivs.pm/\/lib\/climdivs\/climdivs363.txt/r;
my(@conus_map,@akhi_map);
if(-s $conus_map) { @conus_map = _get_map($conus_map); }
else              { cluck "CONUS_MAP was not found";  }
if(-s $akhi_map)  { @akhi_map  = _get_map($akhi_map);  }
else              { cluck "AKHI_MAP was not found";   }
my $climdivs_order = {};
my $climdivs_names = {};
if(-s $climdivs)  { ($climdivs_order,$climdivs_names) = _get_climdivs($climdivs); }
else              { cluck "CLIMDIVS definitions not found"; }

sub _get_map {
	confess "Argument required" unless(@_);
	my $mapfile = shift;

	# --- Load map information ---

	confess "Invalid mapfile" unless(-s $mapfile);
	open(MAP,'<',$mapfile) or confess "Could not open $mapfile for reading";
	{ my $header = <MAP>; }
	my @map;

	while(<MAP>) {
        	my $line = $_;
        	chomp $line;
        	my($lon,$lat,$stcd) = split(/\|/,$line);
        	push(@map,$stcd);
	}
	
	close(MAP);
	return @map;
}

sub _get_climdivs {
	confess "Argument required" unless(@_);
	my $climdivs_file = shift;

	# --- Load climdivs information ---
	
	confess "Invalid climdivs file" unless(-s $climdivs_file);
	open(CLIMDIVS,'<',$climdivs_file) or confess "Could not open $climdivs_file for reading";
	my @climdivs = <CLIMDIVS>; chomp @climdivs;
	close(CLIMDIVS);
	my $order = {};
	my $names = {};

	foreach my $line (@climdivs) {
		my($num,$div,$name) = split(/\|/,$line);
		$order->{$num}      = $div;
		$names->{$div}      = $name;
	}

	return ($order,$names);
}

sub new {
	my $class             = shift;
	my $self              = {};
	$self->{MISSING}      = -9999.;  # Default value
	my $init_val          = undef;
	if(@_) { $init_val    = shift; }
	else   { $init_val    = $self->{MISSING}; }
	$self->{SANITY_LIMIT} = 999999999;

	foreach my $div (keys %$climdivs_names) {
		$self->{$div} = $init_val;
	}

	bless($self,$class);
	return $self;
}

sub set_missing {
	my $self        = shift;
	confess "Argument required" unless @_;
	my $missing_val = shift;

	foreach my $div (keys %$climdivs_names) {
		if($self->{$div} eq $self->{MISSING}) { $self->{$div} = $missing_val; }
	}

	$self->{MISSING} = $missing_val;
	return 0;
}

sub set_sanity_limit {
	my $self              = shift;
	confess "Argument required" unless @_;
	my $sanity_limit      = shift;
	carp "Sanity limit is not numeric" unless(looks_like_number($sanity_limit));
	$self->{SANITY_LIMIT} = $sanity_limit;
	return 0;
}

sub set_conus_data {
	my $self = shift;
	confess "CONUS map not found" unless(@conus_map);
	return &_set_data($self,\@conus_map,@_);
}

sub set_akhi_data {
	my $self = shift;
	confess "AK-HI map not found" unless(@akhi_map);
	return &_set_data($self,\@akhi_map,@_);
}

sub _set_data {
	my $self     = shift;
	my $map_ref  = shift;
	confess "Argument required" unless(@_);
	my $data_ref = shift;

	# --- Load gridded data and map into arrays ---

	my @gridded_data = unpack('f*',$$data_ref);
	my @map          = @$map_ref;
	confess "Input data grid size does not match the supplied map" unless(scalar(@gridded_data) == scalar(@map));

	# --- Get area mean of gridpoints that fall within each division ---

	my($sums,$npts);

	foreach my $div (keys %$climdivs_names) {
		$sums->{$div}     = 0;
		$npts->{$div}     = 0;
	}

	GRIDPOINT: for(my $i=0; $i<@map; $i++) {
		next GRIDPOINT unless(exists $sums->{$map[$i]});

		if(looks_like_number($gridded_data[$i]) and abs($gridded_data[$i] - $self->{MISSING}) > 0.001 and abs($gridded_data[$i]) < $self->{SANITY_LIMIT}) {
			$sums->{$map[$i]} = $sums->{$map[$i]} + $gridded_data[$i];
			$npts->{$map[$i]} = $npts->{$map[$i]} + 1;
		}

	} # :GRIDPOINT

	foreach my $div (keys %$climdivs_names) {
		if($npts->{$div} > 0) { $self->{$div} = $sums->{$div} / $npts->{$div}; }
	}

	return 0;
}

sub get_data {
	my $self     = shift;
	my $data_ref = {};

	foreach my $div (keys %$climdivs_names) {
		$data_ref->{$div} = $self->{$div};
	}

	return $data_ref;
}

sub get_names {
	my $self = shift;
	return $climdivs_names;
}

sub get_climdivs_list {
	my $self = shift;
	my @list;

	foreach my $num (sort {$a <=> $b} keys %$climdivs_order) {
		push(@list,$climdivs_order->{$num});
	}

	return @list;
}

1;

