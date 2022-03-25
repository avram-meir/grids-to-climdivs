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

my @stcd = (101,102,103,104,105,106,107,108,201,202,203,204,205,206,207,301,302,303,304,305,306,307,308,309,401,402,403,404,405,406,407,
501,502,503,504,505,601,602,603,701,702,801,802,803,804,805,806,807,901,902,903,904,905,906,907,908,909,1001,1002,1003,1004,1005,1006,
1007,1008,1009,1010,1101,1102,1103,1104,1105,1106,1107,1108,1109,1201,1202,1203,1204,1205,1206,1207,1208,1209,1301,1302,1303,1304,1305,
1306,1307,1308,1309,1401,1402,1403,1404,1405,1406,1407,1408,1409,1501,1502,1503,1504,1601,1602,1603,1604,1605,1606,1607,1608,1609,1701,
1702,1703,1801,1802,1803,1804,1805,1806,1807,1808,1901,1902,1903,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2101,2102,2103,2104,
2105,2106,2107,2108,2109,2201,2202,2203,2204,2205,2206,2207,2208,2209,2210,2301,2302,2303,2304,2305,2306,2401,2402,2403,2404,2405,2406,
2407,2501,2502,2503,2505,2506,2507,2508,2509,2601,2602,2603,2604,2701,2702,2801,2802,2803,2901,2902,2903,2904,2905,2906,2907,2908,3001,
3002,3003,3004,3005,3006,3007,3008,3009,3010,3101,3102,3103,3104,3105,3106,3107,3108,3201,3202,3203,3204,3205,3206,3207,3208,3209,3301,
3302,3303,3304,3305,3306,3307,3308,3309,3310,3401,3402,3403,3404,3405,3406,3407,3408,3409,3501,3502,3503,3504,3505,3506,3507,3508,3509,
3601,3602,3603,3604,3605,3606,3607,3608,3609,3610,3701,3801,3802,3803,3804,3805,3806,3807,3901,3902,3903,3904,3905,3906,3907,3908,3909,
4001,4002,4003,4004,4101,4102,4103,4104,4105,4106,4107,4108,4109,4110,4201,4202,4203,4204,4205,4206,4207,4301,4302,4303,4401,4402,4403,
4404,4405,4406,4501,4502,4503,4504,4505,4506,4507,4508,4509,4510,4601,4602,4603,4604,4605,4606,4701,4702,4703,4704,4705,4706,4707,4708,
4709,4801,4802,4803,4804,4805,4806,4807,4808,4809,4810);

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

		if(looks_like_number($gridded_data[$i]) and abs($gridded_data[$i] < 5000)) {
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

	foreach my $div (sort {$a <=> $b} keys %$climdivs_order) {
		push(@list,$div);
	}

	return @list;
}

1;

