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

SAMTOOLS_DIR=$1
CORE_PATH=$2

PROJECT=$3
SM_TAG=$4
REF_GENOME=$5

## --write lossless cram file.

START_HC_CRAM=`date '+%s'`

$SAMTOOLS_DIR/samtools \
view \
-C $CORE_PATH/$PROJECT/TEMP/$SM_TAG".HC.bam" \
-T $REF_GENOME \
-@ 4 \
-o $CORE_PATH/$PROJECT/HC_CRAM/$SM_TAG".HC.cram"

END_HC_CRAM=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",H.01-A.01-A.01,HC_CRAM,"$HOSTNAME","$START_HC_CRAM","$END_HC_CRAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $SAMTOOLS_DIR/samtools \
view \
-C $CORE_PATH/$PROJECT/TEMP/$SM_TAG".HC.bam" \
-T $REF_GENOME \
-@ 4 \
-o $CORE_PATH/$PROJECT/HC_CRAM/$SM_TAG".HC.cram" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"
