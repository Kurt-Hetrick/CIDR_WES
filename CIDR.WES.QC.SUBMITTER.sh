#!/usr/bin/env bash

###################
# INPUT VARIABLES #
###################

	SAMPLE_SHEET=$1
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	PRIORITY=$2 # optional. if no 2nd argument present then the default is -15

		# if there is no 2nd argument present then use the number for priority
			if [[ ! ${PRIORITY} ]]
				then
				PRIORITY="-15"
			fi

########################################################################
# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED #
########################################################################

	SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

	SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/scripts"

##################
# CORE VARIABLES #
##################

	# Directory where sequencing projects are located

		CORE_PATH="/mnt/research/active"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# used for tracking in the read group header of the cram file

		PIPELINE_VERSION=`git --git-dir=${SCRIPT_DIR}/../.git --work-tree=${SCRIPT_DIR}/.. log --pretty=format:'%h' -n 1`

	# load gcc for programs like verifyBamID
	## this will get pushed out to all of the compute nodes since I specify env var to pushed out with qsub

			module load gcc/7.2.0

	# explicitly setting this b/c not everybody has had the $HOME directory transferred and I'm not going to through
	# and figure out who does and does not have this set correctly

			umask 0007

	# SUBMIT TIMESTAMP

		SUBMIT_STAMP=`date '+%s'`

	# SUBMITTER_ID

		SUBMITTER_ID=`whoami`

	# grab submitter's name

		PERSON_NAME=`getent passwd | awk 'BEGIN {FS=":"} $1=="'${SUBMITTER_ID}'" {print $5}'`

	# grab email addy

		SEND_TO=`cat ${SCRIPT_DIR}/../email_lists.txt`

	# bind the host file system /mnt to the singularity container. in case I use it in the submitter.

		export SINGULARITY_BINDPATH="/mnt:/mnt"

	# Generate a list of active queue and remove the ones that I don't want to use

		QUEUE_LIST=`qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q|bigdata.q|uhoh.q" \
			| datamash collapse 1 \
			| awk '{print $1}'`

		# just show how to exclude a node
			# QUEUE_LIST=`qstat -f -s r \
			# 	| egrep -v "^[0-9]|^-|^queue" \
			# 	| cut -d @ -f 1 \
			# 	| sort \
			# 	| uniq \
			# 	| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q" \
			# 	| datamash collapse 1 \
			# 	| awk '{print $1,"-l \x27hostname=!DellR730-03\x27"}'`

	# QSUB ARGUMENTS LIST
		# set shell on compute node
		# start in current working directory
		# transfer submit node env to compute node
		# set SINGULARITY BINDPATH
		# set queues to submit to
		# set priority
		# combine stdout and stderr logging to same output file

			QSUB_ARGS="-S /bin/bash" \
				QSUB_ARGS=${QSUB_ARGS}" -cwd" \
				QSUB_ARGS=${QSUB_ARGS}" -V" \
				QSUB_ARGS=${QSUB_ARGS}" -v SINGULARITY_BINDPATH=/mnt:/mnt" \
				QSUB_ARGS=${QSUB_ARGS}" -q ${QUEUE_LIST}" \
				QSUB_ARGS=${QSUB_ARGS}" -p ${PRIORITY}" \
				QSUB_ARGS=${QSUB_ARGS}" -j y"

#####################
# PIPELINE PROGRAMS #
#####################

	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	LAB_QC_DIR="/mnt/linuxtools/CUSTOM_CIDR/EnhancedSequencingQCReport/0.1.0"
		# Copied from /mnt/research/tools/LINUX/CIDRSEQSUITE/pipeline_dependencies/QC_REPORT/EnhancedSequencingQCReport.jar
		# md5 f979bb4dc8d97113735ef17acd3a766e  EnhancedSequencingQCReport.jar
	ALIGNMENT_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/ddl_ce_control_align-0.0.4.simg"
	# contains the following software and is on Ubuntu 16.04.5 LTS
		# gatk 4.0.11.0 (base image). also contains the following.
			# Python 3.6.2 :: Continuum Analytics, Inc.
				# samtools 0.1.19
				# bcftools 0.1.19
				# bedtools v2.25.0
				# bgzip 1.2.1
				# tabix 1.2.1
				# samtools, bcftools, bgzip and tabix will be replaced with newer versions.
				# R 3.2.5
					# dependencies = c("gplots","digest", "gtable", "MASS", "plyr", "reshape2", "scales", "tibble", "lazyeval")    # for ggplot2
					# getopt_1.20.0.tar.gz
					# optparse_1.3.2.tar.gz
					# data.table_1.10.4-2.tar.gz
					# gsalib_2.1.tar.gz
					# ggplot2_2.2.1.tar.gz
				# openjdk version "1.8.0_181"
				# /gatk/gatk.jar -> /gatk/gatk-package-4.0.11.0-local.jar
		# added
			# picard.jar 2.17.0 (as /gatk/picard.jar)
			# samblaster-v.0.1.24
			# sambamba-0.6.8
			# bwa-0.7.15
			# datamash-1.6
			# verifyBamID v1.1.3
			# samtools 1.10
			# bgzip 1.10
			# tabix 1.10
			# bcftools 1.10.2

	GATK_3_7_0_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/gatk3-3.7-0.simg"
	# singularity pull docker://broadinstitute/gatk3:3.7-0
	# used for generating the depth of coverage reports.
		# comes with R 3.1.1 with appropriate packages needed to create gatk pdf output
		# also comes with some version of java 1.8
		# jar file is /usr/GenomeAnalysisTK.jar


	PICARD_DIR="/mnt/linuxtools/PICARD/picard-2.17.0"
	GATK_DIR="/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7"
	VERIFY_DIR="/mnt/linuxtools/verifyBamID/verifyBamID_1.1.3/verifyBamID/bin"
	GATK_DIR_4011="/mnt/linuxtools/GATK/gatk-4.0.1.1"

	DATAMASH_DIR="/mnt/linuxtools/DATAMASH/datamash-1.0.6"
	# This is samtools version 1.7
	# I have no idea why other users other than me cannot index a cram file with a version of samtools that I built from the source
	# Apparently the version that I built with Anaconda works for other users, but it performs REF_CACHE first...
	SAMTOOLS_DIR="/mnt/linuxtools/ANACONDA/anaconda2-5.0.0.1/bin"
	BEDTOOLS_DIR="/mnt/linuxtools/BEDTOOLS/bedtools-2.22.0/bin"
	SAMTOOLS_0118_DIR="/mnt/linuxtools/SAMTOOLS/samtools-0.1.18"
	CIDRSEQSUITE_6_JAVA_DIR="/mnt/linuxtools/JAVA/jre1.7.0_45/bin"
	CIDRSEQSUITE_6_1_1_DIR="/mnt/linuxtools/CIDRSEQSUITE/6.1.1"
	CIDRSEQSUITE_7_5_0_DIR="/mnt/linuxtools/CIDRSEQSUITE/7.5.0"
	R_DIRECTORY="/mnt/linuxtools/R/R-3.1.1/bin"

##################
# PIPELINE FILES #
##################

	CODING_BED="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/UCSC_hg19_CodingOnly_083013_MERGED_noContigs_plus_rCRS_MT.bed"
		# MT was added from ucsc table browser for grch38, GENCODE v29
		# md5 386340ecb59652ad2d182a89dce0c4df
	GENE_LIST="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/RefSeqGene.GRCh37.rCRS.MT.bed"
		# md5 dec069c279625cfb110c2e4c5480e036
	CYTOBAND_BED="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/GRCh37.Cytobands.bed"
	VERIFY_VCF="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf"
	DBSNP_129="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/dbsnp_138.b37.excluding_sites_after_129.vcf"
	VERACODE_CSV="/mnt/research/tools/LINUX/CIDRSEQSUITE/resources/Veracode_hg18_hg19.csv"
	MERGED_MENDEL_BED_FILE="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914_TwistCUEXmito.bed"
		# FOR REANALYSIS OF CUTTING'S PHASE AND PHASE 2 PROJECTS.
		# md5: 5d99c5df1d8f970a8219ef0ab455d756
	MERGED_CUTTING_BED_FILE="/mnt/research/active/H_Cutting_CFTR_WGHum-SeqCustom_1_Reanalysis/BED_Files/H_Cutting_phase_1plus2_super_file.bed"

#################################
##### MAKE A DIRECTORY TREE #####
#################################

#########################################################
# CREATE_PROJECT_ARRAY for each PROJECT in sample sheet #
#########################################################
	# add a end of file is not present
	# remove carriage returns if not present
	# remove blank lines if present
	# remove lines that only have whitespace

		CREATE_PROJECT_ARRAY ()
		{
			PROJECT_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=","} \
					$1=="'${PROJECT_NAME}'" \
					{print $1}' \
				| sort \
				| uniq`)

			# 1: Project=the Seq Proj folder name

				SEQ_PROJECT=${PROJECT_ARRAY[0]}
		}

##################################
# project directory tree creator #
##################################

	MAKE_PROJ_DIR_TREE ()
	{
		mkdir -p \
		${CORE_PATH}/${SEQ_PROJECT}/{TEMP,FASTQ,LOGS,CRAM,GVCF,COMMAND_LINES,HC_CRAM} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{ALIGNMENT_SUMMARY,ANEUPLOIDY_CHECK,ANNOVAR,COUNT_COVARIATES,ERROR_SUMMARY,LAB_PREP_REPORTS,PICARD_DUPLICATES,QC_REPORTS,QC_REPORT_PREP,QUALITY_YIELD,RG_HEADER,TI_TV,TI_TV_MS,VERIFYBAMID,VERIFYBAMID_CHR} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BAIT_BIAS/{METRICS,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{CONCORDANCE,CONCORDANCE_MS} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/COUNT_COVARIATES \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/DEPTH_OF_COVERAGE/{TARGET,UCSC,BED_SUPERSET} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/GC_BIAS/{METRICS,PDF,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/INSERT_SIZE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/MEAN_QUALITY_BY_CYCLE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/PRE_ADAPTER/{METRICS,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/VCF/QC
	}

############################################################################################################
# run ben's enhanced sequencing lab prep metrics report generator which queries phoenix among other things #
############################################################################################################

	RUN_LAB_PREP_METRICS ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
		-N A00-LAB_PREP_METRICS_${PROJECT_NAME} \
			-o ${CORE_PATH}/${PROJECT_NAME}/LOGS/${PROJECT_NAME}-LAB_PREP_METRICS.log \
		${SCRIPT_DIR}/A00-LAB_PREP_METRICS.sh \
			${JAVA_1_8} \
			${LAB_QC_DIR} \
			${CORE_PATH} \
			${PROJECT_NAME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

################################################################
# combine steps into on function which is probably superfluous #
################################################################

	SETUP_PROJECT ()
	{
		CREATE_PROJECT_ARRAY
		MAKE_PROJ_DIR_TREE
		RUN_LAB_PREP_METRICS
		echo Project started at `date` >> ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/PROJECT_START_END_TIMESTAMP.txt
	}

################################################################
# CREATE_SAMPLE_ARRAY to populate aggregated sample variables. #
################################################################

	CREATE_SAMPLE_ARRAY ()
	{
		SAMPLE_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} $8=="'${SM_TAG}'" {split($19,INDEL,";"); print $1,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
			| sort \
			| uniq`)

		# 1: Project=the Seq Proj folder name

			PROJECT=${SAMPLE_ARRAY[0]}

			###########################################################################
			# 2: SKIP: FCID=flowcell that sample read group was performed on ##########
			###########################################################################
			# 3: SKIP: Lane=lane of flowcell that sample read group was performed on] #
			###########################################################################
			# 4: SKIP: Index=sample barcode ###########################################
			###########################################################################

		# 5: Platform=type of sequencing chemistry matching SAM specification

			PLATFORM=${SAMPLE_ARRAY[1]}

		# 6: Library_Name=library group of the sample read group
		#VUsed during Marking Duplicates to determine if molecules are to be considered as part of the same library or not

			LIBRARY=${SAMPLE_ARRAY[2]}

		# 7: Date=should be the run set up date to match the seq run folder name
		# but it has been arbitrarily populated

			RUN_DATE=${SAMPLE_ARRAY[3]}

		# 8: SM_Tag=sample ID

			SM_TAG=${SAMPLE_ARRAY[4]}

				# If there is an @ in the qsub or holdId name it breaks

					SGE_SM_TAG=$(echo ${SM_TAG} | sed 's/@/_/g')

		# 9: Center=the center/funding mechanism

			CENTER=${SAMPLE_ARRAY[5]}

		# 10: Description=Generally we use to denote the sequencer setting (e.g. rapid run)
		# �HiSeq-X�, �HiSeq-4000�, �HiSeq-2500�, �HiSeq-2000�, �NextSeq-500�, or �MiSeq�.

			SEQUENCER_MODEL=${SAMPLE_ARRAY[6]}

			########################
			# 11: SKIP: Seq_Exp_ID #
			########################

		# 12: Genome_Ref=the reference genome used in the analysis pipeline

			REF_GENOME=${SAMPLE_ARRAY[7]}

				# REFERENCE DICTIONARY IS A SUMMARY OF EACH CONTIG. PAIRED WITH REF GENOME

					REF_DICT=$(echo ${REF_GENOME} | sed 's/fasta$/dict/g; s/fa$/dict/g')

			#####################################
			# 13: SKIP: Operator ################
			#####################################
			# 14: SKIP: Extra_VCF_Filter_Params #
			#####################################

		# 15: TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files

			TITV_BED=${SAMPLE_ARRAY[8]}

		# 16: Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
		# Used for limited where to run base quality score recalibration on where to create gvcf files.

			BAIT_BED=${SAMPLE_ARRAY[9]}

			# since the mendel changes capture products need a way to define a 4th bed file which is the union of the different captures used.
			# Also have a section for garry cutting's 2 captures

				if [[ ${PROJECT} = "M_Valle"* ]];
					then
						HC_BAIT_BED=${MERGED_MENDEL_BED_FILE}
				elif [[ ${PROJECT} = "H_Cutting"* ]];
					then
						HC_BAIT_BED=${MERGED_CUTTING_BED_FILE}
				else
					HC_BAIT_BED=${BAIT_BED}
				fi

		# 17: Targets_BED_File=bed file acquired from manufacturer of their targets.

			TARGET_BED=${SAMPLE_ARRAY[10]}

		# 18: KNOWN_SITES_VCF=used to annotate ID field in VCF file.
		# masking in base call quality score recalibration.

			DBSNP=${SAMPLE_ARRAY[11]}

		# 19: KNOWN_INDEL_FILES=used for BQSR masking

			KNOWN_INDEL_1=${SAMPLE_ARRAY[12]}
			KNOWN_INDEL_2=${SAMPLE_ARRAY[13]}
	}

######################################################
# CREATE SAMPLE FOLDERS IN TEMP AND LOGS DIRECTORIES #
######################################################

	MAKE_SAMPLE_DIRECTORIES ()
	{
		mkdir -p \
		${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG} \
		${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}
	}

###################################################
### fix common formatting problems in bed files ###
### create picard style interval files ############
### DO PER SAMPLE #################################
###################################################

	FIX_BED_FILES ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
		-N A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FIX_BED_FILES.log \
		${SCRIPT_DIR}/A01-FIX_BED_FILES.sh \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${BAIT_BED} \
			${TARGET_BED} \
			${TITV_BED} \
			${REF_DICT}
	}

	######################################
	# CREATE VCF FOR VERIFYBAMID METRICS #
	######################################
	# USE THE TARGET BED FILE ############
	######################################

		SELECT_VERIFYBAMID_VCF ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N A01-A01-SELECT_VERIFYBAMID_VCF_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_VERIFYBAMID_VCF.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/A01-A01-SELECT_VERIFYBAMID_VCF.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${VERIFY_VCF} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

#############################################################################
# RUN STEPS TO DO PROJECT SET UP, FIX BED FILES, MAKE VERIFYBAMID VCF FILES #
#############################################################################

	for PROJECT_NAME in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $1}' \
			| sort \
			| uniq);
	do
		SETUP_PROJECT
	done

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		MAKE_SAMPLE_DIRECTORIES
		FIX_BED_FILES
		echo sleep 0.1s
		SELECT_VERIFYBAMID_VCF
		echo sleep 0.1s
	done

#######################################################################################
##### BAM FILE GENERATION AND RUN VERIFYBAMID ########################################
#######################################################################################
# NOTE: THE CRAM FILE IS THE END PRODUCT BUT THE BAM FILE IS USED FOR OTHER PROCESSES #
# SOME PROGRAMS CAN'T TAKE IN CRAM AS AN INPUT ########################################
# THE OUTPUT FROM VERIFYBAMID IS USED FOR HAPLOTYPE CALLER ############################
#######################################################################################

#############################################################################
# CREATE_PLATFORM_UNIT_ARRAY so that bwa mem can add metadata to the header #
#############################################################################

	CREATE_PLATFORM_UNIT_ARRAY ()
	{
		PLATFORM_UNIT_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} \
				$8$2$3$4=="'${PLATFORM_UNIT}'" \
				{split($19,INDEL,";"); \
				print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
			| sort \
			| uniq`)

		# 1: Project=the Seq Proj folder name

			PROJECT=${PLATFORM_UNIT_ARRAY[0]}

		# 2: FCID=flowcell that sample read group was performed on

			FCID=${PLATFORM_UNIT_ARRAY[1]}

		# 3: Lane=lane of flowcell that sample read group was performed on]

			LANE=${PLATFORM_UNIT_ARRAY[2]}

		# 4: Index=sample barcode

			INDEX=${PLATFORM_UNIT_ARRAY[3]}

		# 5: Platform=type of sequencing chemistry matching SAM specification

			PLATFORM=${PLATFORM_UNIT_ARRAY[4]}

		# 6: Library_Name=library group of the sample read group
		# Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not

			LIBRARY=${PLATFORM_UNIT_ARRAY[5]}

		# 7: Date=should be the run set up date to match the seq run folder name
		# but it has been arbitrarily populated

			RUN_DATE=${PLATFORM_UNIT_ARRAY[6]}

		# 8: SM_Tag=sample ID

			SM_TAG=${PLATFORM_UNIT_ARRAY[7]}

				# If there is an @ in the qsub or holdId name it breaks

					SGE_SM_TAG=$(echo ${SM_TAG} | sed 's/@/_/g')

		# 9: Center=the center/funding mechanism

			CENTER=${PLATFORM_UNIT_ARRAY[8]}

		# 10: Description=Generally we use to denote the sequencer setting (e.g. rapid run)
		# �HiSeq-X�, �HiSeq-4000�, �HiSeq-2500�, �HiSeq-2000�, �NextSeq-500�, or �MiSeq�.

			SEQUENCER_MODEL=${PLATFORM_UNIT_ARRAY[9]}

				#########################
				# 11: SKIP:  Seq_Exp_ID #
				#########################

		# 12: Genome_Ref=the reference genome used in the analysis pipeline

			REF_GENOME=${PLATFORM_UNIT_ARRAY[10]}

			#####################################
			# 13: SKIP:  Operator ###############
			#####################################
			# 14: SKIP: Extra_VCF_Filter_Params #
			#####################################

		# 15: TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files

			TITV_BED=${PLATFORM_UNIT_ARRAY[11]}

		# 16: Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
		# Used for limited where to run base quality score recalibration on where to create gvcf files.

			BAIT_BED=${PLATFORM_UNIT_ARRAY[12]}

		# 17: Targets_BED_File=bed file acquired from manufacturer of their targets.

			TARGET_BED=${PLATFORM_UNIT_ARRAY[13]}

		# 18: KNOWN_SITES_VCF=used to annotate ID field in VCF file
		# masking in base call quality score recalibration.

			DBSNP=${PLATFORM_UNIT_ARRAY[14]}

		# 19: KNOWN_INDEL_FILES=used for BQSR masking

			KNOWN_INDEL_1=${PLATFORM_UNIT_ARRAY[15]}
			KNOWN_INDEL_2=${PLATFORM_UNIT_ARRAY[16]}
	}

####################################################################
# Use bwa mem to do the alignments #################################
# pipe to samblaster to add mate tags ##############################
# pipe to picard's AddOrReplaceReadGroups to handle the bam header #
####################################################################

	RUN_BWA ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
		-N A02-BWA_${SGE_SM_TAG}_${FCID}_${LANE}_${INDEX} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}_${FCID}_${LANE}_${INDEX}-BWA.log \
		${SCRIPT_DIR}/A02-BWA.sh \
			${ALIGNMENT_CONTAINER} \
			${CORE_PATH} \
			${PROJECT} \
			${FCID} \
			${LANE} \
			${INDEX} \
			${PLATFORM} \
			${LIBRARY} \
			${RUN_DATE} \
			${SM_TAG} \
			${CENTER} \
			${SEQUENCER_MODEL} \
			${REF_GENOME} \
			${PIPELINE_VERSION} \
			${BAIT_BED} \
			${TARGET_BED} \
			${TITV_BED} \
			${NOVASEQ_REPO} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

#############################
# RUN STEPS TO RUN BWA, ETC #
#############################

	for PLATFORM_UNIT in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $8$2$3$4}' \
			| sort \
			| uniq );
	do
		CREATE_PLATFORM_UNIT_ARRAY
		RUN_BWA
		echo sleep 0.1s
	done

#########################################################################################
### MARK_DUPLICATES #####################################################################
# Merge files and mark duplicates using picard duplictes with queryname sorting #########
# do coordinate sorting with sambamba ###################################################
#########################################################################################
#########################################################################################
# I am setting the heap space and garbage collector threads now #########################
# doing this does drastically decrease the load average ( the gc thread specification ) #
#########################################################################################
#########################################################################################
# create a hold job id qsub command line based on the number of #########################
# submit merging the bam files created by bwa mem above #################################
# only launch when every lane for a sample is done being processed by bwa mem ###########
# I want to clean this up eventually, but not in the mood for it right now. #############
#########################################################################################

	# What is being pulled out of the merged sample sheet
		# 1. PROJECT
		# 2. SM_TAG
		# 3. FCID_LANE_INDEX
		# 4. FCID_LANE_INDEX.bam
		# 5. SM_TAG
		# 6. DESCRIPTION (INSTRUMENT MODEL)

		awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","; OFS="\t"} \
				NR>1 \
				{print $1,$8,$2"_"$3"_"$4,$2"_"$3"_"$4".bam",$8,$10}' \
			| awk 'BEGIN {OFS="\t"} \
				{sub(/@/,"_",$5)} \
				{print $1,$2,$3,$4,$5,$6}' \
			| sort \
				-k 1,1 \
				-k 2,2 \
				-k 3,3 \
				-k 6,6 \
			| uniq \
			| singularity exec $ALIGNMENT_CONTAINER datamash \
				-s \
				-g 1,2 \
				collapse 3 \
				collapse 4 \
				unique 5 \
				unique 6 \
			| awk 'BEGIN {FS="\t"} \
				gsub(/,/,",A02-BWA_"$5"_",$3) \
				gsub(/,/,",INPUT=" "'${CORE_PATH}'" "/" $1"/TEMP/"$2"/",$4) \
				{print "qsub",\
				"-S /bin/bash",\
				"-cwd",\
				"-V",\
				"-v SINGULARITY_BINDPATH=/mnt:/mnt",\
				"-q","'$QUEUE_LIST'",\
				"-p","'${PRIORITY}'",\
				"-N","B01-MARK_DUPLICATES_"$5"_"$1,\
				"-o","'${CORE_PATH}'/"$1"/LOGS/"$2"/"$2"-MARK_DUPLICATES.log",\
				"-j y",\
				"-hold_jid","A02-BWA_"$5"_"$3, \
				"'${SCRIPT_DIR}'""/B01-MARK_DUPLICATES.sh",\
				"'${ALIGNMENT_CONTAINER}'",\
				"'${CORE_PATH}'",\
				$1,\
				$2,\
				$6,\
				"'${SAMPLE_SHEET}'",\
				"'${SUBMIT_STAMP}'",\
				"INPUT=" "'${CORE_PATH}'" "/" $1"/TEMP/"$2"/"$4"\n""sleep 0.1s"}'

