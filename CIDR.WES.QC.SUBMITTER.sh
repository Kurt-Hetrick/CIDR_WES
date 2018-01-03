#!/bin/bash

SAMPLE_SHEET=$1

# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED

SCRIPT_DIR="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CIDR_WES/scripts"

# Directory where sequencing projects are located

CORE_PATH="/mnt/research/active"

# Generate a list of active queue and remove the ones that I don't want to use

QUEUE_LIST=`qstat -f -s r | egrep -v "^[0-9]|^-|^queue" | cut -d @ -f 1 | sort | uniq | egrep -v "all.q|cgc.q|programmers.q|uhoh.q|rhel7.q|rnd.q|bigmem.q" | datamash collapse 1 | awk '{print $1}'`

# PIPELINE PROGRAMS

BWA_DIR="/mnt/research/tools/LINUX/BWA/bwa-0.7.15"
SAMBLASTER_DIR="/mnt/research/tools/LINUX/SAMBLASTER/samblaster-v.0.1.24"
JAVA_1_8="/mnt/research/tools/LINUX/JAVA/jdk1.8.0_73/bin"
PICARD_DIR="/mnt/research/tools/LINUX/PICARD/picard-2.17.0"
DATAMASH_DIR="/mnt/research/tools/LINUX/DATAMASH/datamash-1.0.6/"

# JAVA_1_6="/isilon/cgc/PROGRAMS/jre1.6.0_25/bin"
# GATK_DIR="/isilon/cgc/PROGRAMS/GenomeAnalysisTK-3.7"
# VERIFY_DIR="/isilon/cgc/PROGRAMS/verifyBamID_20120620/bin/"
# TABIX_DIR="/isilon/cgc/PROGRAMS/tabix-0.2.6"
# SAMTOOLS_DIR="/isilon/cgc/PROGRAMS/samtools-0.1.18"
# BEDTOOLS_DIR="/isilon/cgc/PROGRAMS/bedtools-2.22.0/bin"
# VCFTOOLS_DIR="/isilon/cgc/PROGRAMS/vcftools_0.1.12b/bin"
# PLINK2_DIR="/isilon/cgc/PROGRAMS/PLINK2"
# KING_DIR="/isilon/cgc/PROGRAMS/KING/Linux-king19"
# CIDRSEQSUITE_DIR="/isilon/cgc/PROGRAMS/CIDRSeqSuiteSoftware_Version_4_0/"
# ANNOVAR_DIR="/isilon/cgc/PROGRAMS/ANNOVAR/2013_09_11"

# PIPELINE FILES
# GENE_LIST="/isilon/cgc/PIPELINE_FILES/RefSeqGene.GRCh37.Ready.txt"
# VERIFY_VCF="/isilon/cgc/PIPELINE_FILES/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf"
# CODING_BED="/isilon/cgc/PIPELINE_FILES/RefSeq.Unique.GRCh37.FINAL.bed"
# CYTOBAND_BED="/isilon/cgc/PIPELINE_FILES/GRCh37.Cytobands.bed"
# HAPMAP="/isilon/cgc/PIPELINE_FILES/hapmap_3.3.b37.vcf"
# OMNI_1KG="/isilon/cgc/PIPELINE_FILES/1000G_omni2.5.b37.vcf"
# HI_CONF_1KG_PHASE1_SNP="/isilon/cgc/PIPELINE_FILES/1000G_phase1.snps.high_confidence.b37.vcf"
# MILLS_1KG_GOLD_INDEL="/isilon/cgc/PIPELINE_FILES/Mills_and_1000G_gold_standard.indels.b37.vcf"
# PHASE3_1KG_AUTOSOMES="/isilon/cgc/PIPELINE_FILES/ALL.autosomes.phase3_shapeit2_mvncall_integrated_v5.20130502.sites.vcf.gz"
# DBSNP_129="/isilon/cgc/PIPELINE_FILES/dbsnp_138.b37.excluding_sites_after_129.vcf"

#################################
##### MAKE A DIRECTORY TREE #####
#################################

# NEED TO FIGURE OUT HOW TO PUSH OUT A PIPELINE VERSION.
# PIPELINE_VERSION=``

# make the project directory tree structure
# create an error for all metadata for a sample to pass through various part of the pipeline.

# make an array for each sample with information needed for pipeline input obtained from the sample sheet
# add a end of file is not present
# remove carriage returns if not present, remove blank lines if present, remove lines that only have whitespace

# function to grab all the projects in the sample sheet and create all of the folders in the project if they don't already exist

CREATE_PROJECT_ARRAY ()
{
PROJECT_ARRAY=(`awk 1 $SAMPLE_SHEET | sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' | awk 'BEGIN {FS=","} $1=="'$PROJECT_NAME'" {print $1}' | sort | uniq`)

#  1  Project=the Seq Proj folder name
SEQ_PROJECT=${PROJECT_ARRAY[0]}

}

# for every project in the sample sheet create all of the folders in the project if they don't already exist

MAKE_PROJ_DIR_TREE ()
{
mkdir -p \
$CORE_PATH/$SEQ_PROJECT/{TEMP,FASTQ,LOGS,CRAM,GVCF,COMMAND_LINES} \
$CORE_PATH/$SEQ_PROJECT/INDEL/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/INDEL/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/SNV/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/SNV/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/MIXED/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/MIXED/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/VCF/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/VCF/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/{ALIGNMENT_SUMMARY,ANNOVAR,PICARD_DUPLICATES,TI_TV,VERIFYBAMID,VERIFYBAMID_CHR} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/BAIT_BIAS/{METRICS,SUMMARY} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/PRE_ADAPTER/{METRICS,SUMMARY} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/{METRICS,PDF} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/CONCORDANCE \
$CORE_PATH/$SEQ_PROJECT/REPORTS/COUNT_COVARIATES/{GATK_REPORT,PDF} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/GC_BIAS/{METRICS,PDF,SUMMARY} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/DEPTH_OF_COVERAGE/{TARGET,REFSEQ_CODING_PLUS_10bp} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE \
$CORE_PATH/$SEQ_PROJECT/REPORTS/INSERT_SIZE/{METRICS,PDF} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/LOCAL_REALIGNMENT_INTERVALS \
$CORE_PATH/$SEQ_PROJECT/REPORTS/MEAN_QUALITY_BY_CYCLE/{METRICS,PDF} \
$CORE_PATH/$SEQ_PROJECT/REPORTS/ANEUPLOIDY_CHECK
}

SETUP_PROJECT ()
{
CREATE_PROJECT_ARRAY
MAKE_PROJ_DIR_TREE
echo Project started at `date` >> $CORE_PATH/$SEQ_PROJECT/REPORTS/PROJECT_START_END_TIMESTAMP.txt
}

for PROJECT_NAME in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq );
do
SETUP_PROJECT
done

# IN THE FUTURE WILL PUSH OUT TO QSUB;

# -M email@address
# -m {b,e,a} depending on the job.
## other possible options
### -l h_vmem=size specify the amount of maximum memory required (e.g. 3G or 3500M) (NOTE: This is memory per processor slot. So if you ask for 2 processors total memory will be 2 * hvmem_value)

# RUN BWA

CREATE_SAMPLE_INFO_ARRAY ()
{
SAMPLE_INFO_ARRAY=(`awk 1 $SAMPLE_SHEET | sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' | awk 'BEGIN {FS=","} $8$2$3$4=="'$PLATFORM_UNIT'" {split($19,INDEL,";"); print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' | sort | uniq`)

#  1  Project=the Seq Proj folder name
PROJECT=${SAMPLE_INFO_ARRAY[0]}

#  2  FCID=flowcell that sample read group was performed on
FCID=${SAMPLE_INFO_ARRAY[1]}

#  3  Lane=lane of flowcell that sample read group was performed on]
LANE=${SAMPLE_INFO_ARRAY[2]}

#  4  Index=sample barcode
INDEX=${SAMPLE_INFO_ARRAY[3]}

#  5  Platform=type of sequencing chemistry matching SAM specification
PLATFORM=${SAMPLE_INFO_ARRAY[4]}

#  6  Library_Name=library group of the sample read group, Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not
LIBRARY=${SAMPLE_INFO_ARRAY[5]}

#  7  Date=should be the run set up date to match the seq run folder name, but it has been arbitrarily populated
RUN_DATE=${SAMPLE_INFO_ARRAY[6]}

#  8  SM_Tag=sample ID
SM_TAG=${SAMPLE_INFO_ARRAY[7]}
SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks

#  9  Center=the center/funding mechanism
CENTER=${SAMPLE_INFO_ARRAY[8]}

# 10  Description=Generally we use to denote the sequencer setting (e.g. rapid run)
# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.
SEQUENCER_MODEL=${SAMPLE_INFO_ARRAY[9]}

#############################
# 11  Seq_Exp_ID ### SKIP ###
#############################

# 12  Genome_Ref=the reference genome used in the analysis pipeline
REF_GENOME=${SAMPLE_INFO_ARRAY[10]}

###########################
# 13  Operator ### SKIP ###
##########################################
# 14  Extra_VCF_Filter_Params ### SKIP ###
##########################################

# 15  TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files
TITV_BED=${SAMPLE_INFO_ARRAY[11]}

# 16  Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
# Used for limited where to run base quality score recalibration on where to create gvcf files.
BAIT_BED=${SAMPLE_INFO_ARRAY[12]}

# 17  Targets_BED_File=bed file acquired from manufacturer of their targets.
TARGET_BED=${SAMPLE_INFO_ARRAY[13]}

# 18  KNOWN_SITES_VCF=used to annotate ID field in VCF file. masking in base call quality score recalibration.
DBSNP=${SAMPLE_INFO_ARRAY[14]}

# 19  KNOWN_INDEL_FILES=used for BQSR masking, sensitivity in local realignment.
KNOWN_INDEL_1=${SAMPLE_INFO_ARRAY[15]}
KNOWN_INDEL_2=${SAMPLE_INFO_ARRAY[16]}
}

