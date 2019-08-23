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

	# I'M KEEPING TARGET BED AS AN INPUT VARIABLE EVEN THOUGH IT IS NO LONGER USED EXPLICITLY
	# MORE OF A CUE IN THE WRAPPER SCRIPT AS TO WHAT IS GOING ON

	JAVA_1_8=$1
	PICARD_DIR=$2
	SAMTOOLS_DIR=$3
	CORE_PATH=$4

	PROJECT=$5
	SM_TAG=$6
	REF_GENOME=$7
	BAIT_BED=$8
		BAIT_NAME=`basename $BAIT_BED .bed`
	TARGET_BED=$9
	SAMPLE_SHEET=${10}
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${11}

# Run Collect HS metrics which generates hybridization metrics for the qc report
## Also generates a per target interval coverage summary

START_COLLECT_HS_METRICS=`date '+%s'`

	$JAVA_1_8/java -jar $PICARD_DIR/picard.jar CollectHsMetrics \
	INPUT=$CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram" \
	OUTPUT=$CORE_PATH/$PROJECT/REPORTS/HYB_SELECTION/$SM_TAG"_hybridization_selection_metrics.txt" \
	PER_TARGET_COVERAGE=$CORE_PATH/$PROJECT/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE/$SM_TAG"_per_target_coverage.txt" \
	REFERENCE_SEQUENCE=$REF_GENOME \
	BAIT_INTERVALS=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".OnBait.picard.bed" \
	TARGET_INTERVALS=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".OnTarget.picard.bed" \
	MINIMUM_MAPPING_QUALITY=20 \
	MINIMUM_BASE_QUALITY=10 \
	BAIT_SET_NAME=$BAIT_NAME \
	VALIDATION_STRINGENCY=SILENT

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				echo $SAMPLE $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
				>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"
				exit $SCRIPT_STATUS
			fi

END_COLLECT_HS_METRICS=`date '+%s'`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,COLLECT_HS_METRICS,"$HOSTNAME","$START_COLLECT_HS_METRICS","$END_COLLECT_HS_METRICS \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $PICARD_DIR/picard.jar CollectHsMetrics \
INPUT=$CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram" \
OUTPUT=$CORE_PATH/$PROJECT/REPORTS/HYB_SELECTION/$SM_TAG"_hybridization_selection_metrics.txt" \
PER_TARGET_COVERAGE=$CORE_PATH/$PROJECT/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE/$SM_TAG"_per_target_coverage.txt" \
REFERENCE_SEQUENCE=$REF_GENOME \
BAIT_INTERVALS=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".OnBait.picard.bed" \
TARGET_INTERVALS=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".OnTarget.picard.bed" \
MINIMUM_MAPPING_QUALITY=20 \
MINIMUM_BASE_QUALITY=10 \
BAIT_SET_NAME=$BAIT_NAME \
VALIDATION_STRINGENCY=SILENT \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS