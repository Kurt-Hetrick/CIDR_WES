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

	CORE_PATH=$1
	VERIFY_DIR=$2

	PROJECT=$3
	SM_TAG=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$6

## --Running verifyBamID--

START_VERIFYBAMID=`date '+%s'`

	$VERIFY_DIR/verifyBamID \
	--bam $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
	--vcf $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID.vcf" \
	--out $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID/$SM_TAG \
	--precise \
	--verbose \
	--maxDepth 2500

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

END_VERIFYBAMID=`date '+%s'`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,VERIFYBAMID,"$HOSTNAME","$START_VERIFYBAMID","$END_VERIFYBAMID \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $VERIFY_DIR/verifyBamID \
--bam $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
--vcf $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID.vcf" \
--out $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID/$SM_TAG \
--precise \
--verbose \
--maxDepth 2500 \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS
