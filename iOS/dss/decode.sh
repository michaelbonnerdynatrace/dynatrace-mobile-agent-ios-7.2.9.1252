#!/bin/sh
# decode.sh
# Copyright 2017 Dynatrace LLC

TMP_DIR="tmp"
SYM_FILE="NO"
VERBOSE="NO"
DRYRUN="NO"
HELP="NO"
STARTDIR=$PWD
OUT_FILE="_symbols.zip"
SUB_PATTERN='\([#]\)'

SCRIPTPATH=`dirname $0`
DSSCLIENT=$SCRIPTPATH"/DTXDssClient"

for i in "$@"
do
case $i in
	-h|--help|help)
	HELP="YES"
	;;
    -v|--verbose|verbose)
    VERBOSE="YES"
    ;;
    -d|--dry|dry)
    DRYRUN="YES"
    VERBOSE="YES"
    ;;
	-dc=*|--dss-client=*)
	DSSCLIENT="${i#*=}"
	;;
	-t=*|--tmp-dir=*)
	TMP_DIR="${i#*=}"
	;;
    *)
       SYM_FILE=$i
    ;;
esac
done

if [ "$HELP" = "YES" ]; then
  echo "Usage: decode.sh [options] [symbols_file]"
  echo "Example: ./decode.sh MyApp.dsym"
  echo "   -h    , --help         show help"
  echo "   -v    , --verbose      verbose mode"
  echo "   -d    , --dry          dry run (no files are created)"
  echo "   -t=   , --tmp-dir=     temporary working directory"
  echo "   -dc== , --dss-client=  path of the DTXDssClient executable"
  exit 0
fi

if [ "$SYM_FILE" = "NO" ]; then
  echo "SYM_FILE is empty"
  exit 0
fi

OUT_FILE=$(echo "$SYM_FILE" | sed 's:.*/::' | cut -d '.' -f 1)$OUT_FILE


if [ "$DRYRUN" = "YES" ]; then
  echo "dry mode: on"
fi
if [ "$VERBOSE" = "YES" ]; then
  echo "verbose mode: on"
  echo "symbols file: 	$SYM_FILE"
  echo "temp directory: $TMP_DIR"
  echo "result file: 	$OUT_FILE"
fi

#begin!
if [ "$VERBOSE" = "YES" ]; then
	echo "remove temp directory: $TMP_DIR"
fi
if [ "$DRYRUN" = "NO" ]; then
	if [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR"
	fi
fi
if [ "$DRYRUN" = "NO" ]; then
	if [ -f "$OUT_FILE" ]; then
		echo "delete already existing result file: $OUT_FILE"
		rm -rf "$OUT_FILE"
	fi
fi

if [ "$VERBOSE" = "YES" ]; then
	echo "create temp directory: $TMP_DIR"
fi
if [ "$DRYRUN" = "NO" ]; then
	mkdir "$TMP_DIR"
fi

if [ "$VERBOSE" = "YES" ]; then
	echo "exec dss client: " "$DSSCLIENT" -decode symbolsfile="$SYM_FILE" tempdir="$TMP_DIR" verbose="$VERBOSE"
fi
if [ "$DRYRUN" = "NO" ]; then
    if [ "$VERBOSE" = "YES" ]; then
	    "$DSSCLIENT" -decode symbolsfile="$SYM_FILE" tempdir="$TMP_DIR" verbose=YES
    else
    	"$DSSCLIENT" -decode symbolsfile="$SYM_FILE" tempdir="$TMP_DIR"
    fi
fi
#unpack zip files
if [ "$VERBOSE" = "YES" ]; then
	echo "deflate architecture files"
fi
cd $TMP_DIR
if [ "$DRYRUN" = "NO" ]; then
	for z in *.zip; do
	    unzip "$z"
		rm -rf "$z"
	done	
fi
if [ "$VERBOSE" = "YES" ]; then
	echo "create result file: $OUT_FILE"
fi
if [ "$DRYRUN" = "NO" ]; then
	zip "$OUT_FILE" *.*
fi
if [ "$VERBOSE" = "YES" ]; then
	echo "move result file to target directory"
fi

if [ "$DRYRUN" = "NO" ]; then
	mv "$OUT_FILE" "$STARTDIR/$OUT_FILE"
fi
cd "$STARTDIR"

#at last clenup
if [ "$VERBOSE" = "YES" ]; then
	echo "cleanup temp directory: $TMP_DIR"
fi
if [ "$DRYRUN" = "NO" ]; then
	rm -rf "$TMP_DIR"
fi
echo "result file: $OUT_FILE"
