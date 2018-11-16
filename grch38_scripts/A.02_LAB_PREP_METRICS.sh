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

# INPUT VARIABLES

	JAVA_1_8=$1
	LAB_QC_DIR=$2
	CORE_PATH=$3

	PROJECT=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$6

START_LAB_PREP_METRICS=`date '+%s'`

# Make a QC report just for a project in the sample sheet.

(head -n 1 $SAMPLE_SHEET ; \
	awk 'BEGIN {FS=",";OFS=","} $1=="'$PROJECT'" {print $0}' $SAMPLE_SHEET ) \
	>| $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$START_LAB_PREP_METRICS".csv"

$JAVA_1_8/java -jar $LAB_QC_DIR/EnhancedSequencingQCReport.jar \
-lab_qc_metrics \
$CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$START_LAB_PREP_METRICS".csv" \
$CORE_PATH \
$CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				echo $SAMPLE $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
				>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.csv"
				exit $SCRIPT_STATUS
			fi

END_LAB_PREP_METRICS=`date '+s'`

(head -n 1 $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv" \
	| awk '{print $0 ",EPOCH_TIME"}' ; \
	awk 'NR>1 {print $0 "," "'$START_LAB_PREP_METRICS'"}' \
	$CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv" \
	| sort -k 1,1 ) \
	>| $CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv"

echo $PROJECT,X.01,LAB_QC_PREP_METRICS,$HOSTNAME,$START_LAB_PREP_METRICS_METRICS,$END_LAB_PREP_METRICS \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

exit $SCRIPT_STATUS
