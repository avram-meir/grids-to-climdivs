# grids-to-climdivs

Create 363 climate divisions data for the contiguous United States, Alaska, and Hawaii using gridded input datasets.

<table>
   <td width="72%"><img src="https://user-images.githubusercontent.com/94878449/156598379-08ecd22f-8ead-471b-8332-e132c8650a96.png"></td>
   <td width="28%"><img src="https://user-images.githubusercontent.com/94878449/162528023-3fd59661-08fb-41a3-b5a6-9e443cac2fb1.png"><br><img src="https://user-images.githubusercontent.com/94878449/162529132-7b2d6742-7e61-49ea-8257-42740b0b77b0.png"></td>
</table>

## About

Some of the longest record climate datasets for the contiguous United States utilize the [344 climate divisions](https://www.ncdc.noaa.gov/monitoring-references/maps/conus-climate-divisions) as their geographical reference. Example products include:

* [National Temperature and Precipitation Maps](https://www.ncei.noaa.gov/access/monitoring/us-maps/)
* [CPC Degree Days Statistics](https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/degree_days/)
* [CPC Palmer Drought Index](https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/palmer_drought/)
* [Historical Palmer Drought Indices (NCEI)](https://www.ncdc.noaa.gov/temp-and-precip/drought/historical-palmers/)

More recently, climate divisions were [defined for Alaska](https://www.ncdc.noaa.gov/news/climate-division-data-now-available-alaska), and Alaska data are now included in products such as the [National Centers for Environmental Information (NCEI)](https://www.ncei.noaa.gov/)'s [nClimDiv dataset](https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00005). For Hawaii, six climate divisions consisting of the largest populated islands are defined.

In the past, climate divisions data were estimated using a weighted average of data from nearby stations; however, with the availability of high quality and high resolution gridded observational datasets, climate divisions data should be computed from these gridded products. This software application provides a process to compute degree days data from gridded products using the following steps:

1. A "map" file is provided using a 1/8th degree lat/lon grid over the CONUS listing which gridpoints fall within a climate division. A similar map file is provided using a 1/6th degree lat/lon grid over the globe listing which gridpoints fall within each Alaska division or Hawaiian island.
2. If needed, input grids are regridded to match the resolution and domain of these map files using wgrib2 software. In order to perform this step, the input grid must have an example (template) in grib2 format to define the grid dimensions for the regrid.
3. Climate divisions data are computed using a straight average of the gridpoints that fall within each division.
4. If needed, unit conversions or other calculations can be performed on the climate divisions data before output is written.
5. Climate divisions data are written to a pipe-delimited text file.

### Built With

* [Bash](https://www.gnu.org/software/bash/)
* [Perl5](https://www.perl.org/)
* [wgrib2](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/)

## Getting Started

### Environment

The grids-to-climdivs application is designed to run in the [bash shell](https://www.gnu.org/software/bash/). The bash shell is available on Linux and MacOS systems, and on [Windows systems now as well](https://itsfoss.com/install-bash-on-windows/).

### Prerequisites

The grids-to-climdivs application relies on other software that needs to be installed on your system.

#### Install Perl

A Perl interpreter must be installed on your system (i.e., entering `which perl` in a bash shell prompt should give you a path to the perl interpreter). Perl is installed by default on most Linux systems, in which case you do not need to do anything. If you need to install Perl:

* [Install Perl on Unix/Linux systems](https://learn.perl.org/installing/unix_linux.html)
* [Install Perl on Windows systems](https://learn.perl.org/installing/windows.html)
* [Install Perl on MacOS systems](https://learn.perl.org/installing/osx.html)

#### Install CPAN Modules

Several packages must be installed from the CPAN library. See [Installing Perl Modules](http://www.cpan.org/modules/INSTALL.html) for more information about installing packages from CPAN.

* [Date::Manip](https://metacpan.org/pod/Date::Manip)
* [Config::Simple](https://metacpan.org/pod/Config::Simple)
* [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

#### Install wgrib2

The wgrib2 utility must be compiled and installed on your system. Detailed instructions can be found here: [wgrib2 compile questions](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/compile_questions.html). There are some available pre-compiled versions of wgrib2, but only for specific systems, and your mileage may vary.

Precompiled wgrib2 binaries for download can (possibly) be found on these sites:

* [OpenGrads: Darwin, Freebsd, Linux, Windows(cygwin)](https://opengrads.org/)
* [Fedora Project](https://fedoraproject.org)
* [RPMs: Centros, Fedora, OpenSUSE, RedHat, SUSE](https://download.opensuse.org/repositories/home:/gbvalor/)
* [MacPorts](https://trac.macports.org/browser/trunk/dports/science/wgrib2/Portfile)

This application was developed and tested using wgrib2 v3.1.0.

### Install grids-to-climdivs

Once the prerequisite software is installed, now install grids-to-climdivs itself!

1. Clone the repo:
  ```git clone git@github.com:avram-meir/grids-to-climdivs.git```
2. Complete the installation using [GNU Make](https://www.gnu.org/software/make/):
  ```
  cd grids-to-climdivs
  make install
  ```

## Usage

### Configuration files

To define the gridded input files and compute climate divisions output files from those data, grids-to-climdivs uses configuration files in ["INI" format](https://metacpan.org/pod/Config::Simple#INI-FILE) that hold all of the needed information. A [sample configuration file](config/binary-example.config) is provided that can be used as a starting point to create new configuration files for your input data. The sample config file works with a sample gridded data file provided in the same directory, which is useful for testing the software functionality on your system. This is the sample configuration file:

```
[input]

; Parameters in this section include:
;   file
;   byteorder  Are the data written in "big_endian" or "little_endian" format?
;   missing    Value used as the missing data indicator in the input dataset
;   headers    Do the grids have Fortran-style headers (e.g., 4 bytes at the beginning and end of each record)? Supply "header" if yes, or "no_header" if no.
;   ngrids     How many grid records are in the dataset?
;   rgconus    Do the grids need to be regridded to match the CONUS map file? Supply "1" for yes, or "0" for no.
;   rgakhi     Do the grids need to be regridded to match the AK-HI map file? Supply "1" for yes, or "0" for no.

file=$APP_PATH/config/sample-binary.grid
byteorder=little_endian
missing=-999.
headers=no_header
ngrids=3
rgconus=1
rgakhi=0

[regrid]

; Supply the parameters in this section if [input]->regrid=1
; Parameters in this section include:
;   template   Grib2 data file with dimensions matching the binary grid

template=$APP_PATH/lib/grib2/global-6th-degree.template.grb

[output]

; Parameters in this section include:
;   rpn        Supply an expression in Reverse Polish Notation to convert the gridpoints (e.g., for a unit conversion)
;   grids         Which grids to create climdivs data for (available grids are 1 through ngrids)
;   files         Output filenames to use (date wildcards and certain variables allowed)
;   descriptions  Descriptions of data to print in the header line of the climdivs files

rpn=9:*:5:/:32:+
grids=1,2,3
files=sample.tmax.climdivs,sample.tmin.climdivs,sample.tave.climdivs
descriptions=TMAX,TMIN,TAVE
```

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

The driver script `drivers/daily.sh` is a bash shell script intended to help run grids-to-climdivs in a more automated way, e.g., on a cron job, or to generate a large archive over many dates. The script takes three positional arguments: `./daily.pl config startdate enddate`

`config` This is the configuration file describing the input grids to use and output data files to create.

`startdate` For long archive creation, this is the start date to begin creating climate divisions data.

`enddate` This is the ending date, or the last date to create climate divisions data. When the driver script hits this end date, it will also run update-dates.pl to attempt to backfill anything missed. The default period is 30 days; reset this in the script if you want it shorter or longer.

The `config` argument is required. If only one date argument is provided, both `startdate` and `enddate` will be set to it (e.g., only that date will be run, and update-dates.pl will be run targeting that date). If no date arguments are supplied, both `startdate` and `enddate` will be set to yesterday's date based on the system clock.

## Output Data

To create a sample output file (and a good way to test the software to make sure it works on your system!), `cd` into the application directory and run the following: `perl scripts/grids-to-climdivs.pl -c config/binary-example.config -o output`. This should result in output to the terminal that looks like:

```
Running grids-to-climdivs for 20220411 and config/binary-example.config
Converting grid 1 of 3 in scripts/../config/sample-binary.grid to climate divisions
output/sample.tmax.climdivs written!
Converting grid 2 of 3 in scripts/../config/sample-binary.grid to climate divisions
output/sample.tmin.climdivs written!
Converting grid 3 of 3 in scripts/../config/sample-binary.grid to climate divisions
output/sample.tave.climdivs written!
```

If you see that, then you're in good shape! Now run: `head output/sample.tmax.climdivs`. You should see the top few lines of one of the created climate division data files:

```
STCD|TMAX
AL01|55.843
AL02|56.524
AL03|58.764
AL04|57.871
AL05|57.754
AL06|60.756
AL07|63.113
AL08|63.499
AK01|-18.725
```

Data are pipe (|) delimited. The first line of this file is the header line, and STCD means "state acronym and climate division number". A table defining these states and divisions can be found [here](lib/climdivs/climdivs363.txt). TMAX is what the corresponding `descriptions` parameter was set to in the config file, and it means maximum temperature.

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
