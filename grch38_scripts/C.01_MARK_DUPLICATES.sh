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

# INPUT VARIABLES

	JAVA_1_8=$1
	PICARD_DIR=$2
	SAMBAMBA_DIR=$3
	CORE_PATH=$4

	PROJECT=$5
	SM_TAG=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$8

	INPUT_BAM_FILE_STRING=$9
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
\| $SAMBAMBA_DIR/sambamba \
sort \
-t 4 \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
/dev/stdin \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt"
