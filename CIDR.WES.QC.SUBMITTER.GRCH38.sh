#!/bin/bash

SAMPLE_SHEET=$1
	SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)

# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED

SCRIPT_DIR="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CIDR_WES/grch38_scripts"

##################
# CORE VARIABLES #
##################

	# Directory where sequencing projects are located

		CORE_PATH="/mnt/research/active"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# Generate a list of active queue and remove the ones that I don't want to use

		QUEUE_LIST=`qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue" \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q" \
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

	# EVENTUALLY I WANT THIS SET UP AS AN OPTION WITH A DEFAULT OF X

		PRIORITY="-750"

		PIPELINE_VERSION=`git --git-dir=$SCRIPT_DIR/../.git --work-tree=$SCRIPT_DIR/.. log --pretty=format:'%h' -n 1`

		# load gcc for programs like verifyBamID
		## this will get pushed out to all of the compute nodes since I specify env var to pushed out with qsub
			module load gcc/7.2.0

		# explicitly setting this b/c not everybody has had the $HOME directory transferred and I'm not going to through
		# and figure out who does and does not have this set correctly
			umask 0007

	# SUBMIT TIMESTAMP

		SUBMIT_STAMP=`date '+%s'`

#####################
# PIPELINE PROGRAMS #
#####################

	BWA_DIR="/mnt/linuxtools/BWA/bwa-0.7.15"
	SAMBLASTER_DIR="/mnt/linuxtools/SAMBLASTER/samblaster-v.0.1.24"
	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	PICARD_DIR="/mnt/linuxtools/PICARD/picard-2.17.0"
	PICARD_DIR_LIFTOVER="/mnt/linuxtools/PICARD/picard-2.18.25"
	DATAMASH_DIR="/mnt/linuxtools/DATAMASH/datamash-1.0.6"
	GATK_DIR="/mnt/linuxtools/GATK/GenomeAnalysisTK-3.7"
	# This is samtools version 1.5
	# I have no idea why other users other than me cannot index a cram file with a version of samtools that I built from the source
	# Apparently the version that I built with Anaconda works for other users, but it performs REF_CACHE first...
	SAMTOOLS_DIR="/mnt/linuxtools/ANACONDA/anaconda2-5.0.0.1/bin"
	BEDTOOLS_DIR="/mnt/linuxtools/BEDTOOLS/bedtools-2.22.0/bin"
	VERIFY_DIR="/mnt/linuxtools/verifyBamID/verifyBamID_1.1.3/verifyBamID/bin"
	SAMTOOLS_0118_DIR="/mnt/linuxtools/SAMTOOLS/samtools-0.1.18"
		# Becasue I didn't want to go through compiling this yet for version 1.6...I'm hoping that Keith will eventually do a full OS install of RHEL7 instead of his
		# typical stripped down installations so I don't have to install multiple libraries again
	CIDRSEQSUITE_6_JAVA_DIR="/mnt/linuxtools/JAVA/jre1.7.0_45/bin"
	CIDRSEQSUITE_6_1_1_DIR="/mnt/linuxtools/CIDRSEQSUITE/6.1.1"
	SAMBAMBA_DIR="/mnt/linuxtools/SAMBAMBA/sambamba_v0.6.8"
	GATK_DIR_4011="/mnt/linuxtools/GATK/gatk-4.0.11.0"
	CIDRSEQSUITE_7_5_0_DIR="/mnt/linuxtools/CIDRSEQSUITE/7.5.0"
	LAB_QC_DIR="/mnt/linuxtools/CUSTOM_CIDR/EnhancedSequencingQCReport/0.0.5"
		# Copied from /mnt/research/tools/LINUX/CIDRSEQSUITE/pipeline_dependencies/QC_REPORT/EnhancedSequencingQCReport.jar

##################
# PIPELINE FILES #
##################

	CODING_BED="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/gencode24_primary_collapsed.bed"
		# md5 acda5ab9bebcb9520f5ec9670ea09432
	GENE_LIST="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/RefSeqAll_hg38.gatk.txt"
		# md5 45ca8b6e8806fd6233863cbee464a906
		# need to create a link detailing how this file was created
	CYTOBAND_BED="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/GRCh38.Cytobands.bed"
		# md5 cac717c6bc149001c013a3a6c594908d
		# note that I should put some code in here to ignore the header, ^#
		# this is from ucsc
	VERIFY_VCF="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg38.liftover.vcf"
		# md5 d71b55cde492b722a95021a5fb5a4d83
	DBSNP_129="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/dbsnp_138.hg38.liftover.excluding_sites_after_129.vcf.gz"
		# md5 85f3e9f0d5f30de2a046594b4ab4de86
	VERACODE_CSV="/mnt/research/tools/LINUX/CIDRSEQSUITE/resources/Veracode_hg18_hg19.csv"
	MERGED_MENDEL_BED_FILE="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1_GRCh38/BED_Files/BAITS_Merged_S03723314_S06588914.lift.hg38.bed"
		# 4aa700700812d52c19f97c584eaca918
	HG38_TO_HG19_CHAIN="/mnt/shared_resources/public_resources/liftOver_chain/hg38ToHg19.over.chain"
	HG19_REF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/hg19/ucsc.hg19.fasta"
	HG19_DICT="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/hg19/ucsc.hg19.dict"

#################################
##### MAKE A DIRECTORY TREE #####
#################################

	# make an array for each sample with information needed for pipeline input obtained from the sample sheet
		# add a end of file is not present
		# remove carriage returns if not present, remove blank lines if present, remove lines that only have whitespace

		CREATE_PROJECT_ARRAY ()
		{
			PROJECT_ARRAY=(`awk 1 $SAMPLE_SHEET \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=","} $1=="'$PROJECT_NAME'" {print $1}' \
				| sort \
				| uniq`)

			#  1  Project=the Seq Proj folder name
			SEQ_PROJECT=${PROJECT_ARRAY[0]}
		}

	# for every project in the sample sheet create all of the folders in the project if they don't already exist

		MAKE_PROJ_DIR_TREE ()
		{
			mkdir -p \
			$CORE_PATH/$SEQ_PROJECT/{TEMP,FASTQ,LOGS,CRAM,GVCF,COMMAND_LINES,HC_CRAM} \
			$CORE_PATH/$SEQ_PROJECT/INDEL/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/INDEL/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/SNV/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/SNV/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/MIXED/QC/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/MIXED/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/VCF/QC/FILTERED_ON_BAIT \
			$CORE_PATH/$SEQ_PROJECT/VCF/RELEASE/{FILTERED_ON_BAIT,FILTERED_ON_TARGET} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/{ALIGNMENT_SUMMARY,ANNOVAR,PICARD_DUPLICATES,VERIFYBAMID,VERIFYBAMID_CHR,QC_REPORT_PREP,QC_REPORTS,LAB_PREP_REPORTS,QUALITY_YIELD,ERROR_SUMMARY} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/{TI_TV,TI_TV_MS} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/BAIT_BIAS/{METRICS,SUMMARY} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/PRE_ADAPTER/{METRICS,SUMMARY} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/{METRICS,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/{CONCORDANCE,CONCORDANCE_MS} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/COUNT_COVARIATES/{GATK_REPORT,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/GC_BIAS/{METRICS,PDF,SUMMARY} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/DEPTH_OF_COVERAGE/{TARGET,UCSC,BED_SUPERSET} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/INSERT_SIZE/{METRICS,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/MEAN_QUALITY_BY_CYCLE/{METRICS,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
			$CORE_PATH/$SEQ_PROJECT/REPORTS/ANEUPLOIDY_CHECK
		}

	# run ben's enhanced sequencing lab prep metrics report generator which queries phoenix among other things.

		RUN_LAB_PREP_METRICS ()
		{
			echo \
			qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
			-N A.02-LAB_PREP_METRICS"_"$PROJECT_NAME \
			-o $CORE_PATH/$PROJECT_NAME/LOGS/$PROJECT_NAME"-LAB_PREP_METRICS.log" \
			-j y \
			$SCRIPT_DIR/A.02_LAB_PREP_METRICS.sh \
			$JAVA_1_8 \
			$LAB_QC_DIR \
			$CORE_PATH \
			$PROJECT_NAME \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP
		}

	SETUP_PROJECT ()
	{
		CREATE_PROJECT_ARRAY
		MAKE_PROJ_DIR_TREE
		RUN_LAB_PREP_METRICS
		echo Project started at `date` >> $CORE_PATH/$SEQ_PROJECT/REPORTS/PROJECT_START_END_TIMESTAMP.txt
		# this is for tracking failed jobs so I can clean up the temp directory if everything ran successfully
		echo >| $CORE_PATH/$SEQ_PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.csv"
	}

for PROJECT_NAME in $(awk 'BEGIN {FS=","} NR>1 {print $1}' $SAMPLE_SHEET | sort | uniq );
	do
		SETUP_PROJECT
done

########################################################################################
# create an array at the platform level so that bwa mem can add metadata to the header #
########################################################################################

	CREATE_PLATFORM_UNIT_ARRAY ()
	{
		PLATFORM_UNIT_ARRAY=(`awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} $8$2$3$4=="'$PLATFORM_UNIT'" {split($19,INDEL,";"); print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
			| sort \
			| uniq`)

		#  1  Project=the Seq Proj folder name
		PROJECT=${PLATFORM_UNIT_ARRAY[0]}

		#  2  FCID=flowcell that sample read group was performed on
		FCID=${PLATFORM_UNIT_ARRAY[1]}

		#  3  Lane=lane of flowcell that sample read group was performed on]
		LANE=${PLATFORM_UNIT_ARRAY[2]}

		#  4  Index=sample barcode
		INDEX=${PLATFORM_UNIT_ARRAY[3]}

		#  5  Platform=type of sequencing chemistry matching SAM specification
		PLATFORM=${PLATFORM_UNIT_ARRAY[4]}

		#  6  Library_Name=library group of the sample read group, Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not
		LIBRARY=${PLATFORM_UNIT_ARRAY[5]}

		#  7  Date=should be the run set up date to match the seq run folder name, but it has been arbitrarily populated
		RUN_DATE=${PLATFORM_UNIT_ARRAY[6]}

		#  8  SM_Tag=sample ID
		SM_TAG=${PLATFORM_UNIT_ARRAY[7]}
		SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks

		#  9  Center=the center/funding mechanism
		CENTER=${PLATFORM_UNIT_ARRAY[8]}

		# 10  Description=Generally we use to denote the sequencer setting (e.g. rapid run)
		# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.
		SEQUENCER_MODEL=${PLATFORM_UNIT_ARRAY[9]}

		#############################
		# 11  Seq_Exp_ID ### SKIP ###
		#############################

		# 12  Genome_Ref=the reference genome used in the analysis pipeline
		REF_GENOME=${PLATFORM_UNIT_ARRAY[10]}

		###########################
		# 13  Operator ### SKIP ###
		##########################################
		# 14  Extra_VCF_Filter_Params ### SKIP ###
		##########################################

		# 15  TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files
		TITV_BED=${PLATFORM_UNIT_ARRAY[11]}

		# 16  Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
		# Used for limited where to run base quality score recalibration on where to create gvcf files.
		BAIT_BED=${PLATFORM_UNIT_ARRAY[12]}

		# 17  Targets_BED_File=bed file acquired from manufacturer of their targets.
		TARGET_BED=${PLATFORM_UNIT_ARRAY[13]}

		# 18  KNOWN_SITES_VCF=used to annotate ID field in VCF file. masking in base call quality score recalibration.
		DBSNP=${PLATFORM_UNIT_ARRAY[14]}

		# 19  KNOWN_INDEL_FILES=used for BQSR masking, sensitivity in local realignment.
		KNOWN_INDEL_1=${PLATFORM_UNIT_ARRAY[15]}
		KNOWN_INDEL_2=${PLATFORM_UNIT_ARRAY[16]}
	}

###########################################################################################################################################
# Use bwa mem to do the alignments; pipe to samblaster to add mate tags; pipe to picard's AddOrReplaceReadGroups to handle the bam header #
###########################################################################################################################################

	RUN_BWA ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N A.01-BWA"_"$SGE_SM_TAG"_"$FCID"_"$LANE"_"$INDEX \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"_"$FCID"_"$LANE"_"$INDEX"-BWA.log" \
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
			$REF_GENOME \
			$PIPELINE_VERSION \
			$BAIT_BED \
			$TARGET_BED \
			$TITV_BED \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP \
			$NOVASEQ_REPO
	}

for PLATFORM_UNIT in $(awk 'BEGIN {FS=","} NR>1 {print $8$2$3$4}' $SAMPLE_SHEET | sort | uniq );
	do
		CREATE_PLATFORM_UNIT_ARRAY
		mkdir -p $CORE_PATH/$PROJECT/LOGS/$SM_TAG
		RUN_BWA
		echo sleep 0.1s
done

###############################################################################
# create a hold job id qsub command line based on the number of ###############
# submit merging the bam files created by bwa mem above #######################
# only launch when every lane for a sample is done being processed by bwa mem #
# I want to clean this up eventually, but not in the mood for it right now. ###
###############################################################################
	#########################################################################################
	# I am setting the heap space and garbage collector threads now #########################
	# doing this does drastically decrease the load average ( the gc thread specification ) #
	#########################################################################################

		awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","; OFS="\t"} NR>1 {print $1,$8,$2"_"$3"_"$4,$2"_"$3"_"$4".bam",$8,$10}' \
			| awk 'BEGIN {OFS="\t"} {sub(/@/,"_",$5)} {print $1,$2,$3,$4,$5,$6}' \
			| sort -k 1,1 -k 2,2 -k 3,3 \
			| uniq \
			| $DATAMASH_DIR/datamash -s -g 1,2 collapse 3 collapse 4 unique 5 unique 6 \
			| awk 'BEGIN {FS="\t"} \
				gsub(/,/,",A.01-BWA_"$5"_",$3) \
				gsub(/,/,",INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/",$4) \
				{print "qsub",\
				"-S /bin/bash",\
				"-cwd",\
				"-V",\
				"-q","'$QUEUE_LIST'",\
				"-p","'$PRIORITY'",\
				"-N","C.01-MARK_DUPLICATES_"$5"_"$1,\
				"-o","'$CORE_PATH'/"$1"/LOGS/"$2"/"$2"-MARK_DUPLICATES.log",\
				"-j y",\
				"-hold_jid","A.01-BWA_"$5"_"$3, \
				"'$SCRIPT_DIR'""/C.01_MARK_DUPLICATES.sh",\
				"'$JAVA_1_8'",\
				"'$PICARD_DIR'",\
				"'$SAMBAMBA_DIR'",\
				"'$CORE_PATH'",\
				$1,\
				$2,\
				"'$SAMPLE_SHEET'",\
				"'$SUBMIT_STAMP'",\
				$6,\
				"INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/"$4"\n""sleep 0.1s"}'

###################################################
###################################################
### PROCEEDING WITH AGGREGATED SAMPLE FILES NOW ###
###################################################
###################################################

	################################################################################
	# create an array at the SM tag level to populate aggregated sample variables. #
	################################################################################

		CREATE_SAMPLE_ARRAY ()
		{
			SAMPLE_ARRAY=(`awk 1 $SAMPLE_SHEET \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=","} $8=="'$SM_TAG'" {split($19,INDEL,";"); print $1,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
				| sort \
				| uniq`)

			#  1  Project=the Seq Proj folder name
			PROJECT=${SAMPLE_ARRAY[0]}

			###################################################################
			#  2 SKIP : FCID=flowcell that sample read group was performed on #
			###################################################################

			############################################################################
			#  3 SKIP : Lane=lane of flowcell that sample read group was performed on] #
			############################################################################

			################################
			#  4 SKIP Index=sample barcode #
			################################

			#  5  Platform=type of sequencing chemistry matching SAM specification
			PLATFORM=${SAMPLE_ARRAY[1]}

			#  6  Library_Name=library group of the sample read group, Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not
			LIBRARY=${SAMPLE_ARRAY[2]}

			#  7  Date=should be the run set up date to match the seq run folder name, but it has been arbitrarily populated
			RUN_DATE=${SAMPLE_ARRAY[3]}

			#  8  SM_Tag=sample ID
			SM_TAG=${SAMPLE_ARRAY[4]}
			SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks

			#  9  Center=the center/funding mechanism
			CENTER=${SAMPLE_ARRAY[5]}

			# 10  Description=Generally we use to denote the sequencer setting (e.g. rapid run)
			# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.
			SEQUENCER_MODEL=${SAMPLE_ARRAY[6]}

			#############################
			# 11  Seq_Exp_ID ### SKIP ###
			#############################

			# 12  Genome_Ref=the reference genome used in the analysis pipeline
			REF_GENOME=${SAMPLE_ARRAY[7]}

			###########################
			# 13  Operator ### SKIP ###
			##########################################
			# 14  Extra_VCF_Filter_Params ### SKIP ###
			##########################################

			# 15  TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files
			TITV_BED=${SAMPLE_ARRAY[8]}

			# 16  Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
			# Used for limited where to run base quality score recalibration on where to create gvcf files.
			BAIT_BED=${SAMPLE_ARRAY[9]}

				# since the mendel changes capture products need a way to define a 4th bed file which is the union of the different captures used.
					if [[ $PROJECT = "M_Valle"* ]];
						then
							HC_BAIT_BED=${MERGED_MENDEL_BED_FILE}
					else
						HC_BAIT_BED=${BAIT_BED}
					fi

			# 17  Targets_BED_File=bed file acquired from manufacturer of their targets.
			TARGET_BED=${SAMPLE_ARRAY[10]}

			# 18  KNOWN_SITES_VCF=used to annotate ID field in VCF file. masking in base call quality score recalibration.
			DBSNP=${SAMPLE_ARRAY[11]}

			# 19  KNOWN_INDEL_FILES=used for BQSR masking, sensitivity in local realignment.
			KNOWN_INDEL_1=${SAMPLE_ARRAY[12]}
			KNOWN_INDEL_2=${SAMPLE_ARRAY[13]}
		}

	#############################################
	## using data only in the baited intervals ##
	#############################################
	## REMINDER TO HANDLE THE NEW JAR FILE NAME #
	#############################################

		FIX_BED_FILES ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-FIX_BED_FILES.log" \
				-j y \
			-hold_jid C.01-MARK_DUPLICATES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/A.00_FIX_BED.sh \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$BAIT_BED \
				$TARGET_BED \
				$TITV_BED \
				$REF_GENOME \
				$JAVA_1_8 \
				$PICARD_DIR \
				$HG38_TO_HG19_CHAIN \
				$HG19_DICT
		}

	# run bqsr on the using bait bed file

		RUN_BQSR ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N D.01-PERFORM_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-PERFORM_BQSR.log" \
				-j y \
			-hold_jid C.01-MARK_DUPLICATES"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/D.01_PERFORM_BQSR.sh \
				$JAVA_1_8 \
				$GATK_DIR_4011 \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$KNOWN_INDEL_1 \
				$KNOWN_INDEL_2 \
				$DBSNP \
				$BAIT_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
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
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-APPLY_BQSR.log" \
				-j y \
			-hold_jid D.01-PERFORM_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/E.01_APPLY_BQSR.sh \
				$JAVA_1_8 \
				$GATK_DIR_4011 \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
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
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.08-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-SELECT_VERIFYBAMID_VCF.log" \
				-j y \
			-hold_jid E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.08_SELECT_VERIFYBAMID_VCF.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$VERIFY_VCF \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$TARGET_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###################
	# RUN VERIFYBAMID #
	###################

		RUN_VERIFYBAMID ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.08-A.01-RUN_VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VERIFYBAMID.log" \
				-j y \
			-hold_jid H.08-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.08-A.01_VERIFYBAMID.sh \
				$CORE_PATH \
				$VERIFY_DIR \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}


# taking out the post BQSR and analyze covariates until i update them to gatk 4
# also need to look into R for analyze covariates

	for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
		do
			CREATE_SAMPLE_ARRAY
			FIX_BED_FILES
			echo sleep 0.1s
			# FIX_BAM_HEADER
			# echo sleep 0.1s
			# fix bam header shouldn't be needed when running sambamba 0.6.8
			RUN_BQSR
			echo sleep 0.1s
			APPLY_BQSR
			echo sleep 0.1s
			SELECT_VERIFYBAMID_VCF
			echo sleep 0.1s
			RUN_VERIFYBAMID
			echo sleep 0.1s
		done

#####################################
##### VERIFYBAMID BY CHROMOSOME #####
#####################################
	#####################################
	# VERIFYBAMID BY CHROMOSOME SCATTER #
	#####################################

		# make per chromosome/target bed file intersection vcf files for each sample

			CALL_SELECT_VERIFYBAMID_VCF_CHR ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
				-N H.09-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME \
					-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-SELECT_VERIFYBAMID_VCF_"$CHROMOSOME".log" \
					-j y \
				-hold_jid E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
					$SCRIPT_DIR/H.09_SELECT_VERIFYBAMID_VCF_CHR.sh \
					$JAVA_1_8 \
					$GATK_DIR \
					$CORE_PATH \
					$VERIFY_VCF \
					$PROJECT \
					$SM_TAG \
					$REF_GENOME \
					$TARGET_BED \
					$CHROMOSOME \
					$SAMPLE_SHEET \
					$SUBMIT_STAMP
			}

			CALL_VERIFYBAMID_CHR ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
				-N H.09-A.01-VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME \
					-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VERIFYBAMID_"$CHROMOSOME".log" \
					-j y \
				-hold_jid H.09-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME \
				$SCRIPT_DIR/H.09-A.01_VERIFYBAMID_CHR.sh \
					$CORE_PATH \
					$VERIFY_DIR \
					$PROJECT \
					$SM_TAG \
					$CHROMOSOME \
					$SAMPLE_SHEET \
					$SUBMIT_STAMP
			}

		# Take the samples target bed file, create a list of unique chromosome to use as a scatter for verifybamid, exclude chr X,Y,MT

			for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
			do
				CREATE_SAMPLE_ARRAY
					for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
						| sed -r 's/[[:space:]]+/\t/g' \
						| cut -f 1 \
						| egrep -v "X|Y|MT" \
						| sort \
						| uniq \
						| $DATAMASH_DIR/datamash collapse 1 \
						| sed 's/,/ /g');
						do
							CALL_SELECT_VERIFYBAMID_VCF_CHR
							echo sleep 0.1s
							CALL_VERIFYBAMID_CHR
							echo sleep 0.1s
						done
			done

	####################################
	# VERIFYBAMID BY CHROMOSOME GATHER #
	####################################

		# GATHER UP THE PER CHROMOSOME PER SAMPLE VERIFYBAMID OUTPUT FILES
		# I THINK THAT I SHOULD BE ABLE TO INCORPORATE THIS INTO THE ABOVE LOOP.

			BUILD_HOLD_ID_PATH_CAT_VERIFYBAMID ()
			{
				HOLD_ID_PATH_CAT_VERIFYBAMID="-hold_jid "
				for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $TARGET_BED \
										| sed -r 's/[[:space:]]+/\t/g' \
										| cut -f 1 \
										| egrep -v "X|Y|MT" \
										| sort \
										| uniq \
										| $DATAMASH_DIR/datamash collapse 1 \
										| sed 's/,/ /g');
					do
						HOLD_ID_PATH_CAT_VERIFYBAMID=$HOLD_ID_PATH_CAT_VERIFYBAMID"H.09-A.01-VERIFYBAMID_"$SM_TAG"_"$PROJECT"_"$CHROMOSOME","
						HOLD_ID_PATH_CAT_VERIFYBAMID=`echo $HOLD_ID_PATH_CAT_VERIFYBAMID | sed 's/@/_/g'`
				done
			}

			CALL_VERIFYBAMID_CHR_GATHER ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
				-N H.09-A.01-A.01_CAT_VERIFYBAMID_CHR"_"$SGE_SM_TAG"_"$PROJECT \
					-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-CAT_VERIFYBAMID_CHR.log \
					-j y \
				${HOLD_ID_PATH_CAT_VERIFYBAMID} \
				$SCRIPT_DIR/H.09-A.01-A.01_CAT_VERIFYBAMID_CHR.sh \
					$CORE_PATH \
					$DATAMASH_DIR \
					$PROJECT \
					$SM_TAG \
					$TARGET_BED
			}

