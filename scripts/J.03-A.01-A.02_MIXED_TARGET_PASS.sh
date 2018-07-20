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
	TARGET_BED=$7
		TARGET_BED_NAME=(`basename $TARGET_BED .bed`)

# Filter to just on MIXEDS

START_MIXED_TARGET_PASS=`date '+%s'`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T SelectVariants \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	-R $REF_GENOME \
	--excludeFiltered \
	--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
	--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_MIXED_FLAGGED.vcf.gz" \
	-o $CORE_PATH/$PROJECT/MIXED/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnBait_MIXED.vcf.gz"

END_MIXED_TARGET_PASS=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",L.01,MIXED_TARGET_PASS,"$HOSTNAME","$START_MIXED_TARGET_PASS","$END_MIXED_TARGET_PASS \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R $REF_GENOME \
--excludeFiltered \
--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_MIXED_FLAGGED.vcf.gz" \
-o $CORE_PATH/$PROJECT/MIXED/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnBait_MIXED.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/MIXED/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnBait_MIXED.vcf.gz.tbi"
