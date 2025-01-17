#!/bin/bash
# adding some imple args for now. $1 is size
#TODO: Make more robust

trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

#MR_EXAMPLES_JAR=/usr/hdp/2.2.0.0-2041/hadoop-mapreduce/hadoop-mapreduce-examples.jar
#MR_EXAMPLES_JAR=/usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2.7.3-amzn-0.jar
MR_EXAMPLES_JAR=/usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar

case "$1" in 
  "")
    echo ""
    echo "Usage: teragenEMR.sh <SIZE>"
    echo "     SIZE=1T,500G,100G,10G,1G"
    exit
    ;;
  *1T*)
    SIZE=1T
    ROWS=10000000000
    ;;
  *500G*)
    SIZE=500G
    ROWS=5000000000
    ;;
  *100G*)
    SIZE=100G
    ROWS=1000000000
    ;;
  *10G*)
    SIZE=10G
    ROWS=100000000
    ;;
  *1G*)
    SIZE=1G
    ROWS=10000000
    ;;
esac

S3BUCKET=jimmy.emr

#SIZE=500G
#ROWS=5000000000

#SIZE=100G
#ROWS=1000000000

 #SIZE=1T
 #ROWS=10000000000

# SIZE=10G
# ROWS=100000000

# SIZE=1G
# ROWS=10000000


LOGDIR=logs

if [ ! -d "$LOGDIR" ]
then
    mkdir ./$LOGDIR
fi

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="./$LOGDIR/teragen_results_$DATE"


OUTPUT=s3://$S3BUCKET/data/poc/teragen/$SIZE-terasort-input

# teragen.sh
# Kill any running MapReduce jobs
mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '
# Delete the output directory
hadoop fs -rm -r -f -skipTrash ${OUTPUT}

# Run teragen
time hadoop jar $MR_EXAMPLES_JAR teragen \
-Dmapreduce.map.log.level=INFO \
-Dmapreduce.reduce.log.level=INFO \
-Dyarn.app.mapreduce.am.log.level=INFO \
-Dio.file.buffer.size=131072 \
-Dmapreduce.map.cpu.vcores=1 \
-Dmapreduce.map.java.opts=-Xmx1536m \
-Dmapreduce.map.maxattempts=1 \
-Dmapreduce.map.memory.mb=2048 \
-Dmapreduce.map.output.compress=true \
-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec \
-Dmapreduce.reduce.cpu.vcores=1 \
-Dmapreduce.reduce.java.opts=-Xmx1536m \
-Dmapreduce.reduce.maxattempts=1 \
-Dmapreduce.reduce.memory.mb=2048 \
-Dmapreduce.task.io.sort.factor=100 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx1900m \
-Dyarn.app.mapreduce.am.resource.mb=2024 \
-Dmapred.task.timeout=12000000 \
-Dmapred.map.tasks=92 \
${ROWS} ${OUTPUT} >> $RESULTSFILE 2>&1

#-Dmapreduce.map.log.level=TRACE \
#-Dmapreduce.reduce.log.level=TRACE \
#-Dyarn.app.mapreqduce.am.log.level=TRACE \
