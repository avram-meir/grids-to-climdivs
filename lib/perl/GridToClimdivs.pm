#!/usr/bin/perl

package GridToClimdivs;

=pod

=head1 NAME

GridToClimdivs - Converts 1/8th degree gridded data to the 344 U.S. climate divisions

=head1 SYNOPSIS

 use GridToClimdivs qw(get_climdivs);
 
 BEGIN { $GridToClimdivs::mapfile = "/path/to/mapfile"; }
 my $binary_data_file     = "/some/path/to/data/file";
 open($fh,'<',$binary_data_file);
 binmode($fh);
 my $data_str             = join('',<$fh>);
 my $climdivs             = get_climdivs(\$data_str);
 print "The value for the Northern Valley division in Alabama is: ".$climdivs->{101};

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
use Scalar::Util qw(looks_like_number);
use File::Basename qw(fileparse basename);
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(get_climdivs);

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

my $package = __FILE__;
my $mapfile = $package =~ s/\/lib\/perl\/GridToClimdivs.pm/\/lib\/map\/GridToClimdivs.map/r;
my @map;
if(-s $mapfile) { set_map($mapfile); }
else            { cluck "MAPFILE was not found where it was expected and must be set using GridToClimdivs::set_map(MAPFILE)"; }

sub set_map {
	confess "Argument required" unless(@_);
	my $mapfile = shift;

	# --- Load map information ---

	confess "Invalid mapfile" unless(-s $mapfile);
	open(MAP,'<',$mapfile) or confess "Could not open $mapfile for reading";
	{ my $header = <MAP>; }

	while(<MAP>) {
        	my $line = $_;
        	chomp $line;
        	my($lon,$lat,$stcd) = split(/\|/,$line);
        	push(@map,$stcd);
	}
	
	close(MAP);
}

sub get_climdivs {
	confess "Map not found - use set_map to load it into package data" unless(@map);
	confess "Argument required" unless(@_);
	my $data_ref = shift;

	# --- Load gridded data into array ---
	
	my @gridded_data = unpack('f*',$$data_ref);
	confess "Input data grid size does not match the supplied map" unless(scalar(@gridded_data) == scalar(@map));

	# --- Get area mean of gridpoints that fall within each division ---
	
	my($sums,$npts,$climdivs);

	foreach my $stcd (@stcd) {
		$sums->{$stcd}     = 0;
		$npts->{$stcd}     = 0;
		$climdivs->{$stcd} = -9999;
	}

	GRIDPOINT: for(my $i=0; $i<@map; $i++) {
		next GRIDPOINT unless(exists $sums->{$map[$i]});

		if(looks_like_number($gridded_data[$i]) and abs($gridded_data[$i] < 5000)) {
			$sums->{$map[$i]} = $sums->{$map[$i]} + $gridded_data[$i];
			$npts->{$map[$i]} = $npts->{$map[$i]} + 1;
		}

	} # :GRIDPOINT

	foreach my $stcd (keys %$npts) {
		if($npts->{$stcd} > 0) { $climdivs->{$stcd} = $sums->{$stcd} / $npts->{$stcd}; }
	}

	return $climdivs;
}

1;

