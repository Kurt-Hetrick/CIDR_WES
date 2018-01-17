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

CORE_PATH=$1

PROJECT=$2
SM_TAG=$3

## do md5sum on the cram file

START_MD5SUM_CRAM=`date '+%s'`

md5sum $CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram" \
>> $CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram.md5"

END_MD5SUM_CRAM=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT",G.01,MD5SUM_CRAM,"$HOSTNAME","$START_MD5SUM_CRAM","$END_MD5SUM_CRAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"
