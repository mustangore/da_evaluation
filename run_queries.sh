#!/bin/sh

# Generell stuff, get current path
if [ -z "$ETL_PROCESS_HOME" ]
  then
    SCRIPT="$0"

  if [ -L "$SCRIPT" ]
    then
    SCRIPT="$(readlink "$0")"
    case "$SCRIPT" in
        /*) ;;
      *) SCRIPT=$( dirname "$0" )/$SCRIPT;;
    esac
  fi

  ETL_PROCESS_HOME="$( cd "$( dirname "$SCRIPT" )" && pwd )"
fi

# Execute ETL Process by Java Programm for loading MDM and creating OLAP Cube in Apache Kylin
echo "############################"
echo "   Execute ETL Process...   "
echo "############################"
ETL_CP="$ETL_PROCESS_HOME"'/etl_process_v1_4.jar'
time java -cp "$ETL_CP" org.mustangore.etl.ETLProcess

echo "Done..."
echo ""
