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

PROJECT=$4
SM_TAG=$5
REF_GENOME=$6
BAIT_BED=$7
CHROMOSOME=$8

## -----Haplotype Caller-----

## Call on Bait

START_HAPLOTYPE_CALLER=`date '+%s'`

# I'm Adding more annotations so I want this year for the moment in case things start crashing.

# $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
# -T HaplotypeCaller \
# -R $REF_GENOME \
# --input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
# -L $BAIT_BED \
# -L $CHROMOSOME \
# --interval_set_rule INTERSECTION \
# --variant_index_type LINEAR \
# --variant_index_parameter 128000 \
# --max_alternate_alleles 3 \
# --annotation FractionInformativeReads \
# --annotation StrandBiasBySample \
# --annotation StrandAlleleCountsBySample \
# --annotation AlleleBalanceBySample \
# --annotation AlleleBalance \
# -pairHMM VECTOR_LOGLESS_CACHING \
# -o $CORE_PATH/$PROJECT/TEMP/$SM_TAG"."$CHROMOSOME".g.vcf"

# Setting read_filter overclipped. this is in broad's wdl.
# not sure if it going to do anything extra, but we'll see.
# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_engine_filters_OverclippedReadFilter.php
# I'm struggling to think if I should use the bamout argument here.

# I'm pushing the freemix value to the contamination fraction

FREEMIX=`awk 'NR==2 {print $7}' $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID/$SM_TAG".selfSM"`

$JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T HaplotypeCaller \
-R $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-L $BAIT_BED \
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

END_HAPLOTYPE_CALLER=`date '+%s'`

HOSTNAME=`hostname`

echo $SM_TAG"_"$PROJECT,H.01,HAPLOTYPE_CALLER_$CHROMOSOME,$HOSTNAME,$START_HAPLOTYPE_CALLER,$END_HAPLOTYPE_CALLER \
>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

echo $JAVA_1_8/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T HaplotypeCaller \
-R $REF_GENOME \
--input_file $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" \
-L $BAIT_BED \
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
