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

# INPUT VARIABLES

	SAMTOOLS_DIR=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=(`basename $SAMPLE_SHEET .csv`)
	SUBMIT_STAMP=$6

## --Mark Duplicates with Picard, write a duplicate report
## todo; have pixel distance be a input parameter with a switch based on the description in the sample sheet.

START_REHEAD_BAM=`date '+%s'`

# start grabbing the header and put it into a file.
	# GRAB THE HD AND SQ GROUPS FIRST.

		$SAMTOOLS_DIR/samtools \
		view -H \
		$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
		| egrep "^@HD|^@SQ" \
		>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fix.header.txt"

	# NOW GRAB THE RG HEADER AND THE PM TAG TO THE END OF THEM

	# grab field number for PLATFORM_UNIT_TAG

			PU_FIELD=(`$SAMTOOLS_DIR/samtools view -H \
			$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
				| grep -m 1 ^@RG \
				| sed 's/\t/\n/g' \
				| cat -n \
				| sed 's/^ *//g' \
				| awk '$2~/^PU:/ {print $1}'`)

			# Grab the @RG header from the platform unit bam files for the sample to add to the header.

			for PLATFORM_UNIT in $($SAMTOOLS_DIR/samtools view -H \
								$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
									| grep ^@RG \
									| cut -f $PU_FIELD \
									| cut -d ":" -f 2);
				do
					$SAMTOOLS_DIR/samtools view -H \
					$CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam" \
					| grep ^@RG \
					>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fix.header.txt"
				done

	# ADD THE PG TAGS

		$SAMTOOLS_DIR/samtools \
		view -H \
		$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
		| egrep "^@PG" \
		>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fix.header.txt"

			# check the exit signal at this point.

				SCRIPT_STATUS=`echo $?`

				# if exit does not equal 0 then exit with whatever the exit signal is at the end.
				# also write to file that this job failed

					if [ "$SCRIPT_STATUS" -ne 0 ]
					 then
						echo $SAMPLE $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
						>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"
						exit $SCRIPT_STATUS
					fi

		# NOW FIX THE BAM HEADER

				$SAMTOOLS_DIR/samtools \
				reheader \
				$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fix.header.txt" \
				$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
				>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fixed.bam"

				# And index the bam

					$SAMTOOLS_DIR/samtools \
					index \
					$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fixed.bam"

END_REHEAD_BAM=`date '+%s'`

HOSTNAME=`hostname`

# grab the times stamps and save to file

echo $SM_TAG"_"$PROJECT",C.01-1,REHEAD_BAM,"$HOSTNAME","$START_REHEAD_BAM","$END_REHEAD_BAM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# echo command lines to file

echo $SAMTOOLS_DIR/samtools \
reheader \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fix.header.txt" \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.bam" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo $SAMTOOLS_DIR/samtools \
index \
$CORE_PATH/$PROJECT/TEMP/$SM_TAG".dup.fixed.bam" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# exit with the signal from the program

	exit $SCRIPT_STATUS