###################################################
### PROCEEDING WITH AGGREGATED SAMPLE FILES NOW ###
###################################################

	################################
	# run bqsr using bait bed file #
	################################

		RUN_BQSR ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N C01-PERFORM_BQSR_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-PERFORM_BQSR.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},B01-MARK_DUPLICATES_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/C01-PERFORM_BQSR.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${KNOWN_INDEL_1} \
				${KNOWN_INDEL_2} \
				${DBSNP} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	##############################
	# use a 4 bin q score scheme #
	# remove indel Q scores ######
	# retain original Q score  ###
	##############################

		APPLY_BQSR ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-APPLY_BQSR.log \
			-hold_jid C01-PERFORM_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/D01-APPLY_BQSR.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###################
	# RUN VERIFYBAMID #
	###################

		RUN_VERIFYBAMID ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VERIFYBAMID.log \
			-hold_jid A01-A01-SELECT_VERIFYBAMID_VCF_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E01-VERIFYBAMID.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

###############################
# RUN STEPS BQSR, VERIFYBAMID #
###############################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		RUN_BQSR
		echo sleep 0.1s
		APPLY_BQSR
		echo sleep 0.1s
		RUN_VERIFYBAMID
		echo sleep 0.1s
	done

########################################################################################################
##### HAPLOTYPE CALLER AND GENOTYPE GVCF SCATTER #######################################################
# INPUT IS THE BAM FILE ################################################################################
# the freemix value from verifybamID output is pulled as a variable to the haplotype caller script #####
########################################################################################################

	###############################################################################################
	# run haplotype caller to create a gvcf for all intervals per chromosome in the bait bed file #
	###############################################################################################

		CALL_HAPLOTYPE_CALLER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F01-HAPLOTYPE_CALLER_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_chr${CHROMOSOME}.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT},E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/F01-HAPLOTYPE_CALLER_SCATTER.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${HC_BAIT_BED} \
				${CHROMOSOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	################################################################################################
	# run genotype gvcfs for each per chromosome gvcf to ###########################################
	# but only make calls on the capture bait bed file and not the merged bed file if there is one #
	################################################################################################

		CALL_GENOTYPE_GVCF ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G01-GENOTYPE_GVCF_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-GENOTYPE_GVCF_chr${CHROMOSOME}.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},F01-HAPLOTYPE_CALLER_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
			${SCRIPT_DIR}/G01-GENOTYPE_GVCF_SCATTER.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${DBSNP} \
				${CHROMOSOME} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

#################################################################################################
# RUN STEPS FOR HAPLOTYPE CALLER AND GENOTYPE GVCF SCATTER ######################################
# Take the samples bait bed file and ############################################################
# create a list of unique chromosome to use as a scatter for haplotype caller and genotype gvcf #
#################################################################################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY

		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${HC_BAIT_BED} \
			| sed -r 's/[[:space:]]+/\t/g' \
			| sed 's/chr//g' \
			| egrep "^[0-9]|^X|^Y" \
			| cut -f 1 \
			| sort -V \
			| uniq \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				collapse 1 \
			| sed 's/,/ /g');
		do
			CALL_HAPLOTYPE_CALLER
			echo sleep 0.1s
			CALL_GENOTYPE_GVCF
			echo sleep 0.1s
		done
	done

################################################################################
##### HAPLOTYPE CALLER GATHER ##################################################
################################################################################
# GATHER UP THE PER SAMPLE PER CHROMOSOME GVCF FILES INTO A SINGLE SAMPLE GVCF #
################################################################################

	#############################################################################################
	# create variables to create the hold id for gathering the chromosome level gvcfs/bams/vcfs #
	#############################################################################################

		BUILD_HOLD_ID_PATH_GVCF_AND_HC_BAM_AND_VCF_GATHER ()
		{
			HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="-hold_jid "

			HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="-hold_jid "

			for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${HC_BAIT_BED} \
					| sed -r 's/[[:space:]]+/\t/g' \
					| sed 's/chr//g' \
					| egrep "^[0-9]|^X|^Y" \
					| cut -f 1 \
					| sort -V \
					| uniq \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash \
						collapse 1 \
					| sed 's/,/ /g');
			do
				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER}F01-HAPLOTYPE_CALLER_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"

				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER=`echo ${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} | sed 's/@/_/g'`

				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER}G01-GENOTYPE_GVCF_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"

				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER=`echo ${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} | sed 's/@/_/g'`
			done
		}

	###################################
	# gather the per chromosome gvcfs #
	###################################

		CALL_HAPLOTYPE_CALLER_GVCF_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G02-HAPLOTYPE_CALLER_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_GVCF_GATHER.log \
			${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} \
			${SCRIPT_DIR}/G02-HAPLOTYPE_CALLER_GVCF_GATHER.sh \
				${GATK_3_7_0_CONTAINER} \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${HC_BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	########################################################
	# gather the per chromosome haplotype caller bam files #
	########################################################

		CALL_HAPLOTYPE_CALLER_BAM_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G03-HAPLOTYPE_CALLER_BAM_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_BAM_GATHER.log \
			${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} \
			${SCRIPT_DIR}/G03-HAPLOTYPE_CALLER_BAM_GATHER.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${HC_BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	##################################
	# gather the per chromosome vcfs #
	##################################

		CALL_GENOTYPE_GVCF_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-GENOTYPE_GVCF_GATHER.log \
			${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} \
			${SCRIPT_DIR}/H01-GENOTYPE_GVCF_GATHER.sh \
				${GATK_3_7_0_CONTAINER} \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

###############################################
# RUN STEPS TO DO GVCF, HC BAM AND VCF GATHER #
###############################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		BUILD_HOLD_ID_PATH_GVCF_AND_HC_BAM_AND_VCF_GATHER
		CALL_HAPLOTYPE_CALLER_GVCF_GATHER
		echo sleep 0.1s
		CALL_HAPLOTYPE_CALLER_BAM_GATHER
		echo sleep 0.1s
		CALL_GENOTYPE_GVCF_GATHER
		echo sleep 0.1s
	done

###########################################
##### BAM TO CRAM AND RELATED METRICS #####
###########################################

	#####################################################
	# create a lossless cram, although the bam is lossy #
	#####################################################

		BAM_TO_CRAM ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-BAM_TO_CRAM.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E02-BAM_TO_CRAM.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###############################################
	# CREATE DEPTH OF COVERAGE FOR ALL UCSC EXONS #
	###############################################

		DOC_CODING ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E03-DOC_CODING_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_CODING.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E03-DOC_CODING.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${CODING_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#############################################
	# CREATE DEPTH OF COVERAGE FOR BED SUPERSET #
	#############################################

		DOC_BAIT ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E04-DOC_BAIT_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_BED_SUPERSET.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E04-DOC_BED_SUPERSET.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	############################################
	# CREATE DEPTH OF COVERAGE FOR TARGET BED  #
	############################################

		DOC_TARGET ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E05-DOC_TARGET_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_TARGET.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E05-DOC_TARGET.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#########################################################
	# DO AN ANEUPLOIDY CHECK ON TARGET BED FILE DOC OUTPUT  #
	#########################################################

		ANEUPLOIDY_CHECK ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E05-A01-CHROM_DEPTH_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-ANEUPLOIDY_CHECK.log \
			-hold_jid E05-DOC_TARGET_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E05-A01-CHROM_DEPTH.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${CYTOBAND_BED}
		}

	#############################
	# COLLECT MULTIPLE METRICS  #
	#############################

		COLLECT_MULTIPLE_METRICS ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F02-COLLECT_MULTIPLE_METRICS_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-COLLECT_MULTIPLE_METRICS.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/F02-COLLECT_MULTIPLE_METRICS.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${DBSNP} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#######################
	# COLLECT HS METRICS  #
	#######################

		COLLECT_HS_METRICS ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F03-COLLECT_HS_METRICS_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-COLLECT_HS_METRICS.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/F03-COLLECT_HS_METRICS.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${BAIT_BED} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	################################################################
	# PERFORM VERIFYBAM ID PER CHROMOSOME ##########################
	# DOING BOTH THE SELECT VCF AND VERIFYBAMID RUN WITHIN ONE JOB #
	################################################################

		CALL_VERIFYBAMID_PER_AUTO ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E06-VERIFYBAMID_PER_AUTO_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VERIFYBAMID_PER_CHR.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
				${SCRIPT_DIR}/E06-VERIFYBAMID_PER_AUTO.sh \
				${ALIGNMENT_CONTAINER} \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${VERIFY_VCF} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	######################################
	# GATHER PER CHR VERIFYBAMID REPORTS #
	######################################

		CALL_VERIFYBAMID_AUTO_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E06-A01-CAT_VERIFYBAMID_AUTO_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-CAT_VERIFYBAMID_AUTO.log \
			-hold_jid E06-VERIFYBAMID_PER_AUTO_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/E06-A01-CAT_VERIFYBAMID_AUTO.sh \
				${CORE_PATH} \
				${ALIGNMENT_CONTAINER} \
				${PROJECT} \
				${SM_TAG} \
				${BAIT_BED}
		}

############################################
# RUN STEPS TO DO BAM/CRAM RELATED METRICS #
############################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		BAM_TO_CRAM
		echo sleep 0.1s
		DOC_CODING
		echo sleep 0.1s
		DOC_BAIT
		echo sleep 0.1s
		DOC_TARGET
		echo sleep 0.1s
		ANEUPLOIDY_CHECK
		echo sleep 0.1s
		COLLECT_MULTIPLE_METRICS
		echo sleep 0.1s
		COLLECT_HS_METRICS
		echo sleep 0.1s
		CALL_VERIFYBAMID_PER_AUTO
		echo sleep 0.1s
		CALL_VERIFYBAMID_AUTO_GATHER
		echo sleep 0.1s
	done

###########################################################
### HC_BAM TO CRAM; VCF BREAKOUTS, FILTERING, METRICS #####
###########################################################

	########################################################
	# create a lossless HC cram, although the bam is lossy #
	########################################################

		HC_BAM_TO_CRAM ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p ${PRIORITY} \
			-N H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}"-HC_BAM_TO_CRAM.log" \
				-j y \
			-hold_jid I02-HAPLOTYPE_CALLER_BAM_GATHER_${SGE_SM_TAG}_${PROJECT} \
			${SCRIPT_DIR}/H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM.sh \
				$SAMTOOLS_DIR \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

