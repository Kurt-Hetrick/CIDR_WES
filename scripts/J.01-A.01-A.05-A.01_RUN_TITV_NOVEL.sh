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

SAMTOOLS_0118_DIR=$1
CORE_PATH=$2

PROJECT=$3
SM_TAG=$4

# Filter to just on SNVS

START_RUN_TITV_NOVEL=`date '+%s'`

zcat $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_QC_TiTv_Novel.vcf.gz" \
| $SAMTOOLS_0118_DIR/bcftools/vcfutils.pl \
qstats \
/dev/stdin \
>| $CORE_PATH/$PROJECT/REPORTS/TI_TV/$SM_TAG"_Novel_.titv.txt"

END_RUN_TITV_NOVEL=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",M.01,RUN_TITV_NOVEL,"$HOSTNAME","$START_RUN_TITV_NOVEL","$END_RUN_TITV_NOVEL \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/REPORTS/TI_TV/$SM_TAG"_Novel_.titv.txt"