for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
do
	CREATE_SAMPLE_ARRAY
	BUILD_HOLD_ID_PATH_CAT_VERIFYBAMID
	CALL_VERIFYBAMID_CHR_GATHER
	echo sleep 0.1s
done

############################
# HAPLOTYPE CALLER SCATTER #
############################

	# THE JOB DEPENDENCY IS THE BAM FILE B/C CRAM SUPORRT WAS BROKEN IN GATK 3.7 AND 3.8
	# WILL WANT TO SWITCH TO CRAM WHEN USING A VERSION OF GATK WHERE THIS NOT BROKEN
	# This is why i have both verifybamId and a bam/cram dependency, b/c verifybamID has to come after the bam file.
	# the freemix value from verifybamID output is pulled as a variable to the haplotype caller script

		CALL_HAPLOTYPE_CALLER ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.01-HAPLOTYPE_CALLER"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HAPLOTYPE_CALLER_"$CHROMOSOME".log" \
				-j y \
			-hold_jid E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT,H.08-A.01-RUN_VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.01_HAPLOTYPE_CALLER_SCATTER.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$HC_BAIT_BED \
				$CHROMOSOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

		CALL_GENOTYPE_GVCF ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N I.01-GENOTYPE_GVCF"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-GENOTYPE_GVCF_"$CHROMOSOME".log" \
				-j y \
			-hold_jid H.01-HAPLOTYPE_CALLER"_"$SGE_SM_TAG"_"$PROJECT"_"$CHROMOSOME,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/I.01_GENOTYPE_GVCF_SCATTER.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$DBSNP \
				$CHROMOSOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP \
				$BAIT_BED
		}

# Take the samples bait bed file, create a list of unique chromosome to use as a scatter for haplotype_caller_scatter

for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
	do
	CREATE_SAMPLE_ARRAY
		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $HC_BAIT_BED \
			| sed -r 's/[[:space:]]+/\t/g' \
			| cut -f 1 \
			| sort \
			| uniq \
			| $DATAMASH_DIR/datamash collapse 1 \
			| sed 's/,/ /g');
			do
				CALL_HAPLOTYPE_CALLER
				echo sleep 0.1s
				CALL_GENOTYPE_GVCF
				echo sleep 0.1s
		done
done

###########################
# HAPLOTYPE CALLER GATHER #
################################################################################
# GATHER UP THE PER SAMPLE PER CHROMOSOME GVCF FILES INTO A SINGLE SAMPLE GVCF #
################################################################################

	BUILD_HOLD_ID_PATH ()
	{
		HOLD_ID_PATH="-hold_jid "
		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $BAIT_BED \
								| sed -r 's/[[:space:]]+/\t/g' \
								| cut -f 1 \
								| sort \
								| uniq \
								| $DATAMASH_DIR/datamash collapse 1 \
								| sed 's/,/ /g');
			do
				HOLD_ID_PATH=$HOLD_ID_PATH"H.01-HAPLOTYPE_CALLER_"$SM_TAG"_"$PROJECT"_"$CHROMOSOME","
				HOLD_ID_PATH=`echo $HOLD_ID_PATH | sed 's/@/_/g'`
		done
	}

	CALL_HAPLOTYPE_CALLER_GVCF_GATHER ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N H.01-A.01_HAPLOTYPE_CALLER_GVCF_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-HAPLOTYPE_CALLER_GVCF_GATHER.log \
			-j y \
		${HOLD_ID_PATH} \
		$SCRIPT_DIR/H.01-A.01_HAPLOTYPE_CALLER_GVCF_GATHER.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$BAIT_BED \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP
	}

	CALL_HAPLOTYPE_CALLER_BAM_GATHER ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N H.01-A.02_HAPLOTYPE_CALLER_BAM_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-HAPLOTYPE_CALLER_BAM_GATHER.log \
			-j y \
		${HOLD_ID_PATH} \
		$SCRIPT_DIR/H.01-A.02_HAPLOTYPE_CALLER_BAM_GATHER.sh \
			$JAVA_1_8 \
			$PICARD_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$BAIT_BED \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP
	}

