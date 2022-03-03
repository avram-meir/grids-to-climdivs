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

In addition to [Perl 5](https://www.perl.org/get.html), the following modules from CPAN must be installed on your system:

* [Date::Manip](https://metacpan.org/pod/Date::Manip)
* [Config::Simple](https://metacpan.org/pod/Config::Simple)
* [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

Most Linux distributions include these modules in their package repositories.

For example, in Debian/Ubuntu based distributions, try: `sudo apt install libdate-manip-perl libconfig-simple-perl liblist-moreutils-perl`

You can also install these packages using Perl's `cpan` utility, e.g., 

`sudo cpan -i Date::Manip`
`sudo cpan -i Config::Simple`
`sudo cpan -i List::MoreUtils`

See: [cpan](https://perldoc.perl.org/cpan) for more information, including using [local::lib](https://metacpan.org/pod/local::lib) if you don't have sudo access.

#### Install wgrib2

The wgrib2 utility must be compiled and installed on your system. Detailed instructions can be found here: [wgrib2 compile questions](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/compile_questions.html). There are some available pre-compiled versions of wgrib2, but only for specific systems, and YMMV.

Precompiled wgrib2 binaries for download can (possibly) be found on these sites:

* [OpenGrads: Darwin, Freebsd, Linux, Windows(cygwin)](https://opengrads.org/)
* [Fedora Project](https://fedoraproject.org)
* [RPMs: Centros, Fedora, OpenSUSE, RedHat, SUSE](https://download.opensuse.org/repositories/home:/gbvalor/)
* [MacPorts](https://trac.macports.org/browser/trunk/dports/science/wgrib2/Portfile)

### Install grids-to-climdivs

1. Clone the repo:
  ```git clone git@github.com:[name]/[project-name-here]```
2. Complete the installation using [GNU Make](https://www.gnu.org/software/make/):
  ```
  cd grids-to-climdivs
  make install
  ```

## Usage

### Configuration files

### Perl scripts

### Driver script

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
