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

JAVA_1_8=$1
GATK_DIR=$2
CORE_PATH=$3

PROJECT=$4
SM_TAG=$5
REF_GENOME=$6

## --write out bam file with a 4 bin qscore scheme, remove indel Q scores, emit original Q scores

START_FINAL_BAM=`date '+%s'`

$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type PrintReads \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
-nct 8 \
--static_quantized_quals 10 \
--static_quantized_quals 20 \
--static_quantized_quals 30 \
--disable_indel_quals \
--emit_original_quals  \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam"

END_FINAL_BAM=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",E.01,FINAL_BAM,"$HOSTNAME","$START_FINAL_BAM","$END_FINAL_BAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type PrintReads \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
-nct 8 \
--static_quantized_quals 10 \
--static_quantized_quals 20 \
--static_quantized_quals 30 \
--disable_indel_quals \
--emit_original_quals  \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
