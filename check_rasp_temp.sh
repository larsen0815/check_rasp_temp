#!/bin/bash
# Adapted from check_nagios_latency
# https://github.com/larsen0815/check_rasp_temp


# Prints usage information
usage() {

	if [ -n "$1" ] ; then
		echo "Error: $1" 1>&2
	fi

	echo ""
	echo "Usage: check_rasp_temp [-hl?] -w warning -c critical"
	echo ""
	echo "   -w         warning threshold"
	echo "   -c         critical threshold"
	echo "   -l         check for low temperatures"
	echo "   -h, -?     this help message"
	echo ""

	exit 3
}


# Checks if a given program is available and executable
check_prog() {

	if [ -z "$PROG" ] ; then
		PROG=$(which $1)
	fi

	if [ -z "$PROG" ] ; then
		echo "TEMPERATURE UNKNOWN - cannot find $1"
		exit 3
	fi

	PROG=""
}


# Main
check_prog vcgencmd
check_prog awk
check_prog bc


# process command line options
while getopts "hl?c:w:" opt; do
	case $opt in
		c )      CRITICAL=$OPTARG;  ;;
		h | \? ) usage ; exit 3;    ;;
		w )      WARNING=$OPTARG;   ;;
		l )      LOW=true;          ;;
	esac
done
shift $(($OPTIND - 1))


# Check options
if [ -z "${WARNING}" ] ; then
	usage "No warning threshold specified"
fi
if [ -z "${CRITICAL}" ] ; then
	usage "No critical threshold specified"
fi

# Check number formats
if ! echo $WARNING | grep -qE '^[0-9]+(\.[0-9]+)?$' ; then
	echo "TEMPERATURE UNKOWN - Wrong number: $WARNING"
	exit 3
fi
if ! echo $CRITICAL | grep -qE '^[0-9]+(\.[0-9]+)?$' ; then
	echo "TEMPERATURE UNKOWN - Wrong number: $CRITICAL"
	exit 3
fi


# Perform the checks
TEMP=$(sudo vcgencmd measure_temp | awk -F"=" '{print $2}' | awk -F"'" '{print $1}')
PERF="temp=${TEMP};${WARNING};${CRITICAL};;"

if [ "$LOW" == true ] ; then
	COMPARISON=$(echo "if($TEMP<=$CRITICAL) 1 else 0;" | bc)
	if [ $COMPARISON -eq 1 ] ; then
		echo "TEMPERATURE CRITICAL: $TEMP | $PERF"
		exit 2
	fi
	
	COMPARISON=$(echo "if($TEMP<=$WARNING) 1 else 0;" | bc)
	if [ $COMPARISON -eq 1 ] ; then
		echo "TEMPERATURE WARNING: $TEMP | $PERF"
		exit 1
	fi
else
	COMPARISON=$(echo "if($TEMP>=$CRITICAL) 1 else 0;" | bc)
	if [ $COMPARISON -eq 1 ] ; then
		echo "TEMPERATURE CRITICAL: $TEMP | $PERF"
		exit 2
	fi
	
	COMPARISON=$(echo "if($TEMP>=$WARNING) 1 else 0;" | bc)
	if [ $COMPARISON -eq 1 ] ; then
		echo "TEMPERATURE WARNING: $TEMP | $PERF"
		exit 1
	fi
fi

echo "TEMPERATURE OK: $TEMP | $PERF"
exit 0;
