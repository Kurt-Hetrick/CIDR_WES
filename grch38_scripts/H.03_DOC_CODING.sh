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
	CODING_BED=$4
	GENE_LIST=$5

	PROJECT=$6
	SM_TAG=$7
	REF_GENOME=$8
	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${10}

### --Depth of Coverage ALL UCSC CODING EXONS--

START_DOC_CODING=`date '+%s'`

	$JAVA_1_8/java -jar \
	$GATK_DIR/GenomeAnalysisTK.jar \
	--analysis_type DepthOfCoverage \
	--disable_auto_index_creation_and_locking_when_reading_rods \
	--reference_sequence $REF_GENOME \
	--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
	-geneList:REFSEQ $GENE_LIST \
	--intervals $CODING_BED \
	-mmq 20 \
	-mbq 10 \
	--outputFormat csv \
	-omitBaseOutput \
	-ct 10 \
	-ct 15 \
	-ct 20 \
	-ct 30 \
	-ct 50 \
	-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

		if [ "$SCRIPT_STATUS" -ne 0 ]
		 then
			echo $SM_TAG $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
			>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"
			exit $SCRIPT_STATUS
		fi

END_DOC_CODING=`date '+%s'`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,DOC_CODING,"$HOSTNAME","$START_DOC_CODING","$END_DOC_CODING \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar \
$GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type DepthOfCoverage \
--disable_auto_index_creation_and_locking_when_reading_rods \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-geneList:REFSEQ $GENE_LIST \
--intervals $CODING_BED \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-ct 10 \
-ct 15 \
-ct 20 \
-ct 30 \
-ct 50 \
-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_cumulative_coverage_counts" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_cumulative_coverage_counts.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_cumulative_coverage_proportions" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_cumulative_coverage_proportions.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_gene_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_gene_summary.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_interval_statistics" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_interval_statistics.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_interval_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_interval_summary.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_statistics" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_statistics.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/UCSC/$SM_TAG".UCSC_CODING.sample_summary.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS
