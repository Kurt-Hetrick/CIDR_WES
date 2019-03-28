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
	VERIFY_DIR=$3
	CORE_PATH=$4
	VERIFY_VCF=$5
	
	PROJECT=$6
	SM_TAG=$7
	REF_GENOME=$8
	TARGET_BED=$9
		TARGET_BED_NAME=(`basename $TARGET_BED .bed`)
	# CHROMOSOME=$9
	SAMPLE_SHEET=${10}
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${11}

# create loop, for now doing this serially as I don't want to play with bandwith issues by doing it in parallel

START_SELECT_VERIFYBAMID_VCF=`date '+%s'`

# function to call 

SELECT_VERIFYBAMID_VCF_CHR ()
	{
		$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
		-T SelectVariants \
		--reference_sequence $REF_GENOME \
		--disable_auto_index_creation_and_locking_when_reading_rods \
		--variant $VERIFY_VCF \
		-L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
		-L $CHROMOSOME \
		-XL chrX \
		-XL chrY \
		--interval_set_rule INTERSECTION \
		-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID."$CHROMOSOME".vcf"
	}

CALL_VERIFYBAMID_CHR ()
	{
		$VERIFY_DIR/verifyBamID \
		--bam $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
		--vcf $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID."$CHROMOSOME".vcf" \
		--out $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME \
		--precise \
		--verbose \
		--maxDepth 2500
	}

for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
	| sed -r 's/[[:space:]]+/\t/g' \
	| cut -f 1 \
	| sed 's/chr//g' \
	| egrep -v "X|Y|MT" \
	| sort \
	| uniq \
	| $DATAMASH_DIR/datamash collapse 1 \
	| sed 's/,/ /g');
	do
		SELECT_VERIFYBAMID_VCF_CHR
		CALL_VERIFYBAMID_CHR
done

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

END_SELECT_VERIFYBAMID_VCF=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.09,SELECT_VERIFYBAMID_"$CHROMOSOME","$HOSTNAME","$START_SELECT_VERIFYBAMID_VCF","$END_SELECT_VERIFYBAMID_VCF \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
# -T SelectVariants \
# --reference_sequence $REF_GENOME \
# --variant $VERIFY_VCF \
# -L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
# -L $CHROMOSOME \
# -XL chrX \
# -XL chrY \
# --interval_set_rule INTERSECTION \
# -o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID."$CHROMOSOME".vcf" \
# >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG".VerifyBamID."$CHROMOSOME".vcf"
ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".selfSM"

exit $SCRIPT_STATUS
