/*
================================================================================
                                BUILDING INDEXES
================================================================================
*/

// And then initialize channels based on params or indexes that were just built

include { BUILD_INTERVALS } from '../local/build_intervals.nf'
include { BWAMEM2_INDEX } from '../nf-core/bwamem2_index.nf'
include { GATK_CREATE_SEQUENCE_DICTIONARY } from '../local/gatk_dict.nf'
include {
    HTSLIB_TABIX as HTSLIB_TABIX_DBSNP;
    HTSLIB_TABIX as HTSLIB_TABIX_GERMLINE_RESOURCE;
    HTSLIB_TABIX as HTSLIB_TABIX_KNOWN_INDELS;
    HTSLIB_TABIX as HTSLIB_TABIX_PON;
} from '../nf-core/htslib_tabix'
include { SAMTOOLS_FAIDX } from '../nf-core/samtools_faidx.nf'

workflow BUILD_INDICES{
    take:
        dbsnp
        fasta
        germline_resource
        known_indels
        pon
        step

    main:

    if (!(params.bwa) && params.fasta && 'mapping' in step)
        result_bwa = BWAMEM2_INDEX(fasta)
    else
        result_bwa = Channel.empty()

    if (!(params.dict) && params.fasta && !('annotate' in step) && !('controlfreec' in step))
        result_dict = GATK_CREATE_SEQUENCE_DICTIONARY(fasta)
    else
        result_dict = Channel.empty()

    if (!(params.fasta_fai) && params.fasta && !('annotate' in step))
        result_fai = SAMTOOLS_FAIDX(fasta)
    else
        result_fai = Channel.empty()

    if (!(params.dbsnp_index) && params.dbsnp && ('mapping' in step || 'preparerecalibration' in step || 'controlfreec' in tools || 'haplotypecaller' in tools || 'mutect2' in tools || 'tnscope' in tools))
        result_dbsnp_tbi = HTSLIB_TABIX_DBSNP(dbsnp)
    else
        result_dbsnp_tbi = Channel.empty()

    if (!(params.germline_resource_index) && params.germline_resource && 'mutect2' in tools)
        result_germline_resource_tbi = HTSLIB_TABIX_GERMLINE_RESOURCE(germline_resource)
    else
        result_germline_resource_tbi = Channel.empty()

    if (!(params.known_indels_index) && params.known_indels && ('mapping' in step || 'preparerecalibration' in step))
        result_known_indels_tbi = HTSLIB_TABIX_KNOWN_INDELS(known_indels)
    else
        result_known_indels_tbi = Channel.empty()

    if (!(params.pon_index) && params.pon && ('tnscope' in tools || 'mutect2' in tools))
        result_pon_tbi = HTSLIB_TABIX_PON(pon)
    else
        result_pon_tbi = Channel.empty()

    if (!(params.intervals) && !('annotate' in step) && !('controlfreec' in step))
        result_intervals = BUILD_INTERVALS(SAMTOOLS_FAIDX.out)
    else
        result_intervals = Channel.empty()

    emit:
        bwa                   = result_bwa
        dbsnp_tbi             = result_dbsnp_tbi
        dict                  = result_dict
        fai                   = result_fai
        germline_resource_tbi = result_germline_resource_tbi
        intervals             = result_intervals
        known_indels_tbi      = result_known_indels_tbi
        pon_tbi               = result_pon_tbi
}