########################
# GENOTYPE GVCF GATHER #
########################

# GATHER UP THE PER SAMPLE PER CHROMOSOME VCF FILES INTO A GVCF

	BUILD_HOLD_ID_PATH_GENOTYPE_GVCF_GATHER()
	{
		HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="-hold_jid "
			for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' $BAIT_BED \
									| sed -r 's/[[:space:]]+/\t/g' \
									| cut -f 1 \
									| sort \
									| uniq \
									| $DATAMASH_DIR/datamash collapse 1 \
									| sed 's/,/ /g');
				do
					HOLD_ID_PATH_GENOTYPE_GVCF_GATHER=$HOLD_ID_PATH_GENOTYPE_GVCF_GATHER"I.01-GENOTYPE_GVCF_"$SM_TAG"_"$PROJECT"_"$CHROMOSOME","
					HOLD_ID_PATH_GENOTYPE_GVCF_GATHER=`echo $HOLD_ID_PATH_GENOTYPE_GVCF_GATHER | sed 's/@/_/g'`
			done
	}

	CALL_GENOTYPE_GVCF_GATHER ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N I.01-A.01_GENOTYPE_GVCF_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-GENOTYPE_GVCF_GATHER.log \
			-j y \
		${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} \
		$SCRIPT_DIR/I.01-A.01_GENOTYPE_GVCF_GATHER.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$BAIT_BED \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP
	}

