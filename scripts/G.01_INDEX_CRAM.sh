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

## --index the cram file
START_INDEX_CRAM=`date '+%s'`

$SAMTOOLS_DIR/samtools \
index \
$CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram"

END_INDEX_CRAM=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",G.01,INDEX_CRAM,"$HOSTNAME","$START_INDEX_CRAM","$END_INDEX_CRAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $SAMTOOLS_DIR/samtools \
index \
$CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# make a copy/rename the cram index file since their appears to be two useable standards

cp $CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram.crai" \
$CORE_PATH/$PROJECT/CRAM/$SM_TAG".crai"
