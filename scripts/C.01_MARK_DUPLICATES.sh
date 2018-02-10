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

set

echo

JAVA_1_8=$1
PICARD_DIR=$2
SAMBAMBA_DIR=$3
CORE_PATH=$4

PROJECT=$5
SM_TAG=$6

INPUT_BAM_FILE_STRING=$7

INPUT=`echo $INPUT_BAM_FILE_STRING | sed 's/,/ /g'`

## --Mark Duplicates with Picard, write a duplicate report
## todo; have pixel distance be a input parameter with a switch based on the description in the sample sheet.

START_MARK_DUPLICATES=`date '+%s'`

$JAVA_1_8/java -jar \
-Xmx16g \
-XX:ParallelGCThreads=4 \
$PICARD_DIR/picard.jar \
MarkDuplicates \
ASSUME_SORT_ORDER=queryname \
$INPUT \
OUTPUT=/dev/stdout \
VALIDATION_STRINGENCY=SILENT \
METRICS_FILE=$CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt" \
COMPRESSION_LEVEL=0 \
| $SAMBAMBA_DIR/sambamba \
sort \
-t 4 \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
/dev/stdin

END_MARK_DUPLICATES=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",C.01,MARK_DUPLICATES,"$HOSTNAME","$START_MARK_DUPLICATES","$END_MARK_DUPLICATES \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar \
-Xmx16g \
-XX:ParallelGCThreads=4 \
$PICARD_DIR/picard.jar \
MarkDuplicates \
ASSUME_SORT_ORDER=queryname \
$INPUT \
OUTPUT=/dev/stdout \
VALIDATION_STRINGENCY=SILENT \
METRICS_FILE=$CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt" \
COMPRESSION_LEVEL=0 \
| $SAMBAMBA_DIR/sambamba \
sort \
-t 4 \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
/dev/stdin \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