for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
	do
		CREATE_SAMPLE_ARRAY
		BUILD_HOLD_ID_PATH
		BUILD_HOLD_ID_PATH_GENOTYPE_GVCF_GATHER
		CALL_HAPLOTYPE_CALLER_GVCF_GATHER
		echo sleep 0.1s
		CALL_HAPLOTYPE_CALLER_BAM_GATHER
		echo sleep 0.1s
		CALL_GENOTYPE_GVCF_GATHER
		echo sleep 0.1s
done

	#####################################################
	# create a lossless cram, although the bam is lossy #
	#####################################################

		BAM_TO_CRAM ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N F.01-BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-BAM_TO_CRAM.log" \
				-j y \
			-hold_jid E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/F.01_BAM_TO_CRAM.sh \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##########################################################################################
	# index the cram file and copy it so that there are both *crai and cram.crai *extensions #
	##########################################################################################

		INDEX_CRAM ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-INDEX_CRAM.log" \
				-j y \
			-hold_jid F.01-BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/G.01_INDEX_CRAM.sh \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#############################################
	# do the md5sum hash value on the cram file #
	##########################################################################################
	# also doing it on the *cram.crai file and append to the same output for sra submissions #
	##########################################################################################

		MD5SUM_CRAM ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N G.02-MD5SUM_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-MD5SUM_CRAM.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/G.02_MD5SUM_CRAM.sh \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG
		}

	###############################################
	# CREATE DEPTH OF COVERAGE FOR ALL UCSC EXONS #
	###############################################

		DOC_CODING ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.03-DOC_CODING"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-DOC_CODING.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.03_DOC_CODING.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$CODING_BED \
				$GENE_LIST \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME
		}

	#############################################
	# CREATE DEPTH OF COVERAGE FOR BED SUPERSET #
	#############################################

		DOC_BAIT ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.04-DOC_BAIT"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-DOC_BED_SUPERSET.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04_DOC_BED_SUPERSET.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$BAIT_BED \
				$GENE_LIST \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME
		}

	#############################################
	# CREATE  DEPTH OF COVERAGE FOR TARGET BED  #
	#############################################

		DOC_TARGET ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.05-DOC_TARGET"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-DOC_TARGET.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.05_DOC_TARGET.sh \
				$JAVA_1_8 \
				$GATK_DIR \
				$CORE_PATH \
				$TARGET_BED \
				$GENE_LIST \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME
		}

	#########################################################
	# DO AN ANEUPLOIDY CHECK ON TARGET BED FILE DOC OUTPUT  #
	#########################################################

		ANEUPLOIDY_CHECK ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.05-A.01_CHROM_DEPTH"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-ANEUPLOIDY_CHECK.log" \
				-j y \
			-hold_jid H.05-DOC_TARGET"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.05-A.01_CHROM_DEPTH.sh \
				$CORE_PATH \
				$CYTOBAND_BED \
				$DATAMASH_DIR \
				$BEDTOOLS_DIR \
				$PROJECT \
				$SM_TAG
		}

	#############################
	# COLLECT MULTIPLE METRICS  #
	#############################

		COLLECT_MULTIPLE_METRICS ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.06-COLLECT_MULTIPLE_METRICS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COLLECT_MULTIPLE_METRICS.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.06_COLLECT_MULTIPLE_METRICS.sh \
				$JAVA_1_8 \
				$PICARD_DIR \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$DBSNP
		}

	#######################
	# COLLECT HS METRICS  #
	#######################

		COLLECT_HS_METRICS ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N H.07-COLLECT_HS_METRICS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COLLECT_HS_METRICS.log" \
				-j y \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.07_COLLECT_HS_METRICS.sh \
				$JAVA_1_8 \
				$PICARD_DIR \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$BAIT_BED \
				$TARGET_BED
		}

