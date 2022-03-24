# grids-to-climdivs

Create 344 climate divisions data for the contiguous United States using gridded input datasets.

<img src="https://user-images.githubusercontent.com/94878449/156598379-08ecd22f-8ead-471b-8332-e132c8650a96.png" align="center" width="500">

## About

Some of the longest record climate datasets for the contiguous United States utilize the [344 climate divisions](https://www.ncdc.noaa.gov/monitoring-references/maps/conus-climate-divisions) as their geographical reference. Example products include:

* [National Temperature and Precipitation Maps](https://www.ncei.noaa.gov/access/monitoring/us-maps/)
* [CPC Degree Days Statistics](https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/degree_days/)
* [CPC Palmer Drought Index](https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/palmer_drought/)
* [Historical Palmer Drought Indices (NCEI)](https://www.ncdc.noaa.gov/temp-and-precip/drought/historical-palmers/)

Traditionally, climate divisional data were estimated by using a weighted average of data from nearby stations; however, with the proliferation of high quality and high resolution gridded observational data now available, we can improve the quality of the climate divisions data by computing them from these gridded products. This software application provides a technique to compute degree days data from gridded products via the following steps:

1. Regrid the gridded input data to 0.125 degree (1/8th) resolution and perform unit conversions as needed
2. Match the resulting 0.125 degree grid to a map of the same dimensions defining which gridpoints fall into which climate division
3. Take the straight average of the gridpoints falling within a divion to calculate that division's value
4. Write the climate divisonal data to a pipe-delimited text file

### Built With

* [Bash](https://www.gnu.org/software/bash/)
* [Perl5](https://www.perl.org/)
* [wgrib2](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/)

## Getting Started

### Prerequisites

The grids-to-climdivs application relies on other software that needs to be installed on your system.

#### Install CPAN Modules

See [Installing Perl Modules](http://www.cpan.org/modules/INSTALL.html) for more information about installing packages from CPAN.

* [Date::Manip](https://metacpan.org/pod/Date::Manip)
* [Config::Simple](https://metacpan.org/pod/Config::Simple)
* [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

#### Install wgrib2

The wgrib2 utility must be compiled and installed on your system. Detailed instructions can be found here: [wgrib2 compile questions](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/compile_questions.html). There are some available pre-compiled versions of wgrib2, but only for specific systems, and YMMV.

Precompiled wgrib2 binaries for download can (possibly) be found on these sites:

* [OpenGrads: Darwin, Freebsd, Linux, Windows(cygwin)](https://opengrads.org/)
* [Fedora Project](https://fedoraproject.org)
* [RPMs: Centros, Fedora, OpenSUSE, RedHat, SUSE](https://download.opensuse.org/repositories/home:/gbvalor/)
* [MacPorts](https://trac.macports.org/browser/trunk/dports/science/wgrib2/Portfile)

### Install grids-to-climdivs

1. Clone the repo:
  ```git clone git@github.com:avram-meir/grids-to-climdivs.git```
2. Complete the installation using [GNU Make](https://www.gnu.org/software/make/):
  ```
  cd grids-to-climdivs
  make install
  ```

## Usage

### Configuration files

To define the gridded input files and compute climate divisions output files from those data, grids-to-climdivs uses configuration files in ["INI" format](https://metacpan.org/pod/Config::Simple#INI-FILE) that hold all of the needed information. A [sample configuration file](config/config.example) is provided that can be used as a starting point to create new configuration files for your input data. The sample config file works with a sample gridded data file provided in the same directory, which is useful for testing the software functionality on your system. This is the sample configuration file:

```
; Sample configuration file for scripts/grids-to-climdivs.pl
; Works with the provided sample data file config/sample.grid

[input]
file=$APP_PATH/config/sample.grid
ngrids=6
regrid=1
template=$APP_PATH/lib/grib2/global-6th-degree.template.grb
byteorder=little_endian
missing=-999.
headers=0
rpn=9:*:5:/:32:+

[output]
grids=1,3,5
files=sample.tmax.climdivs,sample.tmin.climdivs,sample.tave.climdivs
descriptions=TMAX,TMIN,TAVE
```

A description of each of these parameters follows.

#### Input

`file` This is the full path and name of the gridded input data file to use. Date information included in the path can be specified using [Linux date wildcards](https://man7.org/linux/man-pages/man1/date.1.html). For example, to specify year, month, and day directories, use `%Y/%m/%d`. The actual date to use is set by the script [grids-to-climdivs.pl](scripts/grids-to-climdivs.pl) using the `--date` option. Additionally, three variables can optionally be used as a part of the value:

* `$DATA_IN` - if your input data is located in some centralized data storage mount or directory, you can `export DATA_IN=/path/to/storage` to make things easier
* `$DATA_OUT` - useful for defining a location where your own output data are written to, e.g., `export DATA_OUT=${HOME}/data`
* `$APP_PATH` - not an environment variable, this will be set to the path where this software is installed by grids-to-climdivs.pl

`ngrids` Many gridded binary data files have more than one grid stored in them. Specify the number of grids using this parameter. The grids-to-climdivs.pl script will split the input data file into `ngrids` pieces and can then compute climate divisional values for each grid separately. Which grids to output can be defined by the `grids` options below.

`regrid` If your gridded dataset does not match the exact dimensions of [the 0.125 degree/climate divisions map](lib/map/GridToClimdivs.map), then set this value to 1, because the data must be regridded to match the map. This regridding is done by the wgrib2 software by converting the grids into grib2 format, performing the regrid, and then writing out the regridded data to a temporary output file read by grids-to-climdivs.pl. If your data are already 0.125 degree and match the map dimensions, this parameter can be set to 0.

The following five parameters provide information used by wgrib to regrid the input data. Therefore, if `regrid=0`, they are not necessary.

`template` Path to a grib2 file with grid spatial dimensions that match your input dataset. The data in this file do not matter as it is simply used as a template by wgrib2 to translate the binary input data into grib2 format.

`byteorder` Set to `big-endian` or `little-endian` depending on the byte order of the input dataset. See [this Wikipedia article](https://en.wikipedia.org/wiki/Endianness) for more information.

`missing` Use this parameter to set what the missing value is in your dataset.

`headers` Binary data created by Fortran sometimes include headers that define the chunk size of the binary data. These headers take up one byte at the beginning of the record, and one at the end. If these headers are present, set this value to 1. If the input data are purely unformatted binary, set this value to 0.

`rpn` Optionally provide a unit conversion for the gridded data, as wgrib2 can do this quickly. An example is converting degrees Celsius to degrees Fahrenheit: `rpn=9:*:5:/:32:+`. See [wgrib -rpn](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/rpn.html) for more information.

#### Output

`grids` Given `ngrids` defined above, specify which of these grid(s) you want to create climate divisions data for. For example, if your input data file contains six grids and you want to create climate divisions data for the first, third, and fifth grids, set `grids=1,3,5`. Values must be comma-delimited.

`files` Provide the output filenames for each of the climate divisions data files to be created. The number of filenames provided should match the number of `ngrids`. Date wildcards and the three allowed variables can be used. Note that the script grids-to-climdivs.pl takes an `--output` argument set to the output directory where files should be written. Therefore, the path/filename provided here should be relative to the path provided by the `--output` option. Values must be comma-delimited.

`descriptions` Provide a brief description of the data, and this will be printed as a header line in the climate divisions output data. Provide one description for each grid that is output. Values must be comma-delimited.

### Perl scripts

#### grids-to-climdivs.pl

This is the main script of the application. It optionally takes a date argument, the configuration file described above, and an output argument set to the directory where climate divisions data will be written. The script then computes the requested climate divisions data, using wgrib2 to regrid the input data as necessary. The full command line options are:

```
Usage:
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
```

#### update-dates.pl

This script is utilized by the driver script, and is intended to provide self-healing capabilities when this application is run on cron to update date-based climate divisions archives. It takes a date argument, a period argument (a number of days prior to the date argument), the config file argument, a (date list) file argument, and the output directory of the climate divisions archive argument. The script then:

1. Adds the date arg to a list of dates to update
2. Checks the file argument for a list of dates that may be left over from previous runs and adds those dates to the list of dates to update
3. Scans the archive for `period` days ending on `date` for missing or empty data files, and if any are found, adds those corresponding dates to the list.
4. The list of dates is sorted and culled of duplicate dates, then written to `file`.

The driver script can then read the resulting list of dates and attempt to update the climate divisions archive for those dates.

The full command line options are:

```
Usage:
     update-dates.pl [-c|-d|-f|-p]
     update-dates.pl -h
     update-dates.pl -man

     [OPTION]            [DESCRIPTION]                                    [VALUES]

     -config, -c         Configuration file containing information        filename
                         describing the grids-to-climdivs output 
                         filename
     -date, -d           Date argument                                    YYYYMMDD
     -help, -h           Print usage message and exit
     -file, -f           Filename containing list of dates. If none 
                         exists yet, one will be created
     -manual, -man       Display script documentation
     -output, -o         Output directory where the climate divisions 
                         data are located. Default location if none 
                         supplied is ../work
     -period, -p         Number of days prior to the date supplied by     Positive int
                         the -d argument to scan for missing 
                         grids-to-climdivs output files
```

### Driver script

The driver script `drivers/daily.sh` is a bash shell script intended to help run grids-to-climdivs in an automated sense, e.g., on a cron job, or to generate a large archive. The script takes three positional arguments: `./daily.pl config startdate enddate`

`config` This is the configuration file describing the input grids to use and output data files to create.

`startdate` For long archive creation, this is the start date to begin creating climate divisions data.

`enddate` This is the ending date, or the last date to create climate divisions data. When the driver script hits this end date, it will also run update-dates.pl to attempt to backfill anything missed. The default period is 30 days; reset this in the script if you want it shorter or longer.

The `config` argument is required. If only one date argument is provided, both `startdate` and `enddate` will be set to it (e.g., only that date will be run, and update-dates.pl will be run). If no date arguments are supplied, both `startdate` and `enddate` will be set to yesterday's date based on the system clock.

## Output Data

To create a sample output file (and a good way to test the software to make sure it works on your system!), `cd` into the application directory and run the following: `perl scripts/grids-to-climdivs.pl -c config/config.example -o output`. This should result in output to the terminal that looks like:

```
Running grids-to-climdivs for [yesterday] and config/config.example
Converting grid 1 of 6 to climate divisions
output/sample.tmax.climdivs written!
Converting grid 3 of 6 to climate divisions
output/sample.tmin.climdivs written!
Converting grid 5 of 6 to climate divisions
output/sample.tave.climdivs written!
```

If you see that, then you're in good shape! Now run: `head output/sample.tmax.climdivs`. You should see the top few lines of one of the created climate division data files:

```
STCD|TMAX
101|55.823
102|56.514
103|58.756
104|57.856
105|57.742
106|60.745
107|63.113
108|63.514
201|56.982
```

Data are pipe (|) delimited. The first line of this file is the header line, and STCD means "state number and climate division number". A table defining these states and divisions can be found [here](https://ftp.cpc.ncep.noaa.gov/htdocs/degree_days/weighted/daily_data/regions/ClimateDivisions.txt). TMAX is what the corresponding `descriptions` parameter was set to in the config file. Here it means maximum temperature.

Note that for this sample case, the default date of yesterday does not matter.

## Roadmap

See the [open issues](https://github.com/avram-meir/grids-to-climdivs/issues) for a list of proposed features and reported problems.

## Contributing

Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Contact

Adam Allgood - [Email](mailto:avram.meir@noaa.gov)
