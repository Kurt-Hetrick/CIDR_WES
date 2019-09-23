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

# INPUT VARIABLES

	JAVA_1_8=$1
	GATK_DIR=$2
	CORE_PATH=$3
	TARGET_BED=$4
		TARGET_BED_NAME=(`basename $TARGET_BED .bed`)
	GENE_LIST=$5
	
	PROJECT=$6
	SM_TAG=$7
	REF_GENOME=$8
	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=(`basename $SAMPLE_SHEET .csv`)
	SUBMIT_STAMP={$10}

### --Depth of Coverage On Target--

START_DOC_TARGET=`date '+%s'`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T DepthOfCoverage \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	--reference_sequence $REF_GENOME \
	--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
	-geneList:REFSEQ $GENE_LIST \
	--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
	-mmq 20 \
	-mbq 10 \
	--outputFormat csv \
	-omitBaseOutput \
	-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED" \
	-ct 10 \
	-ct 15 \
	-ct 20 \
	-ct 30 \
	-ct 50

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

END_DOC_TARGET=`date '+%s'`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,DOC_TARGET,"$HOSTNAME","$START_DOC_TARGET","$END_DOC_TARGET \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T DepthOfCoverage \
--disable_auto_index_creation_and_locking_when_reading_rods \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-geneList:REFSEQ $GENE_LIST \
--intervals $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"TARGET_BED_NAME".bed" \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED" \
-ct 10 \
-ct 15 \
-ct 20 \
-ct 30 \
-ct 50 \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_cumulative_coverage_counts" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_cumulative_coverage_counts.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_cumulative_coverage_proportions" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_cumulative_coverage_proportions.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_gene_summary" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_gene_summary.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_interval_statistics" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_interval_statistics.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_interval_summary" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_interval_summary.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_statistics" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_statistics.csv"

#####

	mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_summary" \
	$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/TARGET/$SM_TAG".TARGET_BED.sample_summary.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS
