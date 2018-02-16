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
DBSNP=$7
CHROMOSOME=$8

START_GENOTYPE_GVCF=`date '+%s'`

$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T GenotypeGVCFs \
-R $REF_GENOME \
--dbsnp $DBSNP \
--disable_auto_index_creation_and_locking_when_reading_rods \
-G Standard \
-G AS_Standard \
-L $CHROMOSOME \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".QC_RAW_OnBait.vcf.gz"

END_GENOTYPE_GVCF=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",I.01,GENOTYPE_GVCF_"$CHROMOSOME","$HOSTNAME","$START_GENOTYPE_GVCF","$END_GENOTYPE_GVCF \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T GenotypeGVCFs \
-R $REF_GENOME \
--dbsnp $DBSNP \
--disable_auto_index_creation_and_locking_when_reading_rods \
-G Standard \
-G AS_Standard \
-L $CHROMOSOME \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz" \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".QC_RAW_OnBait.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".QC_RAW_OnBait.vcf.gz.tbi"