# taking out the post BQSR and analyze covariates until i update them to gatk 4
# also need to look into R for analyze covariates

	for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
		do
			CREATE_SAMPLE_ARRAY
			BAM_TO_CRAM
			echo sleep 0.1s
			INDEX_CRAM
			echo sleep 0.1s
			MD5SUM_CRAM
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
				-p $PRIORITY \
			-N H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HC_BAM_TO_CRAM.log" \
				-j y \
			-hold_jid H.01-A.02_HAPLOTYPE_CALLER_BAM_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM.sh \
				$SAMTOOLS_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME
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
			-p $PRIORITY \
		-N H.01-A.02-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HC_INDEX_CRAM.log" \
			-j y \
		-hold_jid H.01-A.02-A.01_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/H.01-A.02-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM.sh \
			$SAMTOOLS_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	SELECT_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01_SELECT_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_SNV_QC.log \
			-j y \
		-hold_jid I.01-A.01_GENOTYPE_GVCF_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01_SELECT_SNV.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	SELECT_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.02_SELECT_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_INDEL_QC.log \
			-j y \
		-hold_jid I.01-A.01_GENOTYPE_GVCF_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.02_SELECT_INDEL.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	SELECT_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.03_SELECT_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_MIXED_QC.log \
			-j y \
		-hold_jid I.01-A.01_GENOTYPE_GVCF_GATHER"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.03_SELECT_MIXED.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	FILTER_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-FILTER_SNV_QC.log \
			-j y \
		-hold_jid J.01_SELECT_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01_FILTER_SNV.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	FILTER_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-FILTER_INDEL_QC.log \
			-j y \
		-hold_jid J.02_SELECT_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.02-A.01_FILTER_INDEL.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	FILTER_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-FILTER_MIXED_QC.log \
			-j y \
		-hold_jid J.03_SELECT_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.03-A.01_FILTER_MIXED.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	BAIT_PASS_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01-A.01_BAIT_PASS_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-BAIT_PASS_SNV_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01-A.01_SNV_BAIT_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	TARGET_PASS_SNV ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01-A.02_TARGET_PASS_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-TARGET_PASS_SNV_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01-A.02_SNV_TARGET_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TARGET_BED
	}

	# liftover from hg38 to hg19 the vcf file

		LIFTOVER_TARGET_PASS_SNV ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N J.01-A.01-A.02-A.01_SNV_TARGET_LIFTOVER_HG19"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-TARGET_SNV_TARGET_LIFTOVER.log \
				-j y \
			-hold_jid J.01-A.01-A.02_TARGET_PASS_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/J.01-A.01-A.02-A.01_SNV_TARGET_LIFTOVER_HG19.sh \
				$JAVA_1_8 \
				$PICARD_DIR_LIFTOVER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$HG19_REF \
				$HG38_TO_HG19_CHAIN
		}

		# do concordance on the lifted over vcf

			TARGET_PASS_SNV_CONCORDANCE ()
			{
				echo \
				qsub \
					-S /bin/bash \
					-cwd \
					-V \
					-q $QUEUE_LIST \
					-p $PRIORITY \
				-N J.01-A.01-A.02-A.01-A.01_SNV_TARGET_PASS_CONCORDANCE"_"$SGE_SM_TAG"_"$PROJECT \
					-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-TARGET_PASS_SNV_QC_CONCORDANCE.log \
					-j y \
				-hold_jid J.01-A.01-A.02-A.01_SNV_TARGET_LIFTOVER_HG19"_"$SGE_SM_TAG"_"$PROJECT,A.00-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
				$SCRIPT_DIR/J.01-A.01-A.02-A.01-A.01_SNV_TARGET_PASS_CONCORDANCE.sh \
					$JAVA_1_8 \
					$CIDRSEQSUITE_7_5_0_DIR \
					$VERACODE_CSV \
					$CORE_PATH \
					$PROJECT \
					$SM_TAG \
					$TARGET_BED
			}

	BAIT_PASS_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.02-A.01-A.01_BAIT_PASS_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-BAIT_PASS_INDEL_QC.log \
			-j y \
		-hold_jid J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.02-A.01-A.01_INDEL_BAIT_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	TARGET_PASS_INDEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.02-A.01-A.02_TARGET_PASS_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-TARGET_PASS_INDEL_QC.log \
			-j y \
		-hold_jid J.02-A.01_FILTER_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.02-A.01-A.02_INDEL_TARGET_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TARGET_BED
	}

	BAIT_PASS_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.03-A.01-A.01_BAIT_PASS_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-BAIT_PASS_MIXED_QC.log \
			-j y \
		-hold_jid J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.03-A.01-A.01_MIXED_BAIT_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME
	}

	TARGET_PASS_MIXED ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.03-A.01-A.02_TARGET_PASS_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-TARGET_PASS_MIXED_QC.log \
			-j y \
		-hold_jid J.03-A.01_FILTER_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.03-A.01-A.02_MIXED_TARGET_PASS.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TARGET_BED
	}

	SELECT_TITV_ALL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01-A.03_SELECT_TITV_ALL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_TITV_ALL_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01-A.03_SELECT_TITV_ALL.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TITV_BED
	}

	SELECT_TITV_KNOWN ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01-A.04_SELECT_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_TITV_KNOWN_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01-A.04_SELECT_TITV_KNOWN.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TITV_BED \
			$DBSNP_129
	}

	SELECT_TITV_NOVEL ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q $QUEUE_LIST \
			-p $PRIORITY \
		-N J.01-A.01-A.05_SELECT_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-SELECT_TITV_NOVEL_QC.log \
			-j y \
		-hold_jid J.01-A.01_FILTER_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT \
		$SCRIPT_DIR/J.01-A.01-A.05_SELECT_TITV_NOVEL.sh \
			$JAVA_1_8 \
			$GATK_DIR \
			$CORE_PATH \
			$PROJECT \
			$SM_TAG \
			$REF_GENOME \
			$TITV_BED \
			$DBSNP_129
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
				-p $PRIORITY \
			-N J.01-A.01-A.03-A.01_RUN_TITV_ALL_QC"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-RUN_TITV_ALL_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.03_SELECT_TITV_ALL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/J.01-A.01-A.03-A.01_RUN_TITV_ALL.sh \
				$SAMTOOLS_0118_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG
		}

		RUN_TITV_KNOWN ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N J.01-A.01-A.04-A.01_RUN_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-RUN_TITV_KNOWN_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.04_SELECT_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/J.01-A.01-A.04-A.01_RUN_TITV_KNOWN.sh \
				$SAMTOOLS_0118_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG
		}

		RUN_TITV_NOVEL ()
		{
			echo \
			qsub \
				-S /bin/bash \
				-cwd \
				-V \
				-q $QUEUE_LIST \
				-p $PRIORITY \
			-N J.01-A.01-A.05-A.01_RUN_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-RUN_TITV_NOVEL_QC.log \
				-j y \
			-hold_jid J.01-A.01-A.05_SELECT_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/J.01-A.01-A.05-A.01_RUN_TITV_NOVEL.sh \
				$SAMTOOLS_0118_DIR \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG
		}

