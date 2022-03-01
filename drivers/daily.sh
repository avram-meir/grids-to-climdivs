#!/bin/bash

if [ -s ~/.profile ] ; then
	. ~/.profile
fi

usage() {
	printf "Usage :\n";
	printf "   $(basename "$0") config date\n";
	printf "   $(basename "$0") config startdate enddate\n";
}

# --- Get command line args ---

startarg=""
endarg=""
if [ "$#" == 3 ] ; then
	config=$1
        startarg=$3
        endarg=$3
elif [ "$#" == 2 ] ; then
	config=$1
        startarg=$2
        endarg=$2
elif [ "$#" == 1 ] ; then
	config=$1
        startarg=$(date +%Y%m%d --date "today")
        endarg=$startarg
else
        usage >&2
        exit 1
fi

# --- Validate config arg ---

if [ ! -f $config ] ; then
	printf "%s does not exist\n" $config >&2
	usage >&2
	exit 1
fi

# --- Validate args as dates ---

startdate=$(date +%Y%m%d --date $startarg)

if [ $? -ne 0 ] ; then
        printf "%s is an invalid date\n" $startarg >&2
        usage >&2
        exit 1
fi

enddate=$(date +%Y%m%d --date $endarg)

if [ $? -ne 0 ] ; then
        printf "%s is an invalid date\n" $endarg >&2
        usage >&2
        exit 1
fi

if [ $startdate -gt $enddate ] ; then
        printf "The end date precedes the start date - switching the order\n"
        tempdate=$enddate
        enddate=$startdate
        startdate=$tempdate
fi

# --- Loop through all days in the range defined by the start and end dates ---

printf "Updating from %s to %s\n" $startdate $enddate

cd $(dirname "$0")

cfileroot=${config##*/}
cfileroot=${cfileroot%.*}
datesfile="../dates/$cfileroot.list"
outputdir="${DATA_OUT}/observations/land_air/all_ranges/conus/climate_divisions"

failed=0
date=$startdate

until [ $date -gt $enddate ] ; do
        printf "\nUpdating %s now\n" $date
	printf "\nDay of the week: %s\n\n" $(date +%a --date $date)

        scriptfailed=0

	if [ $date -eq $enddate ] ; then

		# --- Update list of dates to run ---

		script="../scripts/update-dates.pl"
		printf "Updating the list of dates to run: %s\n" $datesfile
		perl $script -c $config -f $datesfile -o $outputdir

		if [ $? -ne 0 ] ; then
			printf "Could not update dates (%s returned error %d)\n" $script $? >&2
			exit 1
		fi

		# --- Loop through the updated dates list ---

		faileddates=()
		printf "Creating climate divisions data for dates on the update list\n"

		while read $fdate; do

			# --- Create climate divisions data for the dates list date ---

			script="../scripts/grids-to-climdivs.pl"
			perl $script -c $config -d $fdate -o $outputdir

			# --- Store failed date in array ---

			if [ $? -ne 0 ] ; then
				printf "grids-to-climdivs failed to update %s\n" $fdate
				faileddates+=( "$fdate" )
			fi

		done <$datesfile

		# --- Write the failed dates to the dates file (better luck next time!) ---

		if [ ${#faileddates[@]} -ne 0 ]; then
			printf "Writing failed dates to %s\n" $datesfile
			printf "%s\n" ${faileddates[@]} > $datesfile
			((scriptfailed++))
		fi

	else

		# --- Create climate divisions data for the date ---

		script="../scripts/grids-to-climdivs.pl"
		perl $script -c $config -d $date -o $outputdir

		# --- Check for errors ---

		if [ $? -ne 0 ] ; then
			printf "grids-to-climdivs failed to update %s\n" $date
			((scriptfailed++))
		fi

	fi

        # --- Note errors for this date ---

        if [ $scriptfailed -ne 0 ] ; then
                printf "There were %d script errors detected on %s\n" $scriptfailed $date >&2
                ((failed++))
        fi

        date=$(date +%Y%m%d --date "$date+1day")
done

# --- Exit script ---

if [ $failed -ne 0 ] ; then
        printf "There were errors detected on %d days\n" $failed >&2
        exit 1
fi

exit 0

