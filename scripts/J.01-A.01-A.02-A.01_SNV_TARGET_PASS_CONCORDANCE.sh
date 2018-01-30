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

CIDRSEQSUITE_6_JAVA_DIR=$1
CIDRSEQSUITE_6_1_1_DIR=$2
VERACODE_CSV=$3

CORE_PATH=$4
PROJECT=$5
SM_TAG=$6
TARGET_BED=$7

mkdir -p $CORE_PATH/$PROJECT/TEMP/$SM_TAG

zcat $CORE_PATH/$PROJECT/SNV/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnTarget_SNV.vcf.gz" \
>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_QC_OnTarget_SNV.vcf"

$CIDRSEQSUITE_6_JAVA_DIR/java -jar \
$CIDRSEQSUITE_6_1_1_DIR/CIDRSeqSuite.jar \
-pipeline -concordance \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG \
$CORE_PATH/$PROJECT/Pretesting/Final_Genotyping_Reports/ \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG \
$TARGET_BED \
$VERACODE_CSV

mv $CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_concordance.csv" \
$CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_concordance.csv"

mv $CORE_PATH/$PROJECT/TEMP/$SM_TAG/missing_data.csv \
$CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_missing_data.csv"

mv $CORE_PATH/$PROJECT/TEMP/$SM_TAG/discordant_data.csv \
$CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_discordant_calls.txt"
