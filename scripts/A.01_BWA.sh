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
	PLATFORM=${10}
	LIBRARY_NAME=${11}
	RUN_DATE=${12}
	SM_TAG=${13}
	CENTER=${14}
	SEQUENCER_MODEL=${15}
	REF_GENOME=${16}
	PIPELINE_VERSION=${17}
	BAIT_BED=${18}
	TARGET_BED=${19}
	TITV_BED=${20}

		PLATFORM_UNIT=$FLOWCELL"_"$LANE"_"$INDEX
		BAIT_NAME=$(basename $BAIT_BED .bed)
		TARGET_NAME=$(basename $TARGET_BED .bed)
		TITV_NAME=$(basename $TITV_BED .bed)

# Need to convert data in sample manifest to Iso 8601 date since we are not using bwa mem to populate this.
# Picard AddOrReplaceReadGroups is much more stringent here.

	ISO_8601=`echo $RUN_DATE \
	| awk '{split ($0,DATES,"/"); \
	if (length(DATES[1]) < 2 && length(DATES[2]) < 2) \
	print DATES[3]"-0"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
	else if (length(DATES[1]) < 2 && length(DATES[2]) > 1) \
	print DATES[3]"-0"DATES[1]"-"DATES[2]"T00:00:00-0500"; \
	else if(length(DATES[1]) > 1 && length(DATES[2]) < 2) \
	print DATES[3]"-"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
	else print DATES[3]"-"DATES[1]"-"DATES[2]"T00:00:00-0500"}'`

# -----Alignment and BAM post-processing-----

# look for fastq files. allow fastq.gz and fastq extensions.

	FASTQ_1=`ls $CORE_PATH/$PROJECT/FASTQ/$PLATFORM_UNIT"_1.fastq"*`
	FASTQ_2=`ls $CORE_PATH/$PROJECT/FASTQ/$PLATFORM_UNIT"_2.fastq"*`

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
	RGDS=$BAIT_NAME","$TARGET_NAME","TITV_NAME \
	OUTPUT=$CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam"

END_BWA_MEM=`date '+%s'`

HOSTNAME=`hostname`

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
RGDS=$BAIT_NAME","$TARGET_NAME","TITV_NAME \
OUTPUT=$CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$PLATFORM_UNIT".bam"
