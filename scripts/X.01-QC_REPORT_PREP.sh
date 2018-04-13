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

SAMTOOLS_DIR=$1
DATAMASH_DIR=$2
CORE_PATH=$3
PROJECT=$4
SM_TAG=$5

# New plan. datamash transpose output -> qc report prep for sample -> keep appending to it.
# Datamash transpose to a QC report prep folder. one file per sample.

# next script will cat everything together and add the header.
# mega super awesome.

# dirty validations count NF, if not X, then say haha you suck try again and don't write to cat file.

#########################################################
##### Grabbing the BAM header (for RG ID,PU,LB,etc) #####
#########################################################
#########################################################
##### THIS IS THE HEADER ################################
##### "PROJECT","SM_TAG","RG_PU","Library_Name" #########
#########################################################

$SAMTOOLS_DIR/samtools view -H \
$CORE_PATH/$PROJECT/CRAM/$SM_TAG".cram" \
| grep ^@RG \
| awk 'BEGIN {OFS="\t"} {split($9,SMtag,":"); split($8,PU,":"); split($5,Library,":"); split(Library[2],Library_Unit,"_"); \
print "'$PROJECT'",SMtag[2],PU[2],Library[2],Library_Unit[1],Library_Unit[2],substr(Library_Unit[2],1,1),substr(Library_Unit[2],2,2),\
Library_Unit[3],Library_Unit[4],substr(Library_Unit[4],1,1),substr(Library_Unit[4],2,2)}' \
| $DATAMASH_DIR/datamash -s -g 1,2 collapse 3 unique 4 unique 5 unique 6 unique 7 unique 8 unique 9 unique 10 unique 11 unique 12 \
| sed 's/,/;/g' \
| $DATAMASH_DIR/datamash transpose \
>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#################################################
##### GENDER CHECK FROM ANEUPLOIDY CHECK ########
#################################################
##### THIS IS THE HEADER ########################
##### X_AVG_DP,X_NORM_DP,Y_AVG_DP,Y_NORM_DP #####
#################################################

awk 'BEGIN {OFS="\t"} $2=="X"&&$3=="whole" {print $6,$7} $2=="Y"&&$3=="whole" {print $6,$7}' \
$CORE_PATH/$PROJECT/REPORTS/ANEUPLOIDY_CHECK/$SM_TAG".chrom_count_report.txt" \
| paste - - \
| awk 'BEGIN {OFS="\t"} END {if ($1!~/[0-9]/) print "NaN","NaN","NaN","NaN"; else print $0}' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#################################
##### GRABBING CONCORDANCE. #####
#################################
##########################################################################
##### THIS IS THE HEADER #################################################
##### "COUNT_DISC_HOM","COUNT_CONC_HOM","PERCENT_CONC_HOM", ##############
##### "COUNT_DISC_HET","COUNT_CONC_HET","PERCENT_CONC_HET", ##############
##### "PERCENT_TOTAL_CONC","COUNT_HET_BEADCHIP","SENSITIVITY_2_HET" ######
##########################################################################

