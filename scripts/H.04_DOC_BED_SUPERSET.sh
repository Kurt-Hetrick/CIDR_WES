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

JAVA_1_8=$1
GATK_DIR=$2
CORE_PATH=$3
BAIT_BED=$4
GENE_LIST=$5

PROJECT=$6
SM_TAG=$7
REF_GENOME=$8

### --Depth of Coverage JOINT CALLING BED FILE--

START_DOC_BAIT=`date '+%s'`

$JAVA_1_8/java -jar \
$GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type DepthOfCoverage \
--disable_auto_index_creation_and_locking_when_reading_rods \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-geneList:REFSEQ $GENE_LIST \
--intervals $BAIT_BED \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-ct 10 \
-ct 15 \
-ct 20 \
-ct 30 \
-ct 50 \
-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET"

END_DOC_BAIT=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,DOC_BAIT,"$HOSTNAME","$START_DOC_BAIT","$END_DOC_BAIT \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar \
$GATK_DIR/GenomeAnalysisTK.jar \
--analysis_type DepthOfCoverage \
--disable_auto_index_creation_and_locking_when_reading_rods \
--reference_sequence $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-geneList:REFSEQ $GENE_LIST \
--intervals $BAIT_BED \
-mmq 20 \
-mbq 10 \
--outputFormat csv \
-omitBaseOutput \
-ct 10 \
-ct 15 \
-ct 20 \
-ct 30 \
-ct 50 \
-o $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_cumulative_coverage_counts" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_cumulative_coverage_counts.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_cumulative_coverage_proportions" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_cumulative_coverage_proportions.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_gene_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_gene_summary.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_interval_statistics" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_interval_statistics.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_interval_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_interval_summary.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_statistics" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_statistics.csv"

#####

mv -v $CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_summary" \
$CORE_PATH/$PROJECT/REPORTS/DEPTH_OF_COVERAGE/BED_SUPERSET/$SM_TAG".BED_SUPERSET.sample_summary.csv"
