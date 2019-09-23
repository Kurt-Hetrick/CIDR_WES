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
	PICARD_DIR=$2
	CORE_PATH=$3

	PROJECT=$4
	SM_TAG=$5
	INPUT_BAM_FILE_STRING=$6

		INPUT=`echo $INPUT_BAM_FILE_STRING | sed 's/,/ /g'`
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$8

		RIS_ID=${SM_TAG%@*}
		BARCODE_2D=${SM_TAG#*@}

## --Merge and Sort Bam files--

START_MERGE_BAM=`date '+%s'`

	$JAVA_1_8/java -jar $PICARD_DIR/picard.jar MergeSamFiles \
	$INPUT \
	OUTPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
	VALIDATION_STRINGENCY=SILENT \
	SORT_ORDER=coordinate \
	USE_THREADING=true \
	CREATE_INDEX=true

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				echo $SM_TAG $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
				>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.csv"
				exit $SCRIPT_STATUS
			fi

END_MERGE_BAM=`date '+%s'`

echo $SM_TAG"_"$PROJECT",B.01,MERGE_BAM,"$HOSTNAME","$START_MERGE_BAM","$END_MERGE_BAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.txt"

echo $JAVA_1_8/java -jar $PICARD_DIR/MergeSamFiles.jar \
$INPUT \
OUTPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
VALIDATION_STRINGENCY=SILENT \
SORT_ORDER=coordinate \
USE_THREADING=true \
CREATE_INDEX=true \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS
