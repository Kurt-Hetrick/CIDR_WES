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

echo

JAVA_1_8=$1
LAB_QC_DIR=$2
CORE_PATH=$3

PROJECT=$4
SAMPLE_SHEET=$5

START_LAB_PREP_METRICS=`date '+%s'`


SAMPLE_SHEET_NAME=`basename $SAMPLE_SHEET .csv`

$JAVA_1_8/java -jar $LAB_QC_DIR/EnhancedSequencingQCReport.jar \
-lab_qc_metrics \
$SAMPLE_SHEET \
$PROJECT \
$CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv"

END_LAB_PREP_METRICS=`date '+s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT,X.01,LAB_QC_PREP_METRICS,$HOSTNAME,$START_LAB_PREP_METRICS_METRICS,$END_LAB_PREP_METRICS_METRICS \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# echo $JAVA_1_8/java -jar $LAB_QC_DIR/EnhancedSequencingQCReport.jar \
# -lab_qc_metrics \
# $SAMPLE_SHEET \
# $PROJECT \
# $CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv" \
# >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

# ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz.tbi"
