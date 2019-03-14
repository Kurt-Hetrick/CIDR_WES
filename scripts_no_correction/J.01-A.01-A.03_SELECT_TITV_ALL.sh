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
	TITV_BED=$7
		TITV_BED_NAME=(`basename $TITV_BED_NAME .bed`)

# Filter to just on SNVS

START_SELECT_TITV_ALL=`date '+%s'`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T SelectVariants \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	-R $REF_GENOME \
	--excludeFiltered \
	--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TITV_BED_NAME".bed" \
	--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_SNV_FLAGGED.vcf.gz" \
	-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_QC_TiTv_All.vcf.gz"

END_SELECT_TITV_ALL=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",L.01,SELECT_TITV_ALL,"$HOSTNAME","$START_SELECT_TITV_ALL","$END_SELECT_TITV_ALL \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T SelectVariants \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R $REF_GENOME \
--excludeFiltered \
--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TITV_BED_NAME".bed" \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_SNV_FLAGGED.vcf.gz" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_QC_TiTv_All.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_QC_TiTv_All.vcf.gz.tbi"
