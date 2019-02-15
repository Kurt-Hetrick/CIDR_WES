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

	BWA_DIR=$1
	SAMBLASTER_DIR=$2
	JAVA_1_8=$3
	PICARD_DIR=$4

	CORE_PATH=$5
	PROJECT=$6
	FLOWCELL=$7
	LANE=$8
	INDEX=$9
		PLATFORM_UNIT=$FLOWCELL"_"$LANE"_"$INDEX
	PLATFORM=${10}
	LIBRARY_NAME=${11}
	RUN_DATE=${12}
	SM_TAG=${13}
	CENTER=${14}
	SEQUENCER_MODEL=${15}
	REF_GENOME=${16}
	PIPELINE_VERSION=${17}
	BAIT_BED=${18}
		BAIT_NAME=$(basename $BAIT_BED .bed)
	TARGET_BED=${19}
		TARGET_NAME=$(basename $TARGET_BED .bed)
	TITV_BED=${20}
		TITV_NAME=$(basename $TITV_BED .bed)
	SAMPLE_SHEET=${21}
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${22}
	NOVASEQ_REPO=${23}

# Need to convert data in sample manifest to Iso 8601 date since we are not using bwa mem to populate this.
# Picard AddOrReplaceReadGroups is much more stringent here.

	if [[ $RUN_DATE = *"-"* ]];
		then

			# for when the date is this 2018-09-05

				ISO_8601=`echo $RUN_DATE \
					| awk '{print "'$RUN_DATE'" "T00:00:00-0500"}'`

		else

			# for when the data is like this 4/26/2018

				ISO_8601=`echo $RUN_DATE \
					| awk '{split ($0,DATES,"/"); \
					if (length(DATES[1]) < 2 && length(DATES[2]) < 2) \
					print DATES[3]"-0"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
					else if (length(DATES[1]) < 2 && length(DATES[2]) > 1) \
					print DATES[3]"-0"DATES[1]"-"DATES[2]"T00:00:00-0500"; \
					else if(length(DATES[1]) > 1 && length(DATES[2]) < 2) \
					print DATES[3]"-"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
					else print DATES[3]"-"DATES[1]"-"DATES[2]"T00:00:00-0500"}'`
	fi

# look for fastq files. allow fastq.gz and fastq extensions.
# If NovaSeq is contained in the Description field in the sample sheet then assume that ILMN BCL2FASTQ is used.
# Files are supposed to be in /mnt/instrument_files/novaseq/Run_Folder/FASTQ/Project/
# FILENAME-> 137233-0238091146_S49_L002_R1_001.fastq.gz	(SMTAG_ASampleIndexOfSomeSort_4DigitLane_Read_literally001.fastq.gz)
# Otherwise assume that files are demultiplexed with cidrseqsuite and follow previous naming conventions.

	if [[ $SEQUENCER_MODEL == *"NovaSeq"* ]]
		then

			NOVASEQ_RUN_FOLDER=`ls $NOVASEQ_REPO | grep $FLOWCELL`

			FINDPATH=$NOVASEQ_REPO/$NOVASEQ_RUN_FOLDER/FASTQ/$PROJECT

			#Fancy REGEX for R1 and 2 Since we don't have the sample index value in the sample sheet(probably can be cleaned up)
			FASTQ1_REGEX="'.*"$SM_TAG"_[Ss][0-9]+_L00["$LANE"]_R1_001.fastq.gz.*'"
			FASTQ2_REGEX="'.*"$SM_TAG"_[Ss][0-9]+_L00["$LANE"]_R2_001.fastq.gz.*'"

			FASTQ_1="$(echo find "$FINDPATH" -regextype posix-extended -regex "$FASTQ1_REGEX" | bash)"
			FASTQ_2="$(echo find "$FINDPATH" -regextype posix-extended -regex "$FASTQ2_REGEX" | bash)"
		else
			FASTQ_1=`ls $CORE_PATH/$PROJECT/FASTQ/$PLATFORM_UNIT"_1.fastq"*`
			FASTQ_2=`ls $CORE_PATH/$PROJECT/FASTQ/$PLATFORM_UNIT"_2.fastq"*`
	fi

# -----Alignment and BAM post-processing-----

	# bwa mem
	# pipe to samblaster to add MC, etc tags
	# pipe to AddOrReplaceReadGroups to populate the header--

START_BWA_MEM=`date '+%s'`

	$BWA_DIR/bwa mem \
		-K 100000000 \
		-Y \
		-t 4 \
		$REF_GENOME \
		$FASTQ_1 \
		$FASTQ_2 \
	| $SAMBLASTER_DIR/samblaster \
		--addMateTags \
		-a \
	| $JAVA_1_8/java -jar \
	$PICARD_DIR/picard.jar \
	AddOrReplaceReadGroups \
	INPUT=/dev/stdin \
	CREATE_INDEX=true \
	SORT_ORDER=queryname \
	RGID=$FLOWCELL"_"$LANE \
	RGLB=$LIBRARY_NAME \
	RGPL=$PLATFORM \
	RGPU=$PLATFORM_UNIT \
	RGPM=$SEQUENCER_MODEL \
	RGSM=$SM_TAG \
	RGCN=$CENTER \
	RGDT=$ISO_8601 \
	RGPG="CIDR_WES-"$PIPELINE_VERSION \
	RGDS=$BAIT_NAME","$TARGET_NAME","$TITV_NAME \
	OUTPUT=$CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				echo $SAMPLE $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
				>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.csv"
				exit $SCRIPT_STATUS
			fi

END_BWA_MEM=`date '+%s'`

echo $SM_TAG"_"$PROJECT",A.01,BWA_MEM,"$HOSTNAME","$START_BWA_MEM","$END_BWA_MEM \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $BWA_DIR/bwa mem \
-K 100000000 \
-Y \
-t 4 \
$REF_GENOME \
$FASTQ_1 \
$FASTQ_2 \
\| $SAMBLASTER_DIR/samblaster \
--addMateTags \
-a \
\| $JAVA_1_8/java -jar \
$PICARD_DIR/picard.jar \
AddOrReplaceReadGroups \
INPUT=/dev/stdin \
CREATE_INDEX=true \
SORT_ORDER=queryname \
RGID=$FLOWCELL"_"$LANE \
RGLB=$LIBRARY_NAME \
RGPL=$PLATFORM \
RGPU=$PLATFORM_UNIT \
RGPM=$SEQUENCER_MODEL \
RGSM=$SM_TAG \
RGCN=$CENTER \
RGDT=$ISO_8601 \
RGPG="CIDR_WES-"$PIPELINE_VERSION \
RGDS=$BAIT_NAME","$TARGET_NAME","$TITV_NAME \
OUTPUT=$CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam"
