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
CIDRSEQSUITE_7_5_0_DIR=$2
VERACODE_CSV=$3

CORE_PATH=$4
PROJECT=$5
SM_TAG=$6
TARGET_BED=$7

# mkdir a directory in TEMP for the SM tag to decompress the target vcf file into

mkdir -p $CORE_PATH/$PROJECT/TEMP/$SM_TAG

# decompress the target vcf file into the temporary sub-folder

zcat $CORE_PATH/$PROJECT/SNV/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnTarget_SNV.vcf.gz" \
>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_QC_OnTarget_SNV.vcf"

# look for a final report and store it as a variable

FINAL_REPORT_FILE_TEST=$(ls $CORE_PATH/$PROJECT/Pretesting/Final_Genotyping_Reports/*$SM_TAG*)

# if final report exists containing the full sm-tag, then cidrseqsuite magic

if [[ ! -z "$FINAL_REPORT_FILE_TEST" ]]

then
FINAL_REPORT=$FINAL_REPORT_FILE_TEST

# if it does not exist, then look for the string before the delimeter (either a @ or -), take the first element
# look for a final report that contains that
# the assumption will be that this will happen when...hmmm...maybe i should not be making this assumption

else

HAPMAP=${SM_TAG%[@-]*}

FINAL_REPORT=$(ls $CORE_PATH/$PROJECT/Pretesting/Final_Genotyping_Reports/*$HAPMAP* | head -n 1)

fi

# -single_sample_concordance
# Performs concordance between one vcf file and one final report. The vcf must be single sample.
# [1] path_to_vcf_file
# [2] path_to_final_report_file
# [3] path_to_bed_file
# [4] path_to_liftover_file
# [5] path_to_output_directory

$JAVA_1_8/java -jar \
$CIDRSEQSUITE_7_5_0_DIR/CIDRSeqSuite.jar \
-single_sample_concordance \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_QC_OnTarget_SNV.vcf" \
$FINAL_REPORT \
$TARGET_BED \
$VERACODE_CSV \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG

echo \
$JAVA_1_8/java -jar \
$CIDRSEQSUITE_7_5_0_DIR/CIDRSeqSuite.jar \
-single_sample_concordance \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_QC_OnTarget_SNV.vcf" \
$FINAL_REPORT \
$TARGET_BED \
$VERACODE_CSV \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG \
>> 

mv $CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_concordance.csv" \
$CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_concordance.csv"

mv $CORE_PATH/$PROJECT/TEMP/$SM_TAG/$SM_TAG"_discordant_calls.txt" \
$CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_discordant_calls.txt"