RUN_BWA ()
{
echo \
qsub \
-S /bin/bash \
-cwd \
-V \
-q $QUEUE_LIST \
-p -50 \
-N A.01-BWA"_"$SGE_SM_TAG"_"$FCID"_"$LANE"_"$INDEX"_"$PROJECT \
-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG"_"$FCID"_"$LANE"_"$INDEX"-BWA.log" \
-j y \
$SCRIPT_DIR/A.01_BWA.sh \
$BWA_DIR \
$SAMBLASTER_DIR \
$JAVA_1_8 \
$PICARD_DIR \
$CORE_PATH \
$PROJECT \
$FCID \
$LANE \
$INDEX \
$PLATFORM \
$LIBRARY \
$RUN_DATE \
$SM_TAG \
$CENTER \
$SEQUENCER_MODEL \
$REF_GENOME
}

for PLATFORM_UNIT in $(awk 'BEGIN {FS=","} NR>1 {print $8$2$3$4}' $SAMPLE_SHEET | sort | uniq );
do
CREATE_SAMPLE_INFO_ARRAY
RUN_BWA
# echo sleep 0.1
done

# create a hold job id qsub command line based on the number of
# submit merging the bam files created by bwa mem above
# only launch when every lane for a sample is done being processed by bwa mem
# I want to clean this up eventually, but not in the mood for it right now.

CREATE_SAMPLE_INFO_ARRAY
# gsub(/,/,",INPUT=/mnt/research/active/"$1"/TEMP/",$4) \

awk 'BEGIN {FS=","; OFS="\t"} NR>1 {print $1,$8,$2"_"$3"_"$4,$2"_"$3"_"$4".bam",$8}' \
$SAMPLE_SHEET \
| awk 'BEGIN {OFS="\t"} {sub(/@/,"_",$5)} {print $1,$2,$3,$4,$5}' \
| sort -k 1,1 -k 2,2 -k 3,3 \
| uniq \
| $DATAMASH_DIR/datamash -s -g 1,2 collapse 3 collapse 4 unique 5 \
| awk 'BEGIN {FS="\t"} \
gsub(/,/,",A.01_BWA_"$2"_",$3) \
gsub(/,/,",INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/",$4) \
{print "qsub",\
"-S /bin/bash",\
"-cwd",\
"-V",\
"-q","'$QUEUE_LIST'",\
"-p -50",\
"-N","B.01_MERGE_BAM_"$5"_"$1,\
"-o","'$CORE_PATH'/"$1"/LOGS/"$2"_"$1"-MERGE_BAM_FILES.log",\
"-j y",\
"-hold_jid","A.01_BWA_"$5"_"$3, \
"'$SCRIPT_DIR'""/B.01_MERGE_SORT_AGGRO.sh",\
"'$JAVA_1_8'","'$PICARD_DIR'","'$CORE_PATH'",$1,$2,"INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/"$4"\n""sleep 1s"}'

