# clone the repo at https://github.com/broadgsa/gatk
# this is to get b37 liftover chains

# grab the hg19 to hg38 liftover chain

wget https://github.com/broadgsa/gatk/blob/master/public/chainFiles/b37tohg19.chain

zcat hg19ToHg38.over.chain.gz > hg19ToHg38.over.chain

# fix verifybamid omni 2.5 vcf header

( grep "^##" /mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf ; echo '##INFO=<ID=AC,Number=A,Type=Integer,Description="Allele count in genotypes, for each ALT allele, in the same order as listed">' ; echo '##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">' ; grep "^#CHROM" /mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf ; grep -v "^#" /mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf ) >| /mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.fixed.header.vcf

# liftover from b37 to hg19

java -jar /mnt/research/tools/LINUX/PICARD/picard-2.17.0/picard.jar \
LiftoverVcf \
I=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.fixed.header.vcf \
O=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg19.liftover.vcf \
REJECT=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg19.liftover.reject.vcf \
R=/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/hg19/ucsc.hg19.fasta \
CHAIN=/mnt/shared_resources/public_resources/liftOver_chain/chainFiles_b37/b37tohg19.chain

# liftover from hg19 to hg38

java -jar /mnt/research/tools/LINUX/PICARD/picard-2.17.0/picard.jar \
LiftoverVcf \
I=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg19.liftover.vcf \
O=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg38.liftover.vcf \
REJECT=/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg38.liftover.reject.vcf \
R=/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/Homo_sapiens_assembly38.fasta \
CHAIN=/mnt/shared_resources/public_resources/liftOver_chain/hg19ToHg38.over.chain
