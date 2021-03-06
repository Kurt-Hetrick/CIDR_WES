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
	GATK_DIR=$2
	CORE_PATH=$3
	VERIFY_VCF=$4
	
	PROJECT=$5
	SM_TAG=$6
	REF_GENOME=$7
	TARGET_BED=$8
		TARGET_BED_NAME=(`basename $TARGET_BED_NAME .bed`)
	# so the above command is a bug...that I don't think I am going to fix ;)
	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${10}

## --Creating an on the fly VCF file to be used as the reference for verifyBamID--
## --remove X, Y and MT data

START_SELECT_VERIFYBAMID_VCF=`date '+%s'`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T SelectVariants \
	--reference_sequence $REF_GENOME \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	--variant $VERIFY_VCF \
	-L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
	-XL X \
	-XL Y \
	-XL MT \
	-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID.vcf"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

		if [ "$SCRIPT_STATUS" -ne 0 ]
		 then
			echo $SM_TAG $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
			>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"
			exit $SCRIPT_STATUS
		fi

END_SELECT_VERIFYBAMID_VCF=`date '+%s'`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,SELECT_VERIFYBAMID_VCF,"$HOSTNAME","$START_SELECT_VERIFYBAMID_VCF","$END_SELECT_VERIFYBAMID_VCF \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
--reference_sequence $REF_GENOME \
--variant $VERIFY_VCF \
-L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
-XL X \
-XL Y \
-XL MT \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID.vcf" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS
