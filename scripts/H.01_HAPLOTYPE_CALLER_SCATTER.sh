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
	
	PROJECT=$4
	SM_TAG=$5
	REF_GENOME=$6
	BAIT_BED=$7
		BAIT_BED_NAME=(`basename $BAIT_BED .bed`)
	CHROMOSOME=$8
	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${10}

## -----Haplotype Caller-----

## Call on Bait

START_HAPLOTYPE_CALLER=`date '+%s'`

# Setting read_filter overclipped. this is in broad's wdl.
# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_engine_filters_OverclippedReadFilter.php

# I'm pushing the freemix value to the contamination fraction

FREEMIX=`awk 'NR==2 {print $7}' $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID/$SM_TAG".selfSM"`

	$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
	-T HaplotypeCaller \
	-R $REF_GENOME \
	--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
	-L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"BAIT_BED_NAME".bed" \
	-L $CHROMOSOME \
	--interval_set_rule INTERSECTION \
	--variant_index_type LINEAR \
	--variant_index_parameter 128000 \
	--emitRefConfidence GVCF \
	--max_alternate_alleles 3 \
	-pairHMM VECTOR_LOGLESS_CACHING \
	--read_filter OverclippedRead \
	--annotation AS_BaseQualityRankSumTest \
	--annotation AS_FisherStrand \
	--annotation AS_MappingQualityRankSumTest \
	--annotation AS_RMSMappingQuality \
	--annotation AS_ReadPosRankSumTest \
	--annotation AS_StrandOddsRatio \
	--annotation FractionInformativeReads \
	--annotation StrandBiasBySample \
	--annotation StrandAlleleCountsBySample \
	--annotation AlleleBalanceBySample \
	--annotation AlleleBalance \
	--emitDroppedReads \
	-bamout $CORE_PATH/$PROJECT/TEMP/$SM_TAG".HC."$CHROMOSOME".bam" \
	--contamination_fraction_to_filter $FREEMIX \
	-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz"

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

END_HAPLOTYPE_CALLER=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT,H.01,HAPLOTYPE_CALLER_$CHROMOSOME,$HOSTNAME,$START_HAPLOTYPE_CALLER,$END_HAPLOTYPE_CALLER \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T HaplotypeCaller \
-R $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-L $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"BAIT_BED_NAME".bed" \
-L $CHROMOSOME \
--interval_set_rule INTERSECTION \
--variant_index_type LINEAR \
--variant_index_parameter 128000 \
--emitRefConfidence GVCF \
--max_alternate_alleles 3 \
-pairHMM VECTOR_LOGLESS_CACHING \
--read_filter OverclippedRead \
--annotation AS_BaseQualityRankSumTest \
--annotation AS_FisherStrand \
--annotation AS_MappingQualityRankSumTest \
--annotation AS_RMSMappingQuality \
--annotation AS_ReadPosRankSumTest \
--annotation AS_StrandOddsRatio \
--annotation FractionInformativeReads \
--annotation StrandBiasBySample \
--annotation StrandAlleleCountsBySample \
--annotation AlleleBalanceBySample \
--annotation AlleleBalance \
--emitDroppedReads \
-bamout $CORE_PATH/$PROJECT/TEMP/$SM_TAG".HC."$CHROMOSOME".bam" \
--contamination_fraction_to_filter $FREEMIX \
-o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz" \
>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG".COMMAND.LINES.txt"

# if file is not present exit !=0

ls $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf.gz.tbi"