##########################################################################################
# index the cram file and copy it so that there are both *crai and cram.crai *extensions #
##########################################################################################

	HC_INDEX_CRAM ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N H.01-A.02-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}"-HC_INDEX_CRAM.log" \
			-j y \
		-hold_jid H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/H.01-A.02-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM.sh \
			$SAMTOOLS_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME}
	}

	SELECT_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01_SELECT_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_SNV_QC.log \
			-j y \
		-hold_jid H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
		${SCRIPT_DIR}/J.01_SELECT_SNV.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	SELECT_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.02_SELECT_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_INDEL_QC.log \
			-j y \
		-hold_jid H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
		${SCRIPT_DIR}/J.02_SELECT_INDEL.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	SELECT_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.03_SELECT_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_MIXED_QC.log \
			-j y \
		-hold_jid H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
		${SCRIPT_DIR}/J.03_SELECT_MIXED.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	FILTER_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_SNV_QC.log \
			-j y \
		-hold_jid J.01_SELECT_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01_FILTER_SNV.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	FILTER_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_INDEL_QC.log \
			-j y \
		-hold_jid J.02_SELECT_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.02-A.01_FILTER_INDEL.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	FILTER_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_MIXED_QC.log \
			-j y \
		-hold_jid J.03_SELECT_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.03-A.01_FILTER_MIXED.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	BAIT_PASS_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.01_BAIT_PASS_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-BAIT_PASS_SNV_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.01_SNV_BAIT_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	TARGET_PASS_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.02_TARGET_PASS_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-TARGET_PASS_SNV_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.02_SNV_TARGET_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TARGET_BED} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	TARGET_PASS_SNV_CONCORDANCE ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.02-A.01_SNV_TARGET_PASS_CONCORDANCE"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-TARGET_PASS_SNV_QC_CONCORDANCE.log \
			-j y \
		-hold_jid J.01-A.01-A.02_TARGET_PASS_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT},A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.02-A.01_SNV_TARGET_PASS_CONCORDANCE.sh \
			${JAVA_1_8} \
			$CIDRSEQSUITE_7_5_0_DIR \
			$VERACODE_CSV \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${TARGET_BED} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	BAIT_PASS_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.02-A.01-A.01_BAIT_PASS_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-BAIT_PASS_INDEL_QC.log \
			-j y \
		-hold_jid J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.02-A.01-A.01_INDEL_BAIT_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	TARGET_PASS_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.02-A.01-A.02_TARGET_PASS_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-TARGET_PASS_INDEL_QC.log \
			-j y \
		-hold_jid J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.02-A.01-A.02_INDEL_TARGET_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TARGET_BED} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	BAIT_PASS_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.03-A.01-A.01_BAIT_PASS_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-BAIT_PASS_MIXED_QC.log \
			-j y \
		-hold_jid J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.03-A.01-A.01_MIXED_BAIT_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	TARGET_PASS_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.03-A.01-A.02_TARGET_PASS_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-TARGET_PASS_MIXED_QC.log \
			-j y \
		-hold_jid J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.03-A.01-A.02_MIXED_TARGET_PASS.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TARGET_BED} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	SELECT_TITV_ALL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.03_SELECT_TITV_ALL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_TITV_ALL_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.03_SELECT_TITV_ALL.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TITV_BED} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	SELECT_TITV_KNOWN ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.04_SELECT_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_TITV_KNOWN_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.04_SELECT_TITV_KNOWN.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TITV_BED} \
			${DBSNP}_129 \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	SELECT_TITV_NOVEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
		-N J.01-A.01-A.05_SELECT_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_TITV_NOVEL_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT} \
		${SCRIPT_DIR}/J.01-A.01-A.05_SELECT_TITV_NOVEL.sh \
			${JAVA_1_8} \
			$GATK_DIR \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${REF_GENOME} \
			${TITV_BED} \
			${DBSNP}_129 \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

	# run titv

		RUN_TITV_ALL ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p ${PRIORITY} \
			-N J.01-A.01-A.03-A.01_RUN_TITV_ALL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-RUN_TITV_ALL_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.03_SELECT_TITV_ALL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			${SCRIPT_DIR}/J.01-A.01-A.03-A.01_RUN_TITV_ALL.sh \
				$SAMTOOLS_0118_DIR \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

		RUN_TITV_KNOWN ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p ${PRIORITY} \
			-N J.01-A.01-A.04-A.01_RUN_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-RUN_TITV_KNOWN_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.04_SELECT_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			${SCRIPT_DIR}/J.01-A.01-A.04-A.01_RUN_TITV_KNOWN.sh \
				$SAMTOOLS_0118_DIR \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

		RUN_TITV_NOVEL ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p ${PRIORITY} \
			-N J.01-A.01-A.05-A.01_RUN_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-RUN_TITV_NOVEL_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.05_SELECT_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"${PROJECT} \
			${SCRIPT_DIR}/J.01-A.01-A.05-A.01_RUN_TITV_NOVEL.sh \
				$SAMTOOLS_0118_DIR \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

