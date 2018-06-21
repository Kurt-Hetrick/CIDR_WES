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

CORE_PATH=$1
DATAMASH=$2

PROJECT=$3

SAMPLE_SHEET=$4

TIMESTAMP=`date '+%F.%H-%M-%S'`

# combining all the individual qc reports for the project and adding the header.

cat $CORE_PATH/$PROJECT/REPORTS/QC_REPORT_PREP/*.QC_REPORT_PREP.txt \
| awk 'BEGIN {print "PROJECT",\
"SM_TAG",\
"RG_PU",\
"LIBRARY",\
"LIBRARY_PLATE",\
"LIBRARY_WELL",\
"LIBRARY_ROW",\
"LIBRARY_COLUMN",\
"HYB_PLATE",\
"HYB_WELL",\
"HYB_ROW",\
"HYB_COLUMN",\
"X_AVG_DP",\
"X_NORM_DP",\
"Y_AVG_DP",\
"Y_NORM_DP",\
"COUNT_DISC_HOM",\
"COUNT_CONC_HOM",\
"PERCENT_CONC_HOM",\
"COUNT_DISC_HET",\
"COUNT_CONC_HET",\
"PERCENT_CONC_HET",\
"PERCENT_TOTAL_CONC",\
"COUNT_HET_BEADCHIP",\
"SENSITIVITY_2_HET",\
"SNP_ARRAY",\
"VERIFYBAM_FREEMIX_PCT",\
"VERIFYBAM_#SNPS",\
"VERIFYBAM_FREELK1",\
"VERIFYBAM_FREELK0",\
"VERIFYBAM_DIFF_LK0_LK1",\
"VERIFYBAM_AVG_DP",\
"MEDIAN_INSERT_SIZE",\
"MEAN_INSERT_SIZE",\
"STANDARD_DEVIATION_INSERT_SIZE",\
"MAD_INSERT_SIZE",\
"PCT_PF_READS_ALIGNED_R1",\
"PF_HQ_ALIGNED_READS_R1",\
"PF_HQ_ALIGNED_Q20_BASES_R1",\
"PF_MISMATCH_RATE_R1",\
"PF_HQ_ERROR_RATE_R1",\
"PF_INDEL_RATE_R1",\
"PCT_READS_ALIGNED_IN_PAIRS_R1",\
"PCT_ADAPTER_R1",\
"PCT_PF_READS_ALIGNED_R2",\
"PF_HQ_ALIGNED_READS_R2",\
"PF_HQ_ALIGNED_Q20_BASES_R2",\
"PF_MISMATCH_RATE_R2",\
"PF_HQ_ERROR_RATE_R2",\
"PF_INDEL_RATE_R2",\
"PCT_READS_ALIGNED_IN_PAIRS_R2",\
"PCT_ADAPTER_R2",\
"TOTAL_READS",\
"RAW_GIGS",\
"PCT_PF_READS_ALIGNED_PAIR",\
"PF_MISMATCH_RATE_PAIR",\
"PF_HQ_ERROR_RATE_PAIR",\
"PF_INDEL_RATE_PAIR",\
"PCT_READS_ALIGNED_IN_PAIRS_PAIR",\
"STRAND_BALANCE_PAIR",\
"PCT_CHIMERAS_PAIR",\
"PF_HQ_ALIGNED_Q20_BASES_PAIR",\
"MEAN_READ_LENGTH",\
"PCT_PF_READS_IMPROPER_PAIRS_PAIR",\
"UNMAPPED_READS",\
"READ_PAIR_OPTICAL_DUPLICATES",\
"PERCENT_DUPLICATION",\
"ESTIMATED_LIBRARY_SIZE",\
"SECONDARY_OR_SUPPLEMENTARY_READS",\
"READ_PAIR_DUPLICATES",\
"READ_PAIRS_EXAMINED",\
"PAIRED_DUP_RATE",\
"UNPAIRED_READ_DUPLICATES",\
"UNPAIRED_READS_EXAMINED",\
"UNPAIRED_DUP_RATE",\
"GENOME_SIZE",\
"BAIT_TERRITORY",\
"TARGET_TERRITORY",\
"PCT_PF_UQ_READS_ALIGNED",\
"PF_UQ_GIGS_ALIGNED",\
"PCT_SELECTED_BASES",\
"ON_BAIT_VS_SELECTED",\
"MEAN_BAIT_COVERAGE",\
"MEAN_TARGET_COVERAGE",\
"MEDIAN_TARGET_COVERAGE",\
"MAX_TARGET_COVERAGE",\
"ZERO_CVG_TARGETS_PCT",\
"PCT_EXC_MAPQ",\
"PCT_EXC_BASEQ",\
"PCT_EXC_OVERLAP",\
"PCT_EXC_OFF_TARGET",\
"PCT_TARGET_BASES_1X",\
"PCT_TARGET_BASES_2X",\
"PCT_TARGET_BASES_10X",\
"PCT_TARGET_BASES_20X",\
"PCT_TARGET_BASES_30X",\
"PCT_TARGET_BASES_40X",\
"PCT_TARGET_BASES_50X",\
"PCT_TARGET_BASES_100X",\
"HS_LIBRARY_SIZE",\
"AT_DROPOUT",\
"GC_DROPOUT",\
"THEORETICAL_HET_SENSITIVITY",\
"HET_SNP_Q",\
"BAIT_SET",\
"PCT_USABLE_BASES_ON_BAIT",\
"Cref_Q",\
"Gref_Q",\
"DEAMINATION_Q",\
"OxoG_Q",\
"COUNT_SNV_ON_BAIT",\
"PERCENT_SNV_ON_BAIT_SNP138",\
"COUNT_SNV_ON_TARGET",\
"PERCENT_SNV_ON_TARGET_SNP138",\
"HET:HOM_TARGET",\
"ALL_TI_TV_COUNT",\
"ALL_TI_TV_RATIO",\
"KNOWN_TI_TV_COUNT",\
"KNOWN_TI_TV_RATIO",\
"NOVEL_TI_TV_COUNT",\
"NOVEL_TI_TV_RATIO",\
"COUNT_ALL_INDEL_BAIT",\
"ALL_INDEL_BAIT_PCT_SNP138",\
"COUNT_BIALLELIC_INDEL_BAIT",\
"BIALLELIC_INDEL_BAIT_PCT_SNP138",\
"COUNT_ALL_INDEL_TARGET",\
"ALL_INDEL_TARGET_PCT_SNP138",\
"COUNT_BIALLELIC_INDEL_TARGET",\
"BIALLELIC_INDEL_TARGET_PCT_SNP138",\
"BIALLELIC_ID_RATIO",\
"COUNT_MIXED_ON_BAIT",\
"PERCENT_MIXED_ON_BAIT_SNP138",\
"COUNT_MIXED_ON_TARGET",\
"PERCENT_MIXED_ON_TARGET_SNP138"} \
{print $0}' \
| sed 's/ /,/g' \
| sed 's/\t/,/g' \
>| $CORE_PATH/$PROJECT/TEMP/$PROJECT".QC_REPORT."$TIMESTAMP".TEMP.csv"

# Take all of the lab prep metrics and meta data reports generated to date.
	# grab the header
	# cat all of the records (removing the header)
	# sort on the sm_tag and reverse numerical sort on epoch time (newest time comes first)
	# when sm_tag is duplicated take the first record (the last time that sample was generated)
	# join with the newest all project qc report on sm_tag


(cat  $CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
	| head -n 1 ; \
	cat $CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
	| grep -v "^SM_TAG" \
	| sort -t',' -k 1,1 -k 40,40nr) \
| awk 'BEGIN {FS=",";OFS=","} !x[$1]++ {print $0}' \
| join -t , -1 2 -2 1 \
$CORE_PATH/$PROJECT/TEMP/$PROJECT".QC_REPORT."$TIMESTAMP".TEMP.csv" \
/dev/stdin \
>| $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS/$PROJECT".QC_REPORT."$TIMESTAMP".csv"

###########################################################################
##### Make a QC report for just the samples in this batch per project ##### 
###########################################################################

SAMPLE_SHEET_NAME=`basename $SAMPLE_SHEET .csv`

# For each project in the sample sheet make a qc report containing only those samples in sample sheet.
# Create the headers for the new files using the header from the all sample sheet.

head -n 1 $CORE_PATH/$PROJECT/TEMP/$PROJECT".QC_REPORT."$TIMESTAMP".TEMP.csv" \
>| $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".QC_REPORT.csv"

CREATE_SAMPLE_ARRAY ()
{
SAMPLE_ARRAY=(`awk 1 $SAMPLE_SHEET | sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' | awk 'BEGIN {FS=","} $8=="'$SM_TAG'" {print $8}' | sort | uniq`)

#  8  SM_Tag=sample ID
SM_TAG=${SAMPLE_ARRAY[0]}
# SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks
## Don't need to do this unless I make this a sge submitter.
}

for SM_TAG in $(awk 'BEGIN {FS=","} $1=="'$PROJECT'" {print $8}' $SAMPLE_SHEET | sort | uniq );
	do
		CREATE_SAMPLE_ARRAY

		cat $CORE_PATH/$PROJECT/REPORTS/QC_REPORT_PREP/$SM_TAG".QC_REPORT_PREP.txt" \
		>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".QC_REPORT."$TIMESTAMP".txt"
	done

sed 's/\t/,/g' $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".QC_REPORT."$TIMESTAMP".txt" \
>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".QC_REPORT.csv"

#########################################################################
##### Join with LAB QC PREP METRICS AND METADATA at the batch level #####
#########################################################################

join -t , -1 2 -2 1 \
$CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME".QC_REPORT.csv" \
$CORE_PATH/$PROJECT/REPORTS/LAB_PREP_REPORTS/$SAMPLE_SHEET_NAME".LAB_PREP_METRICS.csv" \
>| $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS/$SAMPLE_SHEET_NAME".QC_REPORT.csv"

#######################################################
##### Concatenate all aneuploidy reports together #####
#######################################################

( cat $CORE_PATH/$PROJECT/REPORTS/ANEUPLOIDY_CHECK/*.chrom_count_report.txt | grep "^SM_TAG" | uniq ; \
cat $CORE_PATH/$PROJECT/REPORTS/ANEUPLOIDY_CHECK/*.chrom_count_report.txt | grep -v "SM_TAG" ) \
| sed 's/\t/,/g' \
>| $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS/$PROJECT".ANEUPLOIDY_CHECK."$TIMESTAMP".csv"

#######################################################################
##### Concatenate all per chromosome verifybamID reports together #####
#######################################################################

( cat $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID_CHR/*.VERIFYBAMID.PER_CHR.txt | grep "^#" | uniq ; \
cat $CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID_CHR/*.VERIFYBAMID.PER_CHR.txt | grep -v "^#" ) \
| sed 's/\t/,/g' \
>| $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS/$PROJECT".PER_CHR_VERIFYBAMID."$TIMESTAMP".csv"

####################################################
##### Clean up the Wall Clock minutes tracker. #####
####################################################

awk 'BEGIN {FS=",";OFS=","} $1~/^[A-Z 0-9]/&&$2!=""&&$3!=""&&$4!=""&&$5!=""&&$6!=""&&$7==""&&$5!~/A-Z/&&$6!~/A-Z/ \
{print $1,$2,$3,$4,$5,$6,($6-$5)/60,strftime("%F.%H-%M-%S",$5),strftime("%F.%H-%M-%S",$6)}' \
$CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv" \
| awk 'BEGIN {print "SAMPLE_GROUP,TASK_GROUP,TASK,HOST,EPOCH_START,EPOCH_END,WC_MIN,TIMESTAMP_START,TIMESTAMP_END"} \
{print $0}' \
>|$CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.FIXED.csv"

#############################################################
##### Summarize Wall Clock times ############################
##### This is probably garbage. I'll look at this later #####
#############################################################

sed 's/,/\t/g' $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv" \
| sort -k 1,1 -k 2,2 -k 3,3 \
| awk 'BEGIN {OFS="\t"} {print $0,($6-$5),($6-$5)/60,($6-$5)/3600}' \
| $DATAMASH/datamash -s -g 1,2 max 7 max 8 max 9 | tee $CORE_PATH/$PROJECT/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
| $DATAMASH/datamash -g 1 sum 3 sum 4 sum 5 \
| awk 'BEGIN {print "SAMPLE_PROJECT","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
| sed -r 's/[[:space:]]+/,/g' \
>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.BY_SAMPLE.csv"

sed 's/\t/,/g' $CORE_PATH/$PROJECT/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
| awk 'BEGIN {print "SAMPLE_PROJECT","TASK_GROUP","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
| sed -r 's/[[:space:]]+/,/g' \
>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.BY_SAMPLE_GROUP.csv"

echo Project finished at `date` >> $CORE_PATH/$PROJECT/REPORTS/PROJECT_START_END_TIMESTAMP.txt

# todo: oxidation report?