if [ -f $CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_concordance.csv" ];
then
	awk 1 $CORE_PATH/$PROJECT/REPORTS/CONCORDANCE/$SM_TAG"_concordance.csv" \
	| awk 'BEGIN {FS=",";OFS="\t"} NR>1 \
	{print $5,$6,$7,$2,$3,$4,$8,$9,$10,$11}' \
	| $DATAMASH_DIR/datamash transpose \
	>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"
else
	echo -e "NaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN" \
	| $DATAMASH_DIR/datamash transpose \
	>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"
fi

#####################################################################################################################################
##### VERIFY BAM ID #################################################################################################################
#####################################################################################################################################
##### THIS IS THE HEADER ############################################################################################################
##### "VERIFYBAM_FREEMIX","VERIFYBAM_#SNPS","VERIFYBAM_FREELK1","VERIFYBAM_FREELK0","VERIFYBAM_DIFF_LK0_LK1","VERIFYBAM_AVG_DP" #####
#####################################################################################################################################

awk 'BEGIN {OFS="\t"} NR>1 {print $7*100,$4,$8,$9,($9-$8),$6}' \
$CORE_PATH/$PROJECT/REPORTS/VERIFYBAMID/$SM_TAG".selfSM" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

######################################################################################################
##### INSERT SIZE ####################################################################################
######################################################################################################
##### THIS IS THE HEADER #############################################################################
##### "MEDIAN_INSERT_SIZE","MEAN_INSERT_SIZE","STANDARD_DEVIATION_INSERT_SIZE","MAD_INSERT_SIZE" #####
######################################################################################################

if [[ ! -f $CORE_PATH/$PROJECT/REPORTS/INSERT_SIZE/METRICS/$SM_TAG".insert_size_metrics.txt" ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN \
		| $DATAMASH_DIR/datamash transpose \
		>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

	else
		awk 'BEGIN {OFS="\t"} NR==8 {print $1,$6,$7,$3}' \
		$CORE_PATH/$PROJECT/REPORTS/INSERT_SIZE/METRICS/$SM_TAG".insert_size_metrics.txt" \
		| $DATAMASH_DIR/datamash transpose \
		>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"
fi

#######################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR READ 1 ############################################################
#######################################################################################################
##### THIS THE HEADER #################################################################################
##### "PCT_PF_READS_ALIGNED_R1","PF_HQ_ALIGNED_READS_R1","PF_HQ_ALIGNED_Q20_BASES_R1" #################
##### "PF_MISMATCH_RATE_R1","PF_HQ_ERROR_RATE_R1","PF_INDEL_RATE_R1" ##################################
##### "PCT_READS_ALIGNED_IN_PAIRS_R1","PCT_ADAPTER_R1" ################################################
#######################################################################################################

awk 'BEGIN {OFS="\t"} NR==8 {if ($1=="UNPAIRED") print "0","0","0","0","0","0","0","0"; else print $7,$9,$11,$13,$14,$15,$18,$24}' \
$CORE_PATH/$PROJECT/REPORTS/ALIGNMENT_SUMMARY/$SM_TAG".alignment_summary_metrics.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#######################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR READ 2 ############################################################
#######################################################################################################
##### THIS THE HEADER #################################################################################
##### "PCT_PF_READS_ALIGNED_R2","PF_HQ_ALIGNED_READS_R2","PF_HQ_ALIGNED_Q20_BASES_R2" #################
##### "PF_MISMATCH_RATE_R2","PF_HQ_ERROR_RATE_R2","PF_INDEL_RATE_R2" ##################################
##### "PCT_READS_ALIGNED_IN_PAIRS_R2","PCT_ADAPTER_R2" ################################################
#######################################################################################################

awk 'BEGIN {OFS="\t"} NR==9 {if ($1=="") print "0","0","0","0","0","0","0","0" ; else print $7,$9,$11,$13,$14,$15,$18,$24}' \
$CORE_PATH/$PROJECT/REPORTS/ALIGNMENT_SUMMARY/$SM_TAG".alignment_summary_metrics.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR PAIR #######################################################
################################################################################################
##### THIS THE HEADER ##########################################################################
##### "TOTAL_READS","RAW_GIGS","PCT_PF_READS_ALIGNED_PAIR" #####################################
##### "PF_MISMATCH_RATE_PAIR","PF_HQ_ERROR_RATE_PAIR","PF_INDEL_RATE_PAIR" #####################
##### "PCT_READS_ALIGNED_IN_PAIRS_PAIR","STRAND_BALANCE_PAIR","PCT_CHIMERAS_PAIR" ##############
##### "PF_HQ_ALIGNED_Q20_BASES_PAIR","MEAN_READ_LENGTH","PCT_PF_READS_IMPROPER_PAIRS_PAIR" #####
################################################################################################

awk 'BEGIN {OFS="\t"} NR==10 {if ($1=="") print "0","0","0","0","0","0","0","0","0","0","0","0" ; else print $2,($2*$16/1000000000),$7,$13,$14,$15,$18,$22,$23,$11,$16,$20}' \
$CORE_PATH/$PROJECT/REPORTS/ALIGNMENT_SUMMARY/$SM_TAG".alignment_summary_metrics.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#############################################################################################################
##### MARK DUPLICATES REPORT ################################################################################
#############################################################################################################
##### THIS IS THE HEADER ####################################################################################
##### "UNMAPPED_READS","READ_PAIR_OPTICAL_DUPLICATES","PERCENT_DUPLICATION","ESTIMATED_LIBRARY_SIZE" ########
##### "SECONDARY_OR_SUPPLEMENTARY_READS","READ_PAIR_DUPLICATES","READ_PAIRS_EXAMINED","PAIRED_DUP_RATE" #####
##### "UNPAIRED_READ_DUPLICATES","UNPAIRED_READS_EXAMINED","UNPAIRED_DUP_RATE" ##############################
#############################################################################################################

awk 'BEGIN {OFS="\t"} NR==8 {if ($9!~/[0-9]/) print $5,$8,"NaN","NaN",$4,$7,$3,"NaN",$6,$2,"NaN" ; else print $5,$8,$9,$10,$4,$7,$3,($7/$3),$6,$2,($6/$2)}' \
$CORE_PATH/$PROJECT/REPORTS/PICARD_DUPLICATES/$SM_TAG"_MARK_DUPLICATES.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

##########################################################################################################################################################################
##### HYBRIDIZATION SELECTION REPORT #####################################################################################################################################
##########################################################################################################################################################################
##### THIS IS THE HEADER #################################################################################################################################################
##### "GENOME_SIZE","BAIT_TERRITORY","TARGET_TERRITORY","PCT_PF_UQ_READS_ALIGNED" ########################################################################################
##### "PF_UQ_GIGS_ALIGNED","PCT_SELECTED_BASES","ON_BAIT_VS_SELECTED","MEAN_BAIT_COVERAGE","MEAN_TARGET_COVERAGE","MEDIAN_TARGET_COVERAGE","MAX_TARGET_COVERAGE" #########
##### "ZERO_CVG_TARGETS_PCT","PCT_EXC_MAPQ","PCT_EXC_BASEQ","PCT_EXC_OVERLAP","PCT_EXC_OFF_TARGET" #######################################################################
##### "PCT_TARGET_BASES_1X","PCT_TARGET_BASES_2X","PCT_TARGET_BASES_10X","PCT_TARGET_BASES_20X","PCT_TARGET_BASES_30X","PCT_TARGET_BASES_40X","PCT_TARGET_BASES_50X" #####
##### "PCT_TARGET_BASES_100X","HS_LIBRARY_SIZE","AT_DROPOUT","GC_DROPOUT","HET_SNP_SENSITIVITY","HET_SNP_Q","BAIT_SET","PCT_USABLE_BASES_ON_BAIT"} #######################
##########################################################################################################################################################################

awk 'BEGIN {FS="\t";OFS="\t"} NR==8 {if ($12=="?"&&$44=="") print $2,$3,$4,"NaN",($14/1000000000),"NaN","NaN",$22,$23,$24,$25,$29,"NaN","NaN","NaN","NaN",\
$36,$37,$38,$39,$40,$41,$42,$43,"NaN",$51,$52,$53,$54,$1,"NaN" ; \
else if ($12!="?") print $2,$3,$4,$12,($14/1000000000),$19,$21,$22,$23,$24,$25,$29,$31,$32,$33,$34,\
$36,$37,$38,$39,$40,$41,$42,$43,"NaN",$51,$52,$53,$54,$1,$26 ; \
else print $2,$3,$4,$12,($14/1000000000),$19,$21,$22,$23,$24,$25,$29,$31,$32,$33,$34,\
$36,$37,$38,$39,$40,$41,$42,$43,$44,$51,$52,$53,$54,$1,$26}' \
$CORE_PATH/$PROJECT/REPORTS/HYB_SELECTION/$SM_TAG"_hybridization_selection_metrics.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

##############################################
##### BAIT BIAS REPORT FOR Cref and Gref #####
##############################################
##### THIS IS THE HEADER #####################
##### Cref_Q,Gref_Q ###################
##############################################

grep -v "^#" $CORE_PATH/$PROJECT/REPORTS/BAIT_BIAS/SUMMARY/$SM_TAG".bait_bias_summary_metrics.txt" \
| sed '/^$/d' \
| awk 'BEGIN {OFS="\t"} $12=="Cref"||$12=="Gref"  {print $5}' \
| paste - - \
| awk 'BEGIN {OFS="\t"} {print $0}' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

############################################################
##### PRE-ADAPTER BIAS REPORT FOR Deamination and OxoG #####
############################################################
##### THIS IS THE HEADER ###################################
##### Deamination_Q,OxoG_Q #################################
############################################################

grep -v "^#" $CORE_PATH/$PROJECT/REPORTS/PRE_ADAPTER/SUMMARY/$SM_TAG".pre_adapter_summary_metrics.txt" \
| sed '/^$/d' \
| awk 'BEGIN {OFS="\t"} $12=="Deamination"||$12=="OxoG"  {print $5}' \
| paste - - \
| awk 'BEGIN {OFS="\t"} {print $0}' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

###############################################################
##### GENERATE COUNT PCT,IN DBSNP FOR ON BAIT SNVS ############
###############################################################
##### THIS IS THE HEADER ######################################
##### "COUNT_SNV_ON_BAIT""\t""PERCENT_SNV_ON_BAIT_SNP138" ##### 
###############################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/SNV/QC/FILTERED_ON_BAIT/$SM_TAG"_QC_OnBait_SNV.vcf.gz" \
| awk '{SNV_COUNT++NR} {DBSNP_COUNT+=($3~"rs")} \
END {if (SNV_COUNT!="") {print SNV_COUNT,(DBSNP_COUNT/SNV_COUNT)*100} \
else {print "0","NaN"}}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#######################################################################################
##### GENERATE COUNT PCT,IN DBSNP FOR ON TARGET SNVS ##################################
#######################################################################################
##### THIS IS THE HEADER ##############################################################
##### "COUNT_SNV_ON_TARGET""\t""PERCENT_SNV_ON_TARGET_SNP138""\t""HET:HOM_TARGET" ##### 
#######################################################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/SNV/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnTarget_SNV.vcf.gz" \
| awk '{SNV_COUNT++NR} {DBSNP_COUNT+=($3~"rs")} {HET_COUNT+=($10 ~ /^0\/1/)} \
END {if (SNV_COUNT!="") {print SNV_COUNT,(DBSNP_COUNT/SNV_COUNT)*100,(HET_COUNT)/(SNV_COUNT-HET_COUNT)} \
else {print "0","NaN","NaN"}}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

####################################################
##### GRABBING TI/TV ON UCSC CODING EXONS, ALL #####
####################################################
##### THIS IS THE HEADER ###########################
##### "ALL_TI_TV_COUNT""\t""ALL_TI_TV_RATIO" #######
####################################################

awk 'BEGIN {OFS="\t"} END {if ($2!="") {print $2,$6} \
else {print "0","NaN"}}' \
$CORE_PATH/$PROJECT/REPORTS/TI_TV/$SM_TAG"_All_.titv.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

######################################################
##### GRABBING TI/TV ON UCSC CODING EXONS, KNOWN #####
######################################################
##### THIS IS THE HEADER #############################
##### "KNOWN_TI_TV_COUNT""\t""KNOWN_TI_TV_RATIO" #####
######################################################

awk 'BEGIN {OFS="\t"} END {if ($2!="") {print $2,$6} \
else {print "0","NaN"}}' \
$CORE_PATH/$PROJECT/REPORTS/TI_TV/$SM_TAG"_Known_.titv.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

######################################################
##### GRABBING TI/TV ON UCSC CODING EXONS, NOVEL #####
######################################################
##### THIS IS THE HEADER #############################
##### "NOVEL_TI_TV_COUNT""\t""NOVEL_TI_TV_RATIO" #####
######################################################

awk 'BEGIN {OFS="\t"} END {if ($2!="") {print $2,$6} \
else {print "0","NaN"}}' \
$CORE_PATH/$PROJECT/REPORTS/TI_TV/$SM_TAG"_Novel_.titv.txt" \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#############################################################################################################################
##### INDEL METRICS ON BAIT #################################################################################################
#############################################################################################################################
##### THIS IS THE HEADER ####################################################################################################
##### "COUNT_ALL_INDEL_BAIT","ALL_INDEL_BAIT_PCT_SNP138","COUNT_BIALLELIC_INDEL_BAIT","BIALLELIC_INDEL_BAIT_PCT_SNP138" #####
#############################################################################################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/INDEL/QC/FILTERED_ON_BAIT/$SM_TAG"_QC_OnBait_INDEL.vcf.gz" \
| awk '{INDEL_COUNT++NR} \
{INDEL_BIALLELIC+=($5!~",")} \
{DBSNP_COUNT+=($3~"rs")} \
{DBSNP_COUNT_BIALLELIC+=($3~"rs"&&$5!~",")} \
END {if (INDEL_BIALLELIC==""&&INDEL_COUNT=="") print "0","NaN","0","NaN"; \
else if (INDEL_BIALLELIC==0&&INDEL_COUNT>=1) print INDEL_COUNT,(DBSNP_COUNT/INDEL_COUNT)*100,"0","NaN"; \
else print INDEL_COUNT,(DBSNP_COUNT/INDEL_COUNT)*100,INDEL_BIALLELIC,(DBSNP_COUNT_BIALLELIC/INDEL_BIALLELIC)*100}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#####################################################################################################################################
##### INDEL METRICS ON TARGET #######################################################################################################
#####################################################################################################################################
##### THIS IS THE HEADER ############################################################################################################
##### "COUNT_ALL_INDEL_TARGET","ALL_INDEL_TARGET_PCT_SNP138","COUNT_BIALLELIC_INDEL_TARGET","BIALLELIC_INDEL_TARGET_PCT_SNP138" #####
#####################################################################################################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/INDEL/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnTarget_INDEL.vcf.gz" \
| awk '{INDEL_COUNT++NR} \
{INDEL_BIALLELIC+=($5!~",")} \
{DBSNP_COUNT+=($3~"rs")} \
{DBSNP_COUNT_BIALLELIC+=($3~"rs"&&$5!~",")} \
END {if (INDEL_BIALLELIC==""&&INDEL_COUNT=="") print "0","NaN","0","NaN"; \
else if (INDEL_BIALLELIC==0&&INDEL_COUNT>=1) print INDEL_COUNT,(DBSNP_COUNT/INDEL_COUNT)*100,"0","NaN"; \
else print INDEL_COUNT,(DBSNP_COUNT/INDEL_COUNT)*100,INDEL_BIALLELIC,(DBSNP_COUNT_BIALLELIC/INDEL_BIALLELIC)*100}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

####################################################################
##### BASIC METRICS FOR MIXED VARIANT TYPES ON BAIT ################
####################################################################
##### GENERATE COUNT PCT,IN DBSNP FOR ON BAIT MIXED VARIANT ########
##### THIS IS THE HEADER ###########################################
##### "COUNT_MIXED_ON_BAIT""\t""PERCENT_MIXED_ON_BAIT_SNP138"} ##### 
####################################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/MIXED/QC/FILTERED_ON_BAIT/$SM_TAG"_QC_OnBait_MIXED.vcf.gz" \
| awk '{MIXED_COUNT++NR} {DBSNP_COUNT+=($3~"rs")} \
END {if (MIXED_COUNT!="") print MIXED_COUNT,(DBSNP_COUNT/MIXED_COUNT)*100 ; \
else print "0","NaN"}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"

#######################################################################
##### GENERATE COUNT PCT,IN DBSNP FOR ON TARGET MIXED VARIANT #########
#######################################################################
##### THIS IS THE HEADER ##############################################
##### "COUNT_MIXED_ON_TARGET""\t""PERCENT_MIXED_ON_TARGET_SNP138" ##### 
#######################################################################

zgrep -v "^#" $CORE_PATH/$PROJECT/MIXED/QC/FILTERED_ON_TARGET/$SM_TAG"_QC_OnBait_MIXED.vcf.gz" \
| awk '{MIXED_COUNT++NR} {DBSNP_COUNT+=($3~"rs")} \
END {if (MIXED_COUNT!="") print MIXED_COUNT,(DBSNP_COUNT/MIXED_COUNT)*100 ; \
else print "0","NaN"}' \
| sed 's/ /\t/g' \
| $DATAMASH_DIR/datamash transpose \
>> $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt"



cat $CORE_PATH/$PROJECT/TEMP/$SM_TAG".QC_REPORT_TEMP.txt" \
| $DATAMASH_DIR/datamash transpose \
>| $CORE_PATH/$PROJECT/REPORTS/QC_REPORT_PREP/$SM_TAG".QC_REPORT_PREP.txt"