QC_REPORT_PREP ()
{
echo \
qsub \
-S /bin/bash \
-cwd \
-V \
-q $QUEUE_LIST \
-p ${PRIORITY} \
-N X1"_"$SGE_SM_TAG \
-hold_jid \
J.01-A.01-A.05-A.01_RUN_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.01-A.01-A.04-A.01_RUN_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.01-A.01-A.03-A.01_RUN_TITV_ALL_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.03-A.01-A.02_TARGET_PASS_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.03-A.01-A.01_BAIT_PASS_MIXED_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.02-A.01-A.02_TARGET_PASS_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.02-A.01-A.01_BAIT_PASS_INDEL_QC"_"$SGE_SM_TAG"_"${PROJECT},\
J.01-A.01-A.02-A.01_SNV_TARGET_PASS_CONCORDANCE"_"$SGE_SM_TAG"_"${PROJECT},\
J.01-A.01-A.01_BAIT_PASS_SNV_QC"_"$SGE_SM_TAG"_"${PROJECT},\
E03-DOC_CODING_${SGE_SM_TAG}_${PROJECT},\
E04-DOC_BAIT_${SGE_SM_TAG}_${PROJECT},\
E05-A01-CHROM_DEPTH_${SGE_SM_TAG}_${PROJECT},\
F02-COLLECT_MULTIPLE_METRICS_${SGE_SM_TAG}_${PROJECT},\
F03-COLLECT_HS_METRICS_${SGE_SM_TAG}_${PROJECT},\
E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT},\
E06-A01-CAT_VERIFYBAMID_AUTO_${SGE_SM_TAG}_${PROJECT} \
-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-QC_REPORT_PREP_QC.log \
${SCRIPT_DIR}/X.01-QC_REPORT_PREP.sh \
$SAMTOOLS_DIR \
$DATAMASH_DIR \
${CORE_PATH} \
${PROJECT} \
${SM_TAG} \
${SAMPLE_SHEET} \
${SUBMIT_STAMP}
}

