# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -10

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

set

JAVA_1_8=$1
PICARD_DIR=$2
CORE_PATH=$3

PROJECT=$4
SM_TAG=$5

## --Mark Duplicates with Picard, write a duplicate report

START_MARK_DUPLICATES=`date '+%s'`

$JAVA_1_8/java -jar \
-Xmx16g \
-XX:ParallelGCThreads=4 \
$PICARD_DIR/picard.jar MarkDuplicates \
INPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
OUTPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
VALIDATION_STRINGENCY=SILENT \
METRICS_FILE=$CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt" \
CREATE_INDEX=true

END_MARK_DUPLICATES=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",C.01,MARK_DUPLICATES,"$HOSTNAME","$START_MARK_DUPLICATES","$END_MARK_DUPLICATES \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar \
-Xmx16g \
-XX:ParallelGCThreads=4 \
$PICARD_DIR/picard.jar MarkDuplicates \
INPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
OUTPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
VALIDATION_STRINGENCY=SILENT \
METRICS_FILE=$CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt" \
CREATE_INDEX=true \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
