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
	GATK_DIR=$2
	CORE_PATH=$3

	PROJECT=$4
	SM_TAG=$5
	REF_GENOME=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$8

# Filter INDELS

START_FILTER_INDEL=`date '+%s'`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T VariantFiltration \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	-R $REF_GENOME \
	--filterExpression "QD < 2.0" \
	--filterName "QD" \
	--filterExpression "FS > 200.0" \
	--filterName "FS_INDEL" \
	--filterExpression "ReadPosRankSum < -20.0" \
	--filterName "ReadPosRankSum_INDEL" \
	--filterExpression "DP < 8.0" \
	--filterName "DP" \
	--logging_level ERROR \
	--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_RAW_OnBait_INDEL.vcf.gz" \
	-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_INDEL_FLAGGED.vcf.gz"

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

END_FILTER_INDEL=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",K.01,FILTER_INDEL,"$HOSTNAME","$START_FILTER_INDEL","$END_FILTER_INDEL \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T VariantFiltration \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R $REF_GENOME \
--filterExpression "QD < 2.0" \
--filterName "QD" \
--filterExpression "FS > 200.0" \
--filterName "FS_INDEL" \
--filterExpression "ReadPosRankSum < -20.0" \
--filterName "ReadPosRankSum_INDEL" \
--filterExpression "DP < 8.0" \
--filterName "DP" \
--logging_level ERROR \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_RAW_OnBait_INDEL.vcf.gz" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_INDEL_FLAGGED.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS
