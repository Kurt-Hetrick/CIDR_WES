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

JAVA_1_8=$1
GATK_DIR=$2
CORE_PATH=$3

PROJECT=$4
SM_TAG=$6
REF_GENOME=$7

## --write out file with new scores, retain old scores, no downsampling

START_FINAL_BAM=`date '+%s'`

$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type PrintReads \
--reference $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
-nct 8 \
--static_quantized_quals 10 \
--static_quantized_quals 20 \
--static_quantized_quals 30 \
--disable_indel_quals \
--emit_original_quals  \
--addOutputSAMProgramRecord \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
-o $CORE_PATH/$PROJECT/BAM/$SM_TAG".bam"

END_FINAL_BAM=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",E.01,FINAL_BAM,"$HOSTNAME","$START_FINAL_BAM","$END_FINAL_BAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type PrintReads \
--reference $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".original.bam" \
-nct 8 \
--static_quantized_quals 10 \
--static_quantized_quals 20 \
--static_quantized_quals 30 \
--disable_indel_quals \
--emit_original_quals  \
--addOutputSAMProgramRecord \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
-o $CORE_PATH/$PROJECT/BAM/$SM_TAG".bam"
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

##### DOING THE md5sum on the bam file outside of GATK ##### Just want to see how long it would take

# START_FINAL_BAM_MD5=`date '+%s'`
# 
# md5sum $CORE_PATH/$PROJECT/$FAMILY/$SM_TAG/BAM/$SM_TAG".bam" \
# >> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".CIDR.Analysis.MD5.txt"
# 
# END_FINAL_BAM_MD5=`date '+%s'`
# 
# echo $SM_TAG"_"$PROJECT",G.01-A.01,FINAL_BAM_MD5,"$HOSTNAME","$START_FINAL_BAM_MD5","$END_FINAL_BAM_MD5 \
# >> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"
# 
# md5sum $CORE_PATH/$PROJECT/$FAMILY/$SM_TAG/BAM/$SM_TAG".bai" \
# >> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".CIDR.Analysis.MD5.txt"