QC_REPORT_PREP ()
{
echo \
qsub \
-S /bin/bash \
-cwd \
-V \
-q $QUEUE_LIST \
-p $PRIORITY \
-N X1"_"$SGE_SM_TAG \
-hold_jid J.01-A.01-A.05-A.01_RUN_TITV_NOVEL_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.01-A.01-A.04-A.01_RUN_TITV_KNOWN_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.01-A.01-A.03-A.01_RUN_TITV_ALL_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.03-A.01-A.02_TARGET_PASS_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.03-A.01-A.01_BAIT_PASS_MIXED_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.02-A.01-A.02_TARGET_PASS_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.02-A.01-A.01_BAIT_PASS_INDEL_QC"_"$SGE_SM_TAG"_"$PROJECT,\
J.01-A.01-A.02-A.01-A.01_SNV_TARGET_PASS_CONCORDANCE"_"$SGE_SM_TAG"_"$PROJECT,\
J.01-A.01-A.01_BAIT_PASS_SNV_QC"_"$SGE_SM_TAG"_"$PROJECT,\
H.03-DOC_CODING"_"$SGE_SM_TAG"_"$PROJECT,\
H.04-DOC_BAIT"_"$SGE_SM_TAG"_"$PROJECT,\
H.05-A.01_CHROM_DEPTH"_"$SGE_SM_TAG"_"$PROJECT,\
H.06-COLLECT_MULTIPLE_METRICS"_"$SGE_SM_TAG"_"$PROJECT,\
H.07-COLLECT_HS_METRICS"_"$SGE_SM_TAG"_"$PROJECT,\
H.08-A.01-RUN_VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT,\
H.09-A.01-A.01_CAT_VERIFYBAMID_CHR"_"$SGE_SM_TAG"_"$PROJECT \
-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG-QC_REPORT_PREP_QC.log \
$SCRIPT_DIR/X.01-QC_REPORT_PREP.sh \
$SAMTOOLS_DIR \
$DATAMASH_DIR \
$CORE_PATH \
$PROJECT \
$SM_TAG
}

