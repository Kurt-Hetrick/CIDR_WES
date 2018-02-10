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
GATK_DIR_4011=$2
CORE_PATH=$3

PROJECT=$4
SM_TAG=$5
REF_GENOME=$6
KNOWN_INDEL_1=$7
KNOWN_INDEL_2=$8
DBSNP=$9
BAIT_BED=${10}

## --Generate post BQSR table--
## SEEMS DIFFERENT THAN GATK 3. NO PRE AND POST BQSR TABLE COMMANDS...

START_AFTER_BQSR=`date '+%s'`

$JAVA_1_8/java -jar \
$GATK_DIR_4011/gatk-package-4.0.1.1-local.jar \
BaseRecalibrator \
--input $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
--reference $REF_GENOME \
--known-sites $KNOWN_INDEL_1 \
--known-sites $KNOWN_INDEL_2 \
--known-sites $DBSNP \
--intervals $BAIT_BED \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
--output $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_AFTER_BQSR.bqsr"


END_AFTER_BQSR=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,AFTER_BQSR,"$HOSTNAME","$START_AFTER_BQSR","$END_AFTER_BQSR \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type BaseRecalibrator \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
--reference_sequence $REF_GENOME \
-knownSites $KNOWN_INDEL_1 \
-knownSites $KNOWN_INDEL_2 \
-knownSites $DBSNP \
--intervals $BAIT_BED \
-nct 8 \
-BQSR $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_PERFORM_BQSR.bqsr" \
-o $CORE_PATH/$PROJECT/REPORTS/COUNT_COVARIATES/GATK_REPORT/$SM_TAG"_AFTER_BQSR.bqsr" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
