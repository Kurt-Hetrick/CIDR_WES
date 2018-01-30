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
TARGET_BED=$7

## -----CONCATENATE SCATTERED g.vcf FILES INTO A SINGLE GRCh37 reference sorted g.vcf file-----

# Start with creating a *list file, reference sorted, to put into --variant.
# Assumption is that this is a correctly sorted GRCh37 reference file as the input reference used

# Put the autosome into a file, sort numerically

sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
| sed -r 's/[[:space:]]+/\t/g' \
| cut -f 1 \
| sort \
| uniq \
| awk '$1~/^[0-9]/' \
| sort -k1,1n \
| awk '{print "'$CORE_PATH'" "/" "'$PROJECT'" "/TEMP/" "'$SM_TAG'" "."$1".g.vcf.gz"}' >| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list"

# Append X if present

sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
| sed -r 's/[[:space:]]+/\t/g' \
| cut -f 1 \
| sort \
| uniq \
| awk '$1=="X"' \
| awk '{print "'$CORE_PATH'" "/" "'$PROJECT'" "/TEMP/" "'$SM_TAG'" "."$1".g.vcf.gz"}' >> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list"

# Append Y if present

sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
| sed -r 's/[[:space:]]+/\t/g' \
| cut -f 1 \
| sort \
| uniq \
| awk '$1=="Y"' \
| awk '{print "'$CORE_PATH'" "/" "'$PROJECT'" "/TEMP/" "'$SM_TAG'" "."$1".g.vcf.gz"}' >> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list"

# Append MT if present

sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
| sed -r 's/[[:space:]]+/\t/g' \
| cut -f 1 \
| sort \
| uniq \
| awk '$1=="MT"' \
| awk '{print "'$CORE_PATH'" "/" "'$PROJECT'" "/TEMP/" "'$SM_TAG'" "."$1".g.vcf.gz"}' >> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list"

## Gather the per chromosome gvcf files

START_HAPLOTYPE_CALLER_GATHER=`date '+%s'`

$JAVA_1_8/java -cp $GATK_DIR/GenomeAnalysisTK.jar \
org.broadinstitute.gatk.tools.CatVariants \
-R $REF_GENOME \
--assumeSorted \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list" \
--outputFile $CORE_PATH/$PROJECT/GVCF/$SM_TAG".g.vcf.gz"

END_HAPLOTYPE_CALLER_GATHER=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",H.01-A.01,HAPLOTYPE_CALLER_GATHER,"$HOSTNAME","$START_HAPLOTYPE_CALLER_GATHER","$END_HAPLOTYPE_CALLER_GATHER \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -cp $GATK_DIR/GenomeAnalysisTK.jar \
org.broadinstitute.gatk.tools.CatVariants \
-R $REF_GENOME \
--assumeSorted \
--variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG".gvcf.list" \
--outputFile $CORE_PATH/$PROJECT/GVCF/$SM_TAG".g.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