for SM_TAG in $(awk 'BEGIN {FS=","} NR>1 {print $8}' $SAMPLE_SHEET | sort | uniq );
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
	LIFTOVER_TARGET_PASS_SNV
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

# Maybe I'll make this a function and throw it into a loop, but today is not that day.
# I think that i will have to make this a look to handle multiple projects...maybe not
# but again, today is not that day.

	awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","; OFS="\t"} NR>1 {print $1,$8}' \
		| awk 'BEGIN {OFS="\t"} {sub(/@/,"_",$2)} {print $1,$2}' \
		| sort -k 1,1 -k 2,2 \
		| uniq \
		| $DATAMASH_DIR/datamash -s -g 1 collapse 2 \
		| awk 'BEGIN {FS="\t"} \
			gsub (/,/,",X1_",$2) \
			{print "qsub",\
			"-S /bin/bash",\
			"-cwd",\
			"-V",\
			"-q","'$QUEUE_LIST'",\
			"-p","'$PRIORITY'",\
			"-m","e",\
			"-M","cidr_sequencing_notifications@lists.johnshopkins.edu",\
			"-N","X.01-X.01-END_PROJECT_TASKS_"$1,\
			"-o","'$CORE_PATH'/"$1"/LOGS/"$1".END_PROJECT_TASKS.log",\
			"-j y",\
			"-hold_jid","X1_"$2",A.02-LAB_PREP_METRICS_"$1, \
			"'$SCRIPT_DIR'""/X.01-X.01-END_PROJECT_TASKS.sh",\
			"'$CORE_PATH'","'$DATAMASH_DIR'",$1,"'$SAMPLE_SHEET'" "\n" "sleep 0.1s"}'

# EMAIL WHEN DONE SUBMITTING

# printf "$SAMPLE_SHEET\nhas finished submitting at\n`date`\n" \
# 	| mail -s "CIDR.WES.QC.SUBMITTER.GRCH38.sh submitted" \
# 		-r khetric1@jhmi.edu \
# 		cidr_sequencing_notifications@lists.johnshopkins.edu
