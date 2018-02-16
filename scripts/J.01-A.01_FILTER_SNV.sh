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

JAVA_1_8=$1
GATK_DIR=$2
CORE_PATH=$3

PROJECT=$4
SM_TAG=$5
REF_GENOME=$6

# Filter to just on SNVS

START_FILTER_SNV=`date '+%s'`

$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T VariantFiltration \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R $REF_GENOME \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_RAW_OnBait_SNV.vcf.gz" \
--filterExpression "QD < 2.0" \
--filterName "QD" \
--filterExpression "MQ < 30.0" \
--filterName "MQ" \
--filterExpression "FS > 40.0" \
--filterName "FS" \
--filterExpression "MQRankSum < -12.5" \
--filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" \
--filterName "ReadPosRankSum" \
--filterExpression "DP < 8.0" \
--filterName "DP" \
--logging_level ERROR \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_SNV_FLAGGED.vcf.gz"

END_FILTER_SNV=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",K.01,FILTER_SNV,"$HOSTNAME","$START_FILTER_SNV","$END_FILTER_SNV \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T VariantFiltration \
--disable_auto_index_creation_and_locking_when_reading_rods \
-R $REF_GENOME \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_RAW_OnBait_SNV.vcf.gz" \
--filterExpression "QD < 2.0" \
--filterName "QD" \
--filterExpression "MQ < 30.0" \
--filterName "MQ" \
--filterExpression "FS > 40.0" \
--filterName "FS" \
--filterExpression "MQRankSum < -12.5" \
--filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" \
--filterName "ReadPosRankSum" \
--filterExpression "DP < 8.0" \
--filterName "DP" \
--logging_level ERROR \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_SNV_FLAGGED.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_OnBait_SNV_FLAGGED.vcf.gz.tbi"