for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' ${SAMPLE_SHEET} | sort | uniq );
do
	CREATE_SAMPLE_ARRAY
	HC_BAM_TO_CRAM
	echo sleep 0.1s
	HC_INDEX_CRAM
	echo sleep 0.1s
	SELECT_SNV
	echo sleep 0.1s
	SELECT_INDEL
	echo sleep 0.1s
	SELECT_MIXED
	echo sleep 0.1s
	FILTER_SNV
	echo sleep 0.1s
	FILTER_INDEL
	echo sleep 0.1s
	FILTER_MIXED
	echo sleep 0.1s
	BAIT_PASS_SNV
	echo sleep 0.1s
	TARGET_PASS_SNV
	echo sleep 0.1s
	TARGET_PASS_SNV_CONCORDANCE
	echo sleep 0.1s
	BAIT_PASS_INDEL
	echo sleep 0.1s
	TARGET_PASS_INDEL
	echo sleep 0.1s
	BAIT_PASS_MIXED
	echo sleep 0.1s
	TARGET_PASS_MIXED
	echo sleep 0.1s
	SELECT_TITV_ALL
	echo sleep 0.1s
	SELECT_TITV_KNOWN
	echo sleep 0.1s
	SELECT_TITV_NOVEL
	echo sleep 0.1s
	RUN_TITV_ALL
	echo sleep 0.1s
	RUN_TITV_KNOWN
	echo sleep 0.1s
	RUN_TITV_NOVEL
	echo sleep 0.1s
	QC_REPORT_PREP
	echo sleep 0.1
done

#############################
##### END PROJECT TASKS #####
#############################

# grab email addy

	SEND_TO=`cat ${SCRIPT_DIR}/../email_lists.txt`

# grab submitter's name

	PERSON_NAME=`getent passwd | awk 'BEGIN {FS=":"} $1=="'$SUBMITTER_ID'" {print $5}'`

# build hold id for qc report prep per sample, per project

	BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP ()
	{
		HOLD_ID_PATH="-hold_jid "

		for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} $1=="'${PROJECT}'" {print $8}' \
			| sort \
			| uniq);
		do
			CREATE_SAMPLE_ARRAY
			HOLD_ID_PATH=$HOLD_ID_PATH"X1_"$SGE_SM_TAG","
			HOLD_ID_PATH=`echo $HOLD_ID_PATH | sed 's/@/_/g'`
		done
	}

# run end project functions (qc report, file clean-up) for each project

	PROJECT_WRAP_UP ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p ${PRIORITY} \
			-m e \
			-M khetric1@jhmi.edu \
			-j y \
		-N X.01-X.01_END_PROJECT_TASKS"_"${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${PROJECT}"-END_PROJECT_TASKS.log" \
		${HOLD_ID_PATH}"A00-LAB_PREP_METRICS_"${PROJECT} \
		${SCRIPT_DIR}/X.01-X.01-END_PROJECT_TASKS.sh \
			${CORE_PATH} \
			$DATAMASH_DIR \
			${PROJECT} \
			${SAMPLE_SHEET} \
			${SCRIPT_DIR} \
			$SUBMITTER_ID \
			${SUBMIT_STAMP}
	}

# final loop

for PROJECT in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} NR>1 {print $1}' \
			| sort \
			| uniq);
do
	BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP
	PROJECT_WRAP_UP
done

# EMAIL WHEN DONE SUBMITTING

printf "${SAMPLE_SHEET}\nhas finished submitting at\n`date`\nby `whoami`" \
	| mail -s "$PERSON_NAME has submitted CIDR.WES.QC.SUBMITTER.sh" \
		$SEND_TO
