#!/bin/bash

if [ -s ~/.profile ] ; then
	. ~/.profile
fi

usage() {
	printf "Usage :\n";
	printf "   $(basename "$0") date\n";
	printf "   $(basename "$0") startdate enddate\n";
}

# --- Get command line args ---

startarg=""
endarg=""
if [ "$#" == 2 ] ; then
        startarg=$1
        endarg=$2
elif [ "$#" == 1 ] ; then
        startarg=$1
        endarg=$1
elif [ "$#" == 0 ] ; then
        startarg=$(date +%Y%m%d --date "today")
        endarg=$startarg
else
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

failed=0
date=$startdate

until [ $date -gt $enddate ] ; do
        printf "\nUpdating %s now\n" $date
	printf "\nDay of the week: %s\n\n" $(date +%a --date $date)

        scriptfailed=0

        # --- Run the perl script and check return value ---

	script="../scripts/daily.pl"

	perl ../scripts/daily.pl -d $date

        if [ $? -ne 0 ] ; then
		printf "The script %s failed with exit status %d\n" $script $? >&2
                ((scriptfailed++))
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

