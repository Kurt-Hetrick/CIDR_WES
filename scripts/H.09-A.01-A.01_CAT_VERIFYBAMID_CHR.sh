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

CORE_PATH=$1
DATAMASH_DIR=$2

PROJECT=$3
SM_TAG=$4
TARGET_BED=$5

# REMOVE SEMICOLON BEFORE DO?

echo \
>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt"

for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED | sed -r 's/[[:space:]]+/\t/g' | cut -f 1 | sort | uniq | $DATAMASH_DIR/datamash collapse 1 | sed 's/,/ /g');
do
cat $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".selfSM" \
| grep -v ^# \
| awk 'BEGIN {OFS="\t"} {print($1,"'$CHROMOSOME'",$7,$4,$8,$9,$6)}' \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt"
done

sed -i '/^\s*$/d' $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt"

(awk '$2~/^[0-9]/' $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt" | sort -k2,2n ; \
awk '$2=="X"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt" ; \
awk '$2=="Y"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt" ; \
awk '$2=="MT"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_unsorted.txt") \
>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_joined.txt"

echo "#SM_TAG" CHROM VERIFYBAM_FREEMIX VERIFYBAM_SNPS VERIFYBAM_FREELK1 VERRIFYBAM_FREELK0 VERIFYBAM_AVG_DP \
>| $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID_CHR/$SM_TAG".VERIFYBAMID.PER_CHR.txt"

cat $CORE_PATH/$PROJECT/TEMP/$SM_TAG".verifybamID_joined.txt" \
>> $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID_CHR/$SM_TAG".VERIFYBAMID.PER_CHR.txt"

sed -i 's/ /\t/g' $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID_CHR/$SM_TAG".VERIFYBAMID.PER_CHR.txt"
