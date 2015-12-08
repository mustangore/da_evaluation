#!/bin/sh

# Path to HDFS directory for uploading RDF N-Triples Data
HDFS_PATH="/user/ec2-user"

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
RDF_INPUT_PATH="$ETL_PROCESS_HOME"'/rdf-data'

# Path to output RDF N-Triples data
RDF_OUTPUT_PATH="$ETL_PROCESS_HOME"'/rdf-data/ntriples'

# Jena settings
JVM_ARGS=${JVM_ARGS:--Xmx4096M}
JENA_CP="$ETL_PROCESS_HOME"'/lib/*'
LOGGING="${LOGGING:--Dlog4j.configuration=file:$ETL_PROCESS_HOME/jena-log4j.properties}"
JVM_ARGS="$JVM_ARGS -Djava.io.tmpdir=\"$TMPDIR\""

# Transform every file (excluding *.nt or *.ntriples) to N-Triples data
echo "###########################################"
echo "Transform RDF Data into N-Triples Format..."
echo "###########################################"
ts=$(date +"%s");
for entry in "$RDF_INPUT_PATH"/*
do
  if [ -f "$entry" ];then
    full_filename=`basename $entry`
    extension="${full_filename##*.}"
    filename="${full_filename%.*}"

    if [ $extension != "nt"  ] && [ $extension != "ntriples" ] ; then
      echo "Transforming '$full_filename' to N-Triples '$filename.nt'"
      java $JVM_ARGS $LOGGING -cp "$JENA_CP" riotcmd.riot --time -q --output=nt "$entry" > "$RDF_OUTPUT_PATH/$filename".nt
    fi
  fi
done
echo $(expr $(date +"%s") - $ts)
echo "Transformation done..."
echo ""

echo "################################"
echo "Generate ntriples.tar.gz File..."
echo "################################"
ts=$(date +"%s");
time tar -czvf ntriples.tar.gz $RDF_OUTPUT_PATH/*.nt
echo $(expr $(date +"%s") - $ts)
echo "Done..."
echo ""

# Move generated N-Triples files to HDFS
echo "###############################"
echo "Move ntriples.tar.gz to HDFS..."
echo "###############################"

ts=$(date +"%s");
hdfs dfs -put $RDF_OUTPUT_PATH $HDFS_PATH
echo $(expr $(date +"%s") - $ts)
echo "Done..."
echo ""

# Execute ETL Process by Java Programm for loading MDM and creating OLAP Cube in Apache Kylin
echo "######################"
echo "Execute ETL Process..."
echo "######################"
ETL_CP="$ETL_PROCESS_HOME"'/etl_process_v1.jar'
time java -cp "$ETL_CP" org.mustangore.etl.ETLProcess

echo "Done..."
echo ""
