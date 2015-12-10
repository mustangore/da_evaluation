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
echo "#################################################"
echo "   Transform RDF Data into N-Triples Format...   "
echo "#################################################"

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


# Split lineorder.nt ...
echo "##############################"
echo "   Split N-Triples Files...   "
echo "##############################"
ts=$(date +"%s");

echo "Split lineorder_qb.nt to lineorder_qb.nt.000X by 20 000 000 lines"
time split -l 20000000 --numeric-suffixes --suffix-length=3 "$RDF_OUTPUT_PATH/"lineorder_qb.nt lineorder_qb.nt.
echo $(expr $(date +"%s") - $ts)
echo "Remove Old lineorder_qb.nt file"
rm "$RDF_OUTPUT_PATH/"lineorder_qb.nt
echo $(expr $(date +"%s") - $ts)
echo "Split done..."


# Compress
echo "#################################"
echo "   Compress N-Triples Files...   "
echo "#################################"

ts=$(date +"%s");
for entry in "$RDF_OUTPUT_PATH"/*
do
  if [ -f "$entry" ];then
    full_filename=`basename $entry`
    extension="${full_filename##*.}"
    filename="${full_filename%.*}"

    echo "Compress '$full_filename' to '$full_filename.gz'"
    time gzip "$entry"
  fi
done
echo $(expr $(date +"%s") - $ts)
echo "Compression done..."


# Move generated compressed N-Triples files to HDFS
echo "#####################################"
echo "   Move ntriples.tar.gz to HDFS...   "
echo "#####################################"

ts=$(date +"%s");
time hdfs dfs -put $RDF_OUTPUT_PATH $HDFS_PATH
echo $(expr $(date +"%s") - $ts)
echo "Done..."
echo ""




# Execute ETL Process by Java Programm for loading MDM and creating OLAP Cube in Apache Kylin
echo "############################"
echo "   Execute ETL Process...   "
echo "############################"
ETL_CP="$ETL_PROCESS_HOME"'/etl_process_v1_4.jar'
time java -cp "$ETL_CP" org.mustangore.etl.ETLProcess

echo "Done..."
echo ""


