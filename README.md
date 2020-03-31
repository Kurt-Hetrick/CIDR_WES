GRCh38 pipeline summary (up to cram files)
=======

bwa mem version, 0.7.15, was used to align fastq file to the reference genome with the following parameters; -K 100000000 -Y -t 4. Samblaster version, 0.1.24, was used to add mate tags with the following parameters; --addMateTags -a. AddOrReplaceReadGroups in picard version was used to perform queryname sorting and populate the CRAM RG headers with the following fields; ID, LB, PL, PU, PM, SM, CN, DT, PG, DS. MarkDuplicates in picard version, 2.17.0, was to mark duplicates on a queryname sorted bam file. sambamba version, 0.6.8, was used to sort the bam file to reference coordinates. Base quality score recalibration was performed by BaseRecalibrator in GATK version, 4.0.11.0, using; Homo_sapiens_assembly38.dbsnp138.vcf, Homo_sapiens_assembly38.known_indels.vcf.gz and Mills_and_1000G_gold_standard.indels.hg38.vcf.gz as known sites and limited to the sites present in the capture's bait bed file using the original base quality scores present in the bam file. Recalibrated base call quality scores were applied using ApplyBQSR in GATK version, 4.0.11.0, and binned to base call quality scores of 0-6,10,20 and 30. Original base call quality scores were retained in the OQ tag. Bam files were converted to cram files using samtools version 1.9.

DIFFERENCES BETWEEN GRCh37 AND GRCh38 PIPELINE.
=======

1. A.00_FIX_BED FILES
	* DIFF B/W B37 AND GRCH38 WITH CHR

2. C.01-A.01_FIX_BAM_HEADER.sh
	* only in grch37 pipeline. will be taken out.

3. D.01 PERFORM BQSR
	* DIFFERENT GATK VERSION (SHOULDN'T MATTER...can sync later) b/w 37 and 38
	* ...DIFFERENT INPUT B/C OF SAMBAMBA (can fix) in 37

4. H.01-A.01_HAPLOTYPE_CALLER_GVCF_GATHER.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

5. H.01-A.02_HAPLOTYPE_CALLER_BAM_GATHER.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

6. H.05-A.01_CHROM_DEPTH.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

7. H.08_SELECT_VERIFYBAMID_VCF.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

8. H.09_VERIFYBAMID_PER_CHR.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

9. H.09-A.01_CAT_VERIFYBAMID_CHR.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

10. I.01-A.01_GENOTYPE_GVCF_GATHER.sh
	* DIFF B/W B37 AND GRCH38 WITH CHR

11. J.01-A.01-A.02-A.01_SNV_TARGET_LIFTOVER_HG19.sh
	* grch38 only

12. J.01-A.01-A.02-A.01_SNV_TARGET_PASS_CONCORDANCE.sh vs J.01-A.01-A.02-A.01-A.01_SNV_TARGET_PASS_CONCORDANCE.sh
	* different b/c of liftover of grch38 back hg19