# # Mark duplicates on the bam file above. Create a Mark Duplicates report which goes into the QC report
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","C.01_MARK_DUPLICATES_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","B.01_MERGE_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".MARK_DUPLICATES.log",\
# "'$SCRIPT_DIR'""/C.01_MARK_DUPLICATES.sh",\
# "'$JAVA_1_8'","'$PICARD_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # Generate a list of places that could be potentially realigned.
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$19}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($5,INDEL,";"); split($3,smtag,"[@]"); \
# print "qsub","-N","D.01_REALIGNER_TARGET_CREATOR_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","C.01_MARK_DUPLICATES_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".REALIGNER_TARGET_CREATOR.log",\
# "'$SCRIPT_DIR'""/D.01_REALIGNER_TARGET_CREATOR.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,INDEL[1],INDEL[2]"\n""sleep 1s"}'
#
# # With the list generated above walk through the BAM file and realign where necessary
# # Write out a new bam file
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$19}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($5,INDEL,";"); split($3,smtag,"[@]"); \
# print "qsub","-N","E.01_INDEL_REALIGNER_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","D.01_REALIGNER_TARGET_CREATOR_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".INDEL_REALIGNER.log",\
# "'$SCRIPT_DIR'""/E.01_INDEL_REALIGNER.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,INDEL[1],INDEL[2]"\n""sleep 1s"}'
#
# # Run Base Quality Score Recalibration
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$19,$18,$16}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($5,INDEL,";"); split($3,smtag,"[@]"); \
# print "qsub","-N","F.01_PERFORM_BQSR_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","E.01_INDEL_REALIGNER_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PERFORM_BQSR.log",\
# "'$SCRIPT_DIR'""/F.01_PERFORM_BQSR.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,INDEL[1],INDEL[2],$6,$7"\n""sleep 1s"}'
#
# # write Final Bam file
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","F.01_PERFORM_BQSR_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".FINAL_BAM.log",\
# "'$SCRIPT_DIR'""/G.01_FINAL_BAM.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# # SCATTER THE HAPLOTYPE CALLER GVCF CREATION USING THE WHERE THE BED INTERSECTS WITH {{1.22},{X,Y}}
#
# CREATE_SAMPLE_INFO_ARRAY_HC ()
# {
# SAMPLE_INFO_ARRAY_HC=(`awk 'BEGIN {FS="\t"; OFS="\t"} $8=="'$SAMPLE'" {split($8,smtag,"[@]"); print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_HAPLOTYPE_CALLER ()
# {
# echo \
# qsub \
# -N H.01_HAPLOTYPE_CALLER_${SAMPLE_INFO_ARRAY_HC[0]}_${SAMPLE_INFO_ARRAY_HC[5]}_chr$CHROMOSOME \
# -hold_jid G.01_FINAL_BAM_${SAMPLE_INFO_ARRAY_HC[5]}_${SAMPLE_INFO_ARRAY_HC[0]} \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_HC[0]}/${SAMPLE_INFO_ARRAY_HC[1]}/${SAMPLE_INFO_ARRAY_HC[2]}/LOGS/${SAMPLE_INFO_ARRAY_HC[2]}_${SAMPLE_INFO_ARRAY_HC[0]}.HAPLOTYPE_CALLER_chr$CHROMOSOME.log \
# $SCRIPT_DIR/H.01_HAPLOTYPE_CALLER_SCATTER.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_HC[0]} ${SAMPLE_INFO_ARRAY_HC[1]} ${SAMPLE_INFO_ARRAY_HC[2]} ${SAMPLE_INFO_ARRAY_HC[3]} \
# $CHROMOSOME
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
# do
# CREATE_SAMPLE_INFO_ARRAY_HC
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_HAPLOTYPE_CALLER
# 		echo sleep 1s
# 		done
# 	done
#
# ################################################################
#
# # GATHER UP THE PER SAMPLE PER CHROMOSOME GVCF FILES INTO A SINGLE SAMPLE GVCF
#
# # GATHER UP THE PER SAMPLE PER CHROMOSOME GVCF FILES INTO A SINGLE SAMPLE GVCF
#
# # BUILD_HOLD_ID_PATH(){
# # 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# # 	do
# # 	HOLD_ID_PATH="-hold_jid "
# # 	for CHROMOSOME in {{1..22},{X,Y}};
# #  	do
# #  		HOLD_ID_PATH=$HOLD_ID_PATH"H.01_HAPLOTYPE_CALLER_"$PROJECT"_"${SAMPLE_INFO_ARRAY_HC[5]}"_chr"$CHROMOSOME","
# #  	done
# #  done
# # }
#
# BUILD_HOLD_ID_PATH(){
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"H.01_HAPLOTYPE_CALLER_"$PROJECT"_"$SAMPLE"_chr"$CHROMOSOME","
#  	done
#  done
# }
#
# # CREATE_SAMPLE_INFO_ARRAY_HC ()
# # {
# # SAMPLE_INFO_ARRAY_HC=(`awk 'BEGIN {FS="\t"; OFS="\t"} $8=="'$SAMPLE'" {split($8,smtag,"[@]"); print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}' \
# # ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# CREATE_SAMPLE_INFO_ARRAY_HC ()
# {
# SAMPLE_INFO_ARRAY_HC=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_HAPLOTYPE_CALLER_GATHER ()
# {
# echo \
# qsub \
# -N H.01-A.01_HAPLOTYPE_CALLER_GATHER_${SAMPLE_INFO_ARRAY_HC[0]}_$SAMPLE \
# ${HOLD_ID_PATH} \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_HC[0]}/${SAMPLE_INFO_ARRAY_HC[1]}/${SAMPLE_INFO_ARRAY_HC[2]}/LOGS/${SAMPLE_INFO_ARRAY_HC[2]}_${SAMPLE_INFO_ARRAY_HC[0]}.HAPLOTYPE_CALLER_GATHER.log \
# $SCRIPT_DIR/H.01-A.01_HAPLOTYPE_CALLER_GATHER.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_HC[0]} ${SAMPLE_INFO_ARRAY_HC[1]} ${SAMPLE_INFO_ARRAY_HC[2]} ${SAMPLE_INFO_ARRAY_HC[3]}
# }
#
# # CALL_HAPLOTYPE_CALLER_GATHER ()
# # {
# # echo \
# # qsub \
# # -N H.01-A.01_HAPLOTYPE_CALLER_GATHER_${SAMPLE_INFO_ARRAY_HC[0]}_${SAMPLE_INFO_ARRAY_HC[5]} \
# # ${HOLD_ID_PATH} \
# # -o $CORE_PATH/${SAMPLE_INFO_ARRAY_HC[0]}/${SAMPLE_INFO_ARRAY_HC[1]}/${SAMPLE_INFO_ARRAY_HC[2]}/LOGS/${SAMPLE_INFO_ARRAY_HC[2]}_${SAMPLE_INFO_ARRAY_HC[0]}.HAPLOTYPE_CALLER_GATHER.log \
# # $SCRIPT_DIR/H.01-A.01_HAPLOTYPE_CALLER_GATHER.sh \
# # $JAVA_1_8 $GATK_DIR $CORE_PATH \
# # ${SAMPLE_INFO_ARRAY_HC[0]} ${SAMPLE_INFO_ARRAY_HC[1]} ${SAMPLE_INFO_ARRAY_HC[2]} ${SAMPLE_INFO_ARRAY_HC[3]}
# # }
#
# # for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8} $SAMPLE_SHEET | sort | uniq );
# #  do
# # 	BUILD_HOLD_ID_PATH
# # 	CREATE_SAMPLE_INFO_ARRAY_HC
# # 	CALL_HAPLOTYPE_CALLER_GATHER
# # 	echo sleep 1s
# #  done
#
# # for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]}' $SAMPLE_SHEET | sort | uniq );
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
#  do
# 	BUILD_HOLD_ID_PATH
# 	CREATE_SAMPLE_INFO_ARRAY_HC
# 	CALL_HAPLOTYPE_CALLER_GATHER
# 	echo sleep 1s
#  done
#
# # Run POST BQSR TABLE
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$19,$18}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($5,INDEL,";"); split($3,smtag,"[@]"); \
# print "qsub","-N","H.02_POST_BQSR_TABLE_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".POST_BQSR_TABLE.log",\
# "'$SCRIPT_DIR'""/H.02_POST_BQSR_TABLE.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,INDEL[1],INDEL[2],$6"\n""sleep 1s"}'
#
# # Run ANALYZE COVARIATES
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($5,INDEL,";"); split($3,smtag,"[@]"); \
# print "qsub","-N","H.02-A.01_ANALYZE_COVARIATES_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.02_POST_BQSR_TABLE_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".ANALYZE_COVARIATES.log",\
# "'$SCRIPT_DIR'""/H.02-A.01_ANALYZE_COVARIATES.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# # RUN DOC CODING PLUS 10 BP FLANKS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03_DOC_CODING_10bpFLANKS_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".DOC_CODING_10bpFLANKS.log",\
# "'$SCRIPT_DIR'""/H.03_DOC_CODING_10bpFLANKS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'","'$GENE_LIST'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# # RUN ANEUPLOIDY_CHECK AFTER CODING PLUS 10 BP FLANKS FINISHES
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.01_DOC_CHROM_DEPTH_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03_DOC_CODING_10bpFLANKS_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".ANEUPLOIDY_CHECK.log",\
# "'$SCRIPT_DIR'""/H.03-A.01_CHROM_DEPTH.sh",\
# "'$CORE_PATH'","'$CYTOBAND_BED'","'$DATAMASH_DIR'","'$BEDTOOLS_DIR'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN FORMATTING PER BASE COVERAGE WITH GENE NAME ANNNOTATION
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.02_PER_BASE_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03_DOC_CODING_10bpFLANKS_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_BASE.log",\
# "'$SCRIPT_DIR'""/H.03-A.02_PER_BASE.sh",\
# "'$CORE_PATH'","'$BEDTOOLS_DIR'","'$CODING_BED'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN FILTERING PER BASE COVERAGE WITH GENE NAME ANNNOTATION WITH LESS THAN 30x
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.02_PER_BASE_FILTER_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03-A.02_PER_BASE_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_BASE_FILTER.log",\
# "'$SCRIPT_DIR'""/H.03-A.02-A.01_PER_BASE_FILTERED.sh",\
# "'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # BGZIP PER BASE COVERAGE WITH GENE NAME ANNNOTATION
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.02-A.02_PER_BASE_BGZIP_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03-A.02_PER_BASE_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_BASE_BGZIP.log",\
# "'$SCRIPT_DIR'""/H.03-A.02-A.02_PER_BASE_BGZIP.sh",\
# "'$CORE_PATH'","'$TABIX_DIR'",$1,$2,$3"\n""sleep 1s"}'
#
# # TABIX PER BASE COVERAGE WITH GENE NAME ANNNOTATION
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.02-A.02-A.01_PER_BASE_TABIX_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03-A.02-A.02_PER_BASE_BGZIP_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_BASE_TABIX.log",\
# "'$SCRIPT_DIR'""/H.03-A.02-A.02-A.01_PER_BASE_TABIX.sh",\
# "'$CORE_PATH'","'$TABIX_DIR'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN FORMATTING PER CODING INTERVAL COVERAGE WITH GENE NAME ANNNOTATION
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.03_PER_INTERVAL_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03_DOC_CODING_10bpFLANKS_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_INTERVAL.log",\
# "'$SCRIPT_DIR'""/H.03-A.03_PER_INTERVAL.sh",\
# "'$CORE_PATH'","'$BEDTOOLS_DIR'","'$CODING_BED'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN FILTERING PER CODING INTERVAL COVERAGE WITH GENE NAME ANNNOTATION WITH LESS THAN 30x
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.03-A.03_PER_INTERVAL_FILTER_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.03-A.03_PER_INTERVAL_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".PER_INTERVAL_FILTER.log",\
# "'$SCRIPT_DIR'""/H.03-A.03-A.01_PER_INTERVAL_FILTERED.sh",\
# "'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN DOC TARGET BED
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$17}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.05_DOC_TARGET_BED_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".DOC_TARGET_BED.log",\
# "'$SCRIPT_DIR'""/H.05_DOC_TARGET_BED.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'","'$GENE_LIST'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# # RUN COLLECT MULTIPLE METRICS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$18,$15}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.06_COLLECT_MULTIPLE_METRICS_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".COLLECT_MULTIPLE_METRICS.log",\
# "'$SCRIPT_DIR'""/H.06_COLLECT_MULTIPLE_METRICS.sh",\
# "'$JAVA_1_8'","'$PICARD_DIR'","'$CORE_PATH'","'$SAMTOOLS_DIR'",$1,$2,$3,$4,$5,$6"\n""sleep 1s"}'
#
# # RUN COLLECT HS METRICS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$16,$17}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.07_COLLECT_HS_METRICS_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".COLLECT_HS_METRICS.log",\
# "'$SCRIPT_DIR'""/H.07_COLLECT_HS_METRICS.sh",\
# "'$JAVA_1_8'","'$PICARD_DIR'","'$CORE_PATH'","'$SAMTOOLS_DIR'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# # RUN SELECT VERIFYBAM ID VCF
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$15}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.08_SELECT_VERIFYBAMID_VCF_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","G.01_FINAL_BAM_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".SELECT_VERIFYBAMID_VCF.log",\
# "'$SCRIPT_DIR'""/H.08_SELECT_VERIFYBAMID_VCF.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'","'$VERIFY_VCF'",$1,$2,$3,$4,$5"\n""sleep 1s"}'
#
# # RUN VERIFYBAMID
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); \
# print "qsub","-N","H.08-A.01_VERIFYBAMID_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","H.08_SELECT_VERIFYBAMID_VCF_"smtag[1]"_"smtag[2]"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$1".VERIFYBAMID.log",\
# "'$SCRIPT_DIR'""/H.08-A.01_VERIFYBAMID.sh",\
# "'$CORE_PATH'","'$VERIFY_DIR'",$1,$2,$3"\n""sleep 1s"}'
#
# ###################################################
# ### RUN VERIFYBAM ID PER CHROMOSOME - VITO ########
# ###################################################
#
# CREATE_SAMPLE_INFO_ARRAY_VERIFY_BAM ()
# {
# SAMPLE_INFO_ARRAY_VERIFY_BAM=(`awk 'BEGIN {FS="\t"; OFS="\t"} $8=="'$SAMPLE'" {split($8,smtag,"[@]"); print $1,$20,$8,$12,$15,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_SELECT_VERIFY_BAM ()
# {
# echo \
# qsub \
# -N H.09_SELECT_VERIFYBAMID_VCF_${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}_chr$CHROMOSOME \
# -hold_jid G.01_FINAL_BAM_${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]} \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}/LOGS/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}.SELECT_VERIFYBAMID_chr$CHROMOSOME.log \
# $SCRIPT_DIR/H.09_SELECT_VERIFYBAMID_VCF_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH $VERIFY_VCF \
# ${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[3]} \
# ${SAMPLE_INFO_ARRAY_VERIFY_BAM[4]} $CHROMOSOME
# }
#
# CALL_VERIFYBAMID ()
# {
# echo \
# qsub \
# -N H.09-A.01_VERIFYBAMID_${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}_chr$CHROMOSOME \
# -hold_jid H.09_SELECT_VERIFYBAMID_VCF_${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}_chr$CHROMOSOME \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}/LOGS/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}.VERIFYBAMID_chr$CHROMOSOME.log \
# $SCRIPT_DIR/H.09-A.01_VERIFYBAMID_CHR.sh \
# $CORE_PATH $VERIFY_DIR \
# ${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]} \
# $CHROMOSOME
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
# do
# CREATE_SAMPLE_INFO_ARRAY_VERIFY_BAM
# 	for CHROMOSOME in {1..22}
# 		do
# 		CALL_SELECT_VERIFY_BAM
# 		echo sleep 1s
# 		CALL_VERIFYBAMID
# 		echo sleep 1s
# 	done
# done
#
# #####################################################
# ### JOIN THE PER CHROMOSOME VERIFYBAMID REPORTS #####
# #####################################################
#
# BUILD_HOLD_ID_PATH_CAT_VERIFYBAMID_CHR ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"H.09-A.01_VERIFYBAMID_"${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}"_"${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}"_"chr$CHROMOSOME","
#  	done
#  done
# }
#
#  CAT_VERIFYBAMID_CHR ()
#  {
# echo \
# qsub \
# -N H.09-A.01-A.01_JOIN_VERIFYBAMID_${SAMPLE_INFO_ARRAY_VERIFY_BAM[5]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]} \
# $HOLD_ID_PATH \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]}/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}/LOGS/${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}_${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]}.CAT_VERIFYBAMID_CHR.log \
# $SCRIPT_DIR/H.09-A.01-A.01_CAT_VERIFYBAMID_CHR.sh \
# $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_VERIFY_BAM[0]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[1]} ${SAMPLE_INFO_ARRAY_VERIFY_BAM[2]}
#  }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
#  do
#  	CREATE_SAMPLE_INFO_ARRAY_VERIFY_BAM
# 	BUILD_HOLD_ID_PATH_CAT_VERIFYBAMID_CHR
# 	CAT_VERIFYBAMID_CHR
# 	echo sleep 1s
#  done
#
# #### JOINT CALLING AND VQSR #### ###VITO###
#
# ### CREATE A GVCF ".list" file for each sample
#
# CREATE_FAMILY_INFO_ARRAY ()
# {
# FAMILY_INFO_ARRAY=(`awk 'BEGIN {FS="\t"; OFS="\t"} $20=="'$FAMILY'" {split($8,smtag,"[@]"); print $1,smtag[1]"_"smtag[2],$20,$12,$18}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CREATE_GVCF_LIST ()
# {
# awk 'BEGIN {OFS="/"} $20=="'$FAMILY'" {print "'$CORE_PATH'",$1,$20,$8,"GVCF",$8".g.vcf.gz"}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort \
# | uniq \
# >| $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/$FAMILY/$FAMILY".gvcf.list"
# }
#
# CREATE_FAMILY_SAMPLE_LIST ()
# {
# awk '$20=="'$FAMILY'" {print $8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort \
# | uniq \
# >| $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/$FAMILY/$FAMILY".sample.list"
# }
#
# BUILD_HOLD_ID_PATH_GENOTYPE_GVCF ()
# {
# ##NEED FULL LIST OF SAMPLES IN FAMILY FOR THE INNER FOR LOOP.  THE ${FAMILY_INFO_ARRAY[1]} WON'T WORK CONSIDERING THAT IS SPECIFIC FOR ONE SAMPLE
#
# for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# do
# HOLD_ID_PATH="-hold_jid "
# for SAMPLE in $(awk 'BEGIN {FS="\t"; OFS="\t"} $20=="'$FAMILY'" {print $8}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq);
# 	do
# 		HOLD_ID_PATH=$HOLD_ID_PATH"H.01-A.01_HAPLOTYPE_CALLER_GATHER_"$PROJECT"_"${FAMILY_INFO_ARRAY[1]}","
# 	done
# done
# }
#
# CALL_GENOTYPE_GVCF ()
# {
# for CHROM in {{1..22},{X,Y}};
# do
# echo \
# qsub \
# -N I.01_GENOTYPE_GVCF_SCATTER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}_chr$CHROM \
# $HOLD_ID_PATH \
# -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.GENOTYPE_GVCF_chr$CHROM.log \
# $SCRIPT_DIR/I.01_GENOTYPE_GVCF_SCATTER.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]} ${FAMILY_INFO_ARRAY[4]} $CHROM $CONTROL_REPO
# echo sleep 1s
# done
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} NR>1 {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq);
# do
# 	 CREATE_FAMILY_INFO_ARRAY
# 	 CREATE_GVCF_LIST
#  CREATE_FAMILY_SAMPLE_LIST
# BUILD_HOLD_ID_PATH_GENOTYPE_GVCF
# CALL_GENOTYPE_GVCF
# done
#
# ########################################################################################
# ##### GATHER UP THE PER FAMILY PER CHROMOSOME GVCF FILES INTO A SINGLE FAMILY GVCF #####
# ########################################################################################
#
# BUILD_HOLD_ID_PATH_GENOTYPE_GVCF_GATHER()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHR in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"I.01_GENOTYPE_GVCF_SCATTER_"$FAMILY"_"$PROJECT"_chr"$CHR","
#  	done
#  done
# }
#
#
# CALL_GENOTYPE_GVCF_GATHER ()
# {
# echo \
# qsub \
# -N I.01-A.01_GENOTYPE_GVCF_GATHER_${FAMILY_INFO_ARRAY[0]}_${FAMILY_INFO_ARRAY[2]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.GENOTYPE_GVCF_GATHER.log \
#  $SCRIPT_DIR/I.01-A.01_GENOTYPE_GVCF_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
#  	# echo $FAMILY
# 	BUILD_HOLD_ID_PATH_GENOTYPE_GVCF_GATHER
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_GENOTYPE_GVCF_GATHER
# 	echo sleep 1s
#  done
#
# ##########################################################
# ################END VITO##################################
# ##########################################################
#
# #####################################################################################################
# ##### Run Variant Recalibrator for the SNP model, this is done in parallel with the INDEL model #####
# #####################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12,$18}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","J.01_VARIANT_RECALIBRATOR_SNP_"$2"_"$1,\
# "-hold_jid","I.01-A.01_GENOTYPE_GVCF_GATHER_"$1"_"$2,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_RECALIBRATOR_SNP.log",\
# "'$SCRIPT_DIR'""/J.01_VARIANT_RECALIBRATOR_SNP.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,"'$HAPMAP'","'$OMNI_1KG'","'$HI_CONF_1KG_PHASE1_SNP'""\n""sleep 1s"}'
#
# ### Run Variant Recalibrator for the INDEL model, this is done in parallel with the SNP model
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","J.02_VARIANT_RECALIBRATOR_INDEL_"$2"_"$1,\
# "-hold_jid","I.01-A.01_GENOTYPE_GVCF_GATHER_"$1"_"$2,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_RECALIBRATOR_INDEL.log",\
# "'$SCRIPT_DIR'""/J.02_VARIANT_RECALIBRATOR_INDEL.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,"'$MILLS_1KG_GOLD_INDEL'""\n""sleep 1s"}'
#
# ### Run Apply Recalbration with the SNP model to the VCF file
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","K.01_APPLY_RECALIBRATION_SNP_"$2"_"$1,\
# "-hold_jid","J.01_VARIANT_RECALIBRATOR_SNP_"$2"_"$1",""J.02_VARIANT_RECALIBRATOR_INDEL_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".APPLY_RECALIBRATION_SNP.log",\
# "'$SCRIPT_DIR'""/K.01_APPLY_RECALIBRATION_SNP.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ### Run Apply Recalibration with the INDEL model to the VCF file.
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","L.01_APPLY_RECALIBRATION_INDEL_"$2"_"$1,\
# "-hold_jid","K.01_APPLY_RECALIBRATION_SNP_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".APPLY_RECALIBRATION_INDEL.log",\
# "'$SCRIPT_DIR'""/L.01_APPLY_RECALIBRATION_INDEL.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ################################################
# ##### SCATTER GATHER FOR ADDING ANNOTATION #####
# ################################################
#
# CREATE_FAMILY_INFO_ARRAY ()
# {
# FAMILY_INFO_ARRAY=(`awk 'BEGIN {FS="\t"; OFS="\t"} $20=="'$FAMILY'" {print $1,$8,$20,$12,$18}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_VARIANT_ANNOTATOR ()
# {
# echo \
# qsub \
# -N P.01_VARIANT_ANNOTATOR_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}_$CHROMOSOME \
# -hold_jid L.01_APPLY_RECALIBRATION_INDEL_${FAMILY_INFO_ARRAY[2]}"_"${FAMILY_INFO_ARRAY[0]} \
# -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.VARIANT_ANNOTATOR_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01_VARIANT_ANNOTATOR_SCATTER.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH $PED_FILE \
# ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]} $CHROMOSOME $PHASE3_1KG_AUTOSOMES
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq);
# do
# CREATE_FAMILY_INFO_ARRAY
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_VARIANT_ANNOTATOR
# 		echo sleep 1s
# 	done
# done
#
# ##############################################################################################
# ##### GATHER UP THE PER FAMILY PER CHROMOSOME ANNOTATED VCF FILES INTO A SINGLE VCF FILE #####
# ##############################################################################################
#
# BUILD_HOLD_ID_PATH_ADD_MORE_ANNOTATION ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01_VARIANT_ANNOTATOR_"$FAMILY"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# CALL_VARIANT_ANNOTATOR_GATHER ()
# {
# echo \
# qsub \
# -N P.01-A.01_VARIANT_ANNOTATOR_GATHER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.ADD_MORE_ANNOTATION_GATHER.log \
#  $SCRIPT_DIR/P.01-A.01_VARIANT_ANNOTATOR_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
# 	BUILD_HOLD_ID_PATH_ADD_MORE_ANNOTATION
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_VARIANT_ANNOTATOR_GATHER
# 	echo sleep 1s
#  done
#
# ############################################################################################################
# ##### DO PER CHROMOSOME VARIANT TO TABLE FOR COHORT ########################################################
# ############################################################################################################
#
# CREATE_FAMILY_ONLY_ARRAY ()
# {
# FAMILY_ONLY_ARRAY=(`awk 'BEGIN {FS="\t"; OFS="\t"} $20=="'$FAMILY'" {print $1,$20,$12,$18,$17}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_VARIANT_TO_TABLE_COHORT_ALL_SITES ()
# {
# echo \
# qsub \
# -N P.01-A.02_VARIANT_TO_TABLE_COHORT_ALL_SITES_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -hold_jid P.01_VARIANT_ANNOTATOR_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -o $CORE_PATH/${FAMILY_ONLY_ARRAY[0]}/${FAMILY_ONLY_ARRAY[1]}/LOGS/${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}.VARIANT_TO_TABLE_COHORT_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01-A.02_VARIANT_TO_TABLE_COHORT_ALL_SITES_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${FAMILY_ONLY_ARRAY[0]} ${FAMILY_ONLY_ARRAY[1]} ${FAMILY_ONLY_ARRAY[2]} $CHROMOSOME
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"} {print $1}' $PED_FILE | sort | uniq );
# do
# CREATE_FAMILY_ONLY_ARRAY
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_VARIANT_TO_TABLE_COHORT_ALL_SITES
# 		echo sleep 1s
# 		done
# 	done
#
# ################################################################################################################
# ##### GATHER PER CHROMOSOME VARIANT TO TABLE FOR COHORT ########################################################
# ################################################################################################################
#
# BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_COHORT_GATHER ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01-A.02_VARIANT_TO_TABLE_COHORT_ALL_SITES_"$FAMILY"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# CALL_VARIANT_TO_TABLE_COHORT_GATHER ()
# {
# echo \
# qsub \
# -N T.18_VARIANT_TO_TABLE_COHORT_ALL_SITES_GATHER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.VARIANT_TO_TABLE_COHORT_ALL_SITES_GATHER.log \
#  $SCRIPT_DIR/T.18_VARIANT_TO_TABLE_COHORT_ALL_SITES_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
# 	BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_COHORT_GATHER
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_VARIANT_TO_TABLE_COHORT_GATHER
# 	echo sleep 1s
#  done
#
# ##############################################################################################################
# ## BGZIP INITIAL JOINT CALLED VCF TABLE ######################################################################
# ##############################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","T.18-A.01_VARIANT_TO_TABLE_BGZIP_COHORT_ALL_SITES_"$2"_"$1,\
# "-hold_jid","T.18_VARIANT_TO_TABLE_COHORT_ALL_SITES_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_TO_TABLE_BGZIP_COHORT_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.18-A.01_VARIANT_TO_TABLE_BGZIP_COHORT_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2"\n""sleep 1s"}'
#
# ##############################################################################################################
# ## TABIX INDEX INITIAL JOINT CALLED VCF TABLE ################################################################
# ##############################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","T.18-A.01-A.01_VARIANT_TO_TABLE_TABIX_COHORT_ALL_SITES_"$2"_"$1,\
# "-hold_jid","T.18-A.01_VARIANT_TO_TABLE_BGZIP_COHORT_ALL_SITES_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_TO_TABLE_TABIX_COHORT_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.18-A.01-A.01_VARIANT_TO_TABLE_TABIX_COHORT_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2"\n""sleep 1s"}'
#
#
# #################################################################################
# ########### RUNNING FILTER TO FAMILY ALL SITES BY CHROMOSOME ####################
# #################################################################################
#
# CALL_FILTER_TO_FAMILY_ALL_SITES ()
# {
# echo \
# qsub \
# -N P.01-A.03_FILTER_TO_FAMILY_ALL_SITES_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -hold_jid P.01_VARIANT_ANNOTATOR_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -o $CORE_PATH/${FAMILY_ONLY_ARRAY[0]}/${FAMILY_ONLY_ARRAY[1]}/LOGS/${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}.FILTER_TO_FAMILY_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01-A.03_FILTER_TO_FAMILY_ALL_SITES_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${FAMILY_ONLY_ARRAY[0]} ${FAMILY_ONLY_ARRAY[1]} ${FAMILY_ONLY_ARRAY[2]} $CHROMOSOME
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"} {print $1}' $PED_FILE | sort | uniq );
# do
# CREATE_FAMILY_ONLY_ARRAY
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_FILTER_TO_FAMILY_ALL_SITES
# 		echo sleep 1s
# 		done
# 	done
#
# #####################################################################################################
# ##### GATHER UP THE PER FAMILY PER CHROMOSOME FILTER TO FAMILY VCF FILES INTO A SINGLE VCF FILE #####
# #####################################################################################################
#
# BUILD_HOLD_ID_PATH_FILTER_TO_FAMILY_VCF ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01-A.03_FILTER_TO_FAMILY_ALL_SITES_"$FAMILY"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# CALL_FILTER_TO_FAMILY_VCF_GATHER ()
# {
# echo \
# qsub \
# -N T.03-1_FILTER_TO_FAMILY_ALL_SITES_GATHER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.FILTER_TO_FAMILY_ALL_SITES_GATHER.log \
#  $SCRIPT_DIR/T.03-1_FILTER_TO_FAMILY_ALL_SITES_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
# 	BUILD_HOLD_ID_PATH_FILTER_TO_FAMILY_VCF
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_FILTER_TO_FAMILY_VCF_GATHER
# 	echo sleep 1s
#  done
#
# ############################################################################################################
# ##### DO PER CHROMOSOME VARIANT TO TABLE FOR FAMILY ########################################################
# ############################################################################################################
#
# CALL_VARIANT_TO_TABLE_FAMILY_ALL_SITES ()
# {
# echo \
# qsub \
# -N T.03-2_VARIANT_TO_TABLE_FAMILY_ALL_SITES_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -hold_jid P.01-A.03_FILTER_TO_FAMILY_ALL_SITES_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -o $CORE_PATH/${FAMILY_ONLY_ARRAY[0]}/${FAMILY_ONLY_ARRAY[1]}/LOGS/${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}.VARIANT_TO_TABLE_FAMILY_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/T.03-2_VARIANT_TO_TABLE_FAMILY_ALL_SITES_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${FAMILY_ONLY_ARRAY[0]} ${FAMILY_ONLY_ARRAY[1]} ${FAMILY_ONLY_ARRAY[2]} $CHROMOSOME
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"} {print $1}' $PED_FILE | sort | uniq );
# do
# CREATE_FAMILY_ONLY_ARRAY
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_VARIANT_TO_TABLE_FAMILY_ALL_SITES
# 		echo sleep 1s
# 		done
# 	done
#
# ################################################################################################################
# ##### GATHER PER CHROMOSOME VARIANT TO TABLE FOR FAMILY ########################################################
# ################################################################################################################
#
# BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_FAMILY_GATHER ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"T.03-2_VARIANT_TO_TABLE_FAMILY_ALL_SITES_"$FAMILY"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
#
# CALL_VARIANT_TO_TABLE_FAMILY_GATHER ()
# {
# echo \
# qsub \
# -N T.03-2-A.01_VARIANT_TO_TABLE_FAMILY_ALL_SITES_GATHER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.VARIANT_TO_TABLE_ALL_SITES_GATHER.log \
#  $SCRIPT_DIR/T.03-2-A.01_VARIANT_TO_TABLE_FAMILY_ALL_SITES_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
# 	BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_FAMILY_GATHER
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_VARIANT_TO_TABLE_FAMILY_GATHER
# 	echo sleep 1s
#  done
#
# ##############################################################################################################
# ## BGZIP FAMILY ONLY VCF TABLE ###############################################################################
# ##############################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","T.03-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_FAMILY_ALL_SITES_"$2"_"$1,\
# "-hold_jid","T.03-2-A.01_VARIANT_TO_TABLE_FAMILY_ALL_SITES_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_TO_TABLE_BGZIP_FAMILY_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.03-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_FAMILY_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2"\n""sleep 1s"}'
#
# ##############################################################################################################
# ## TABIX INDEX FAMILY ONLY VCF TABLE #########################################################################
# ##############################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","T.03-2-A.01-A.01-A.01_VARIANT_TO_TABLE_TABIX_FAMILY_ALL_SITES_"$2"_"$1,\
# "-hold_jid","T.03-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_FAMILY_ALL_SITES_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".VARIANT_TO_TABLE_TABIX_FAMILY_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.03-2-A.01-A.01-A.01_VARIANT_TO_TABLE_TABIX_FAMILY_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2"\n""sleep 1s"}'
#
# #################################################################################
# ########### RUNNING FILTER TO SAMPLE ALL SITES BY CHROMOSOME ####################
# #################################################################################
#
# # CREATE_SAMPLE_INFO_ARRAY_2 ()
# # {
# # SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} $8=="'$SAMPLE'" {split($8,smtag,"[@]"); print $1,$8,$20,$12,$18,smtag[1]"_"smtag[2]}' \
# # ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# # for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
# # do
# # CREATE_SAMPLE_INFO_ARRAY_2
# # 	for CHROMOSOME in {{1..22},{X,Y}}
# # 		do
# # 		CALL_FILTER_TO_SAMPLE_ALL_SITES
# # 		echo sleep 1s
# # 		done
# # 	done
#
# CREATE_SAMPLE_INFO_ARRAY_2 ()
# {
# SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_FILTER_TO_SAMPLE_ALL_SITES ()
# {
# echo \
# qsub \
# -N P.01-A.04_FILTER_TO_SAMPLE_ALL_SITES_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -hold_jid P.01_VARIANT_ANNOTATOR_${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.FILTER_TO_SAMPLE_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01-A.04_FILTER_TO_SAMPLE_ALL_SITES_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]} $CHROMOSOME
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
# do
# CREATE_SAMPLE_INFO_ARRAY_2
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_FILTER_TO_SAMPLE_ALL_SITES
# 		echo sleep 1s
# 		done
# 	done
#
# #####################################################################################################
# ##### GATHER UP THE PER SAMPLE PER CHROMOSOME FILTER TO SAMPLE VCF FILES INTO A SINGLE VCF FILE #####
# #####################################################################################################
#
# BUILD_HOLD_ID_PATH_FILTER_TO_SAMPLE_VCF ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01-A.04_FILTER_TO_SAMPLE_ALL_SITES_"$SAMPLE"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# # CALL_FILTER_TO_SAMPLE_VCF_GATHER ()
# # {
# # echo \
# # qsub \
# # -N T.06-1_FILTER_TO_SAMPLE_ALL_SITES_GATHER_${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]} \
# #  ${HOLD_ID_PATH} \
# #  -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[2]}/${SAMPLE_INFO_ARRAY_2[1]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.FILTER_TO_SAMPLE_ALL_SITES_GATHER.log \
# #  $SCRIPT_DIR/T.06-1_FILTER_TO_SAMPLE_ALL_SITES_GATHER.sh \
# #  $JAVA_1_8 $GATK_DIR $CORE_PATH \
# #  ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[3]}
# # }
#
# # SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# # print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}'
#
# CALL_FILTER_TO_SAMPLE_VCF_GATHER ()
# {
# echo \
# qsub \
# -N T.06-1_FILTER_TO_SAMPLE_ALL_SITES_GATHER_${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.FILTER_TO_SAMPLE_ALL_SITES_GATHER.log \
#  $SCRIPT_DIR/T.06-1_FILTER_TO_SAMPLE_ALL_SITES_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]}
# }
#
# # for SAMPLE in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $8}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
# #  do
# #  	BUILD_HOLD_ID_PATH_FILTER_TO_SAMPLE_VCF
# # 	CREATE_SAMPLE_INFO_ARRAY_2
# # 	CALL_FILTER_TO_SAMPLE_VCF_GATHER
# # 	echo sleep 1s
# #  done
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
#  do
#  	BUILD_HOLD_ID_PATH_FILTER_TO_SAMPLE_VCF
# 	CREATE_SAMPLE_INFO_ARRAY_2
# 	CALL_FILTER_TO_SAMPLE_VCF_GATHER
# 	echo sleep 1s
#  done
#
# ############################################################################################################
# ##### DO PER CHROMOSOME VARIANT TO TABLE FOR SAMPLE ########################################################
# ############################################################################################################
#
# # CREATE_SAMPLE_INFO_ARRAY_2 ()
# # {
# # SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# # print $1,$20,$8,$12,$16,smtag[1]"_"smtag[2]}' \
# # ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# CALL_VARIANT_TO_TABLE_SAMPLE_ALL_SITES ()
# {
# echo \
# qsub \
# -N T.06-2_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -hold_jid P.01-A.04_FILTER_TO_SAMPLE_ALL_SITES_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.VARIANT_TO_TABLE_SAMPLE_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/T.06-2_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]} $CHROMOSOME
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
# do
# CREATE_SAMPLE_INFO_ARRAY_2
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_VARIANT_TO_TABLE_SAMPLE_ALL_SITES
# 		echo sleep 1s
# 		done
# 	done
#
# ################################################################################################################
# ##### GATHER PER CHROMOSOME VARIANT TO TABLE FOR SAMPLE ########################################################
# ################################################################################################################
#
# BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_SAMPLE_GATHER ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"T.06-2_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_"$SAMPLE"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# CALL_VARIANT_TO_TABLE_SAMPLE_GATHER ()
# {
# echo \
# qsub \
# -N T.06-2-A.01_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_GATHER_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.VARIANT_TO_TABLE_SAMPLE_ALL_SITES_GATHER.log \
#  $SCRIPT_DIR/T.06-2-A.01_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]}
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
#  do
# 	BUILD_HOLD_ID_PATH_VARIANT_TO_TABLE_SAMPLE_GATHER
# 	CREATE_SAMPLE_INFO_ARRAY_2
# 	CALL_VARIANT_TO_TABLE_SAMPLE_GATHER
# 	echo sleep 1s
#  done
#
# #################################################################################################################
# ## ## BGZIP SAMPLE ONLY VCF TABLE ###############################################################################
# #################################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","T.06-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_SAMPLE_ALL_SITES_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","T.06-2-A.01_VARIANT_TO_TABLE_SAMPLE_ALL_SITES_GATHER_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".VARIANT_TO_TABLE_BGZIP_SAMPLE_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.06-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_SAMPLE_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# #################################################################################################################
# ## ## TABIX INDEX SAMPLE ONLY VCF TABLE #########################################################################
# #################################################################################################################
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","T.06-2-A.01-A.01-A.01_VARIANT_TO_TABLE_TABIX_SAMPLE_ALL_SITES_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","T.06-2-A.01-A.01_VARIANT_TO_TABLE_BGZIP_SAMPLE_ALL_SITES_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".VARIANT_TO_TABLE_TABIX_SAMPLE_ALL_SITES.log",\
# "'$SCRIPT_DIR'""/T.06-2-A.01-A.01-A.01_VARIANT_TO_TABLE_TABIX_SAMPLE_ALL_SITES.sh",\
# "'$TABIX_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ###########################################################################################
# ########### RUNNING FILTER TO SAMPLE ALL SITES BY CHROMOSOME ON TARGET ####################
# ###########################################################################################
#
# # CREATE_SAMPLE_INFO_ARRAY_2 ()
# # {
# # SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} $8=="'$SAMPLE'" {print $1,$8,$20,$12,$18}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# CREATE_SAMPLE_INFO_ARRAY_2 ()
# {
# SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# print $1,$20,$8,$12,$18,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# }
#
# CALL_FILTER_TO_SAMPLE_ALL_SITES_ON_TARGET ()
# {
# echo \
# qsub \
# -N P.01-A.05_FILTER_TO_SAMPLE_ALL_SITES_TARGET_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -hold_jid P.01_VARIANT_ANNOTATOR_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]}_$CHROMOSOME \
# -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.FILTER_TO_SAMPLE_ALL_SITES_TARGET_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01-A.05_FILTER_TO_SAMPLE_ALL_SITES_TARGET_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]} $CHROMOSOME
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
# do
# CREATE_SAMPLE_INFO_ARRAY_2
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_FILTER_TO_SAMPLE_ALL_SITES_ON_TARGET
# 		echo sleep 1s
# 		done
# 	done
#
# ###############################################################################################################
# ##### GATHER UP THE PER SAMPLE PER CHROMOSOME FILTER TO SAMPLE VCF FILES ON TARGET INTO A SINGLE VCF FILE #####
# ###############################################################################################################
#
# BUILD_HOLD_ID_PATH_FILTER_TO_SAMPLE_VCF_TARGET ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01-A.05_FILTER_TO_SAMPLE_ALL_SITES_TARGET_"$SAMPLE"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# # CREATE_SAMPLE_INFO_ARRAY_2 ()
# # {
# # SAMPLE_INFO_ARRAY_2=(`awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); if (smtag[1]"_"smtag[2]=="'$SAMPLE'") \
# # print $1,$20,$8,$12,$18,smtag[1]"_"smtag[2]}' \
# # ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# CALL_FILTER_TO_SAMPLE_VCF_TARGET_GATHER ()
# {
# echo \
# qsub \
# -N T.15_FILTER_TO_SAMPLE_ALL_SITES_TARGET_GATHER_${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE}_${SAMPLE_INFO_ARRAY_2[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${SAMPLE_INFO_ARRAY_2[0]}/${SAMPLE_INFO_ARRAY_2[1]}/${SAMPLE_INFO_ARRAY_2[2]}/LOGS/${SAMPLE_INFO_ARRAY_2[1]}_${SAMPLE_INFO_ARRAY_2[2]}_${SAMPLE_INFO_ARRAY_2[0]}.FILTER_TO_SAMPLE_ALL_SITES_TARGET_GATHER.log \
#  $SCRIPT_DIR/T.15_FILTER_TO_SAMPLE_ALL_SITES_TARGET_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${SAMPLE_INFO_ARRAY_2[0]} ${SAMPLE_INFO_ARRAY_2[1]} ${SAMPLE_INFO_ARRAY_2[2]} ${SAMPLE_INFO_ARRAY_2[3]}
# }
#
# for SAMPLE in $(awk 'BEGIN {FS=","} NR>1 {if ($8~"@") {split($8,smtag,"[@]"); print smtag[1]"_"smtag[2]} else print $8"_"}' $SAMPLE_SHEET | sort | uniq );
#  do
#  	BUILD_HOLD_ID_PATH_FILTER_TO_SAMPLE_VCF_TARGET
# 	CREATE_SAMPLE_INFO_ARRAY_2
# 	CALL_FILTER_TO_SAMPLE_VCF_TARGET_GATHER
# 	echo sleep 1s
#  done
#
# ###########################################################################################
# ########### RUNNING FILTER TO FAMILY ALL SITES BY CHROMOSOME ON TARGET ####################
# ###########################################################################################
#
# # CREATE_FAMILY_ONLY_ARRAY ()
# # {
# # FAMILY_ONLY_ARRAY=(`awk 'BEGIN {FS="\t"; OFS="\t"} $20=="'$FAMILY'" {print $1,$20,$12,$18,$17}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt`)
# # }
#
# CALL_FILTER_TO_FAMILY_ON_TARGET_VARIANT ()
# {
# echo \
# qsub \
# -N P.01-A.06_FILTER_TO_FAMILY_TARGET_VARIANT_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -hold_jid P.01_VARIANT_ANNOTATOR_${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}_$CHROMOSOME \
# -o $CORE_PATH/${FAMILY_ONLY_ARRAY[0]}/${FAMILY_ONLY_ARRAY[1]}/LOGS/${FAMILY_ONLY_ARRAY[1]}_${FAMILY_ONLY_ARRAY[0]}.FILTER_TO_FAMILY_ALL_SITES_$CHROMOSOME.log \
# $SCRIPT_DIR/P.01-A.06_FILTER_TO_FAMILY_ON_TARGET_VARIANT_ONLY_CHR.sh \
# $JAVA_1_8 $GATK_DIR $CORE_PATH \
# ${FAMILY_ONLY_ARRAY[0]} ${FAMILY_ONLY_ARRAY[1]} ${FAMILY_ONLY_ARRAY[2]} ${FAMILY_ONLY_ARRAY[4]} $CHROMOSOME
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"} {print $1}' $PED_FILE | sort | uniq );
# do
# CREATE_FAMILY_ONLY_ARRAY
# 	for CHROMOSOME in {{1..22},{X,Y}}
# 		do
# 		CALL_FILTER_TO_FAMILY_ON_TARGET_VARIANT
# 		echo sleep 1s
# 		done
# 	done
#
# ###############################################################################################################
# ##### GATHER UP THE PER FAMILY PER CHROMOSOME ON TARGET FILTER TO FAMILY VCF FILES INTO A SINGLE VCF FILE #####
# ###############################################################################################################
#
# BUILD_HOLD_ID_PATH_FILTER_TO_FAMILY_VCF_TARGET_VARIANT ()
# {
# 	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq )
# 	do
# 	HOLD_ID_PATH="-hold_jid "
# 	for CHROMOSOME in {{1..22},{X,Y}};
#  	do
#  		HOLD_ID_PATH=$HOLD_ID_PATH"P.01-A.06_FILTER_TO_FAMILY_TARGET_VARIANT_"$FAMILY"_"$PROJECT"_"$CHROMOSOME","
#  	done
#  done
# }
#
# CALL_FILTER_TO_FAMILY_VCF_GATHER_TARGET_VARIANT ()
# {
# echo \
# qsub \
# -N T.09-1_FILTER_TO_FAMILY_ON_TARGET_VARIANT_GATHER_${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]} \
#  ${HOLD_ID_PATH} \
#  -o $CORE_PATH/${FAMILY_INFO_ARRAY[0]}/${FAMILY_INFO_ARRAY[2]}/LOGS/${FAMILY_INFO_ARRAY[2]}_${FAMILY_INFO_ARRAY[0]}.FILTER_TO_FAMILY_ON_TARGET_VARIANT_GATHER.log \
#  $SCRIPT_DIR/T.09-1_FILTER_TO_FAMILY_ON_TARGET_VARIANT_ONLY_GATHER.sh \
#  $JAVA_1_8 $GATK_DIR $CORE_PATH \
#  ${FAMILY_INFO_ARRAY[0]} ${FAMILY_INFO_ARRAY[2]} ${FAMILY_INFO_ARRAY[3]}
# }
#
# for FAMILY in $(awk 'BEGIN {FS="\t"; OFS="\t"} {print $20}' ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt | sort | uniq)
#  do
# 	BUILD_HOLD_ID_PATH_FILTER_TO_FAMILY_VCF_TARGET_VARIANT
# 	CREATE_FAMILY_INFO_ARRAY
# 	CALL_FILTER_TO_FAMILY_VCF_GATHER_TARGET_VARIANT
# 	echo sleep 1s
#  done
#
# ###############################
# ##### DOING VCF BREAKOUTS #####
# ###############################
#
# ### SUBSETTING FROM COHORT (FAMILY PLUS CONTROL SET) VCF ###
#
# # FILTER TO JUST VARIANT SITES
# # I think Molly might like this output, but if not, then don't have to generate it.
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","S.01_FILTER_COHORT_VARIANT_ONLY_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".FILTER_COHORT_VARIANT_ONLY.log",\
# "'$SCRIPT_DIR'""/S.01_FILTER_COHORT_VARIANT_ONLY.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # FILTER TO JUST PASSING VARIANT SITES
# # I think statgen is using this for some of their programs
# # If not needed then don't generate
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | awk '{print "qsub","-N","S.02_FILTER_COHORT_VARIANT_ONLY_PASS_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".FILTER_COHORT_VARIANT_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.02_FILTER_COHORT_VARIANT_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # FILTER TO JUST PASSING BIALLELIC SNV SITES
# # TEMPORARY FILE USED FOR PCA AND RELATEDNESS
#
# awk 'BEGIN {OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1,1 -k 2,2 \
# | uniq \
# | awk '{print "qsub","-N","S.03_FILTER_COHORT_SNV_ONLY_PASS_BIALLELIC_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".FILTER_COHORT_SNV_ONLY_PASS_BIALLELIC.log",\
# "'$SCRIPT_DIR'""/S.03_FILTER_COHORT_SNV_ONLY_PASS_BIALLELIC.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# # RUN HUAS WORKFLOW FOR PCA AND RELATEDNESS
#
# awk 'BEGIN {OFS="\t"} {print $1,$20,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1,1 -k 2,2 \
# | uniq \
# | awk '{print "qsub","-N","S.03-A.01_PCA_RELATEDNESS_"$2"_"$1,\
# "-hold_jid","S.03_FILTER_COHORT_SNV_ONLY_PASS_BIALLELIC_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/LOGS/"$2"_"$1".PCA_RELATEDNESS.log",\
# "'$SCRIPT_DIR'""/S.03-A.01_PCA_RELATEDNESS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'","'$VCFTOOLS_DIR'","'$PLINK2_DIR'","'$KING_DIR'",$1,$2,$3,"'$PED_FILE'","'$CONTROL_PED_FILE'""\n""sleep 1s"}'
#
# #################################
# ### SUBSETTING TO SAMPLE VCFS ###
# #################################
#
# ## SUBSET TO SAMPLE VARIANTS ONLY ON BAIT
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.07_FILTER_TO_SAMPLE_VARIANTS_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/LOGS/"$3"_"$1".FILTER_TO_VARIANTS.log",\
# "'$SCRIPT_DIR'""/S.07_FILTER_TO_SAMPLE_VARIANTS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 3s"}'
#
# ## SUBSET TO SAMPLE PASSING SNVS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09_FILTER_TO_SNV_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_SNV_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.09_FILTER_TO_SAMPLE_SNV_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO SAMPLE PASSING INDELS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.10_FILTER_TO_INDEL_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_INDEL_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.10_FILTER_TO_SAMPLE_INDEL_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO SAMPLE PASSING MIXED
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.11_FILTER_TO_MIXED_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_MIXED_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.11_FILTER_TO_SAMPLE_MIXED_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO TARGET SNV ONLY PASS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.12_FILTER_TO_SAMPLE_TARGET_SNV_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TARGET_SNV_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.12_FILTER_TO_SAMPLE_TARGET_SNV_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO TARGET INDEL ONLY PASS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.13_FILTER_TO_SAMPLE_TARGET_INDEL_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TARGET_INDEL_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.13_FILTER_TO_SAMPLE_TARGET_INDEL_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO TARGET MIXED ONLY PASS
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.14_FILTER_TO_SAMPLE_TARGET_MIXED_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TARGET_MIXED_ONLY_PASS.log",\
# "'$SCRIPT_DIR'""/S.14_FILTER_TO_SAMPLE_TARGET_MIXED_ONLY_PASS.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 1s"}'
#
# ## SUBSET TO SAMPLE VARIANTS ONLY ON TARGET
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.16_FILTER_TO_SAMPLE_VARIANTS_TARGET_"smtag[1]"_"smtag[2]"_"$1,\
# "-hold_jid","P.01-A.01_VARIANT_ANNOTATOR_GATHER_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/LOGS/"$3"_"$1".FILTER_TO_VARIANTS_TARGET.log",\
# "'$SCRIPT_DIR'""/S.16_FILTER_TO_SAMPLE_VARIANTS_TARGET.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4"\n""sleep 3s"}'
#
#
# ####################
# ### TITV SECTION ###
# ####################
#
# # BREAK DOWN TO ALL PASSING SNV THAT FALL IN TITV BED FILE
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$15}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.01_FILTER_TO_SAMPLE_TITV_VCF_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09_FILTER_TO_SNV_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TITV_VCF.log",\
# "'$SCRIPT_DIR'""/S.09-A.01_FILTER_TO_SAMPLE_TITV_VCF.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,$5"\n""sleep 1s"}'
#
# # BREAK DOWN TO ALL PASSING SNV THAT FALL IN TITV BED FILE AND OVERLAP WITH DBSNP 129
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$15}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.02_FILTER_TO_SAMPLE_TITV_VCF_KNOWN_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09_FILTER_TO_SNV_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TITV_VCF_KNOWN.log",\
# "'$SCRIPT_DIR'""/S.09-A.02_FILTER_TO_SAMPLE_TITV_VCF_KNOWN.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,$5,"'$DBSNP_129'""\n""sleep 1s"}'
#
# # BREAK DOWN TO ALL PASSING SNV THAT FALL IN TITV BED FILE AND DO NOT OVERLAP WITH DBSNP 129
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$12,$15}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.03_FILTER_TO_SAMPLE_TITV_VCF_NOVEL_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09_FILTER_TO_SNV_ONLY_PASS_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".FILTER_TO_TITV_VCF_NOVEL.log",\
# "'$SCRIPT_DIR'""/S.09-A.03_FILTER_TO_SAMPLE_TITV_VCF_NOVEL.sh",\
# "'$JAVA_1_8'","'$GATK_DIR'","'$CORE_PATH'",$1,$2,$3,$4,$5,"'$DBSNP_129'""\n""sleep 1s"}'
#
# ### RUN TITV FOR THE PASSING SNVS THAT FALL IN UCSC CODING REGIONS THAT TOUCH EITHER THE BED OR TARGET FILE
#
# ## ALL SNVS TITV
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.01-A.01_TITV_ALL_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09-A.01_FILTER_TO_SAMPLE_TITV_VCF_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".RUN_TITV_ALL.log",\
# "'$SCRIPT_DIR'""/S.09-A.01-A.01_TITV_ALL.sh",\
# "'$SAMTOOLS_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ## ALL KNOWN SNVS TITV
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.02-A.01_TITV_KNOWN_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09-A.02_FILTER_TO_SAMPLE_TITV_VCF_KNOWN_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".RUN_TITV_KNOWN.log",\
# "'$SCRIPT_DIR'""/S.09-A.02-A.01_TITV_KNOWN.sh",\
# "'$SAMTOOLS_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ## ALL NOVEL SNVS TITV
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.09-A.03-A.01_TITV_NOVEL_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.09-A.03_FILTER_TO_SAMPLE_TITV_VCF_NOVEL_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".RUN_TITV_NOVEL.log",\
# "'$SCRIPT_DIR'""/S.09-A.03-A.01_TITV_NOVEL.sh",\
# "'$SAMTOOLS_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 1s"}'
#
# ###################
# ##### ANNOVAR #####
# ###################
#
# ## RUN ANNOVAR
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1,1 -k 2,2 -k 3,3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.16-A.01_RUN_ANNOVAR_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.16_FILTER_TO_SAMPLE_VARIANTS_TARGET_"smtag[1]"_"smtag[2]"_"$1,\
# "-pe slots 5",\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".RUN_ANNOVAR.log",\
# "'$SCRIPT_DIR'""/S.16-A.01_RUN_ANNOVAR.sh",\
# "'$JAVA_1_6'","'$CIDRSEQSUITE_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 3s"}'
#
# ## REFORMAT ANNOVAR
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1,1 -k 2,2 -k 3,3 \
# | uniq \
# | awk '{split($3,smtag,"[@]"); print "qsub","-N","S.16-A.01-A.01_REFORMAT_ANNOVAR_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-hold_jid","S.16-A.01_RUN_ANNOVAR_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/"$2"/"$3"/LOGS/"$3"_"$2"_"$1".REFORMAT_ANNOVAR.log",\
# "'$SCRIPT_DIR'""/S.16-A.01-A.01_REFORMAT_ANNOVAR.sh",\
# "'$ANNOVAR_DIR'","'$CORE_PATH'",$1,$2,$3"\n""sleep 3s"}'
#
# ######### FINISH UP #################
#
# ### QC REPORT PREP ###
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {print $1,$20,$8,$21,$22,$23,$24}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 -k 3 \
# | uniq \
# | awk 'BEGIN {FS="\t"}
# {split($3,smtag,"[@]"); print "qsub","-N","X.01-QC_REPORT_PREP_"$1"_"smtag[1]"_"smtag[2],\
# "-hold_jid","S.16-A.01-A.01_REFORMAT_ANNOVAR_"smtag[1]"_"smtag[2]"_"$2"_"$1,\
# "-o","'$CORE_PATH'/"$1"/LOGS/"$3"_"$1".QC_REPORT_PREP.log",\
# "'$SCRIPT_DIR'""/X.01-QC_REPORT_PREP.sh",\
# "'$SAMTOOLS_DIR'","'$CORE_PATH'","'$DATAMASH_DIR'",$1,$2,$3,$4,$5,$6,$7"\n""sleep 1s"}'
#
# ### END PROJECT TASKS ###
#
# awk 'BEGIN {FS="\t"; OFS="\t"} {split($8,smtag,"[@]"); print $1,smtag[1]"_"smtag[2]}' \
# ~/CGC_PIPELINE_TEMP/$MANIFEST_PREFIX.$PED_PREFIX.join.txt \
# | sort -k 1 -k 2 \
# | uniq \
# | $DATAMASH_DIR/datamash -s -g 1 collapse 2 \
# | awk 'BEGIN {FS="\t"}
# gsub (/,/,",X.01-QC_REPORT_PREP_"$1"_",$2) \
# {print "qsub","-N","X.01-X.01-END_PROJECT_TASKS_"$1,\
# "-hold_jid","X.01-QC_REPORT_PREP_"$1"_"$2,\
# "-o","'$CORE_PATH'/"$1"/LOGS/"$1".END_PROJECT_TASKS.log",\
# "'$SCRIPT_DIR'""/X.01-X.01-END_PROJECT_TASKS.sh",\
# "'$CORE_PATH'","'$DATAMASH_DIR'",$1"\n""sleep 1s"}'
#
