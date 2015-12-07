#!/bin/sh

# Path to HDFS directory for uploading RDF N-Triples Data
HDFS_PATH="TODO"

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

# Path to input RDF data
RDF_INPUT_PATH="$ETL_PROCESS_HOME"'/input'

# Path to output RDF N-Triples data
RDF_OUTPUT_PATH="$ETL_PROCESS_HOME"'/output'

# Jena settings
JVM_ARGS=${JVM_ARGS:--Xmx4096M}
JENA_CP="$ETL_PROCESS_HOME"'/lib/*'
LOGGING="${LOGGING:--Dlog4j.configuration=file:$ETL_PROCESS_HOME/jena-log4j.properties}"
JVM_ARGS="$JVM_ARGS -Djava.io.tmpdir=\"$TMPDIR\""

# Transform every file (excluding *.nt or *.ntriples) to N-Triples data
echo "###########################################"
echo "Transform RDF Data into N-Triples Format..."
echo "###########################################"

for entry in "$RDF_INPUT_PATH"/*
do
  if [ -f "$entry" ];then
    full_filename=`basename $entry`
    extension="${full_filename##*.}"
    filename="${full_filename%.*}"

    if ! [ $extension == "nt"  ] && ! [ $extension == "ntriples" ]
      then
      echo "Transforming '$full_filename' to N-Triples '$filename.nt'"
      java $JVM_ARGS $LOGGING -cp "$JENA_CP" riotcmd.riot --time -q --output=nt "$entry" > "$RDF_OUTPUT_PATH/$filename".nt
    fi
  fi
done

echo "Transformation done..."
echo ""

# Move generated N-Triples files to HDFS
echo "hadoop fs -copyFromLocal "$RDF_OUTPUT_PATH" "$HDFS_PATH""

# Execute ETL Process by Java Programm for loading MDM and creating OLAP Cube in Apache Kylin
ETL_CP="$ETL_PROCESS_HOME"'/etl_process_v1.jar'
java -cp "$ETL_CP" org.mustangore.etl.ETLProcess