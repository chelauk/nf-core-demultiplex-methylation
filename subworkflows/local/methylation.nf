//
// Read QC, UMI extraction and trimming
//

include { BISMARK_ALIGN    }                      from '../../modules/nf-core/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_METHYLATED }   from '../../modules/nf-core/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_UNMETHYLATED } from '../../modules/nf-core/bismark/align/main'
include { SAMTOOLS_INDEX }                        from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as INDEX_METHYLATED }    from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as INDEX_UNMETHYLATED }  from '../../modules/nf-core/samtools/index/main'
include { BISMARK_METHYLATIONEXTRACTOR }          from '../../modules/nf-core/bismark/methylationextractor/main'
include { BISMARK_CONVERSION }                    from '../../modules/local/bs_conversion/main'
include { FILTER_BISMARK_MX }                     from '../../modules/local/filter_bismark_methylation_extractor/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS as CDSV }   from '../../modules/nf-core/custom/dumpsoftwareversions/main'


workflow METHYLATION {
    take:
    reads                // channel: [ val(meta), [ reads ] ]
    bismark_refdir       // path: bismark reference
    methylated_control   // path: methylated control
    unmethylated_control // path: unmethylated control
    target_bed           // path: target bed file or empty channel


    main:
    // versions for report
    ch_versions = Channel.empty()
    // open channel to put aligned outputs
    aligned        = Channel.empty()
    // channel for alignment reports
    aligned_report = Channel.empty()
    //
    // module: BISMARK ALIGN
    //
    BISMARK_ALIGN(reads,bismark_refdir)
    ch_versions = ch_versions.mix(BISMARK_ALIGN.out.versions.first())
    aligned = aligned.mix(BISMARK_ALIGN.out.bam)
    aligned_report = aligned_report.mix(BISMARK_ALIGN.out.report)
    ch_versions = ch_versions.mix(BISMARK_ALIGN.out.versions)

    SAMTOOLS_INDEX(BISMARK_ALIGN.out.bam)
    //
    // module: BISMARK ALIGN METHYLATED CONTROL
    //

    if (params.use_controls) {
        BISMARK_METHYLATED(reads,methylated_control)
        aligned = aligned.mix(BISMARK_METHYLATED.out.bam)
        aligned_report = aligned_report.mix(BISMARK_METHYLATED.out.report)
    }
    //
    // module: BISMARK ALIGN UNMETHYLATED CONTROL
    //
    if (params.use_controls) {
        BISMARK_UNMETHYLATED(reads,unmethylated_control)
        aligned = aligned.mix(BISMARK_UNMETHYLATED.out.bam)
        aligned_report = aligned_report.mix(BISMARK_UNMETHYLATED.out.report)
    }

    //
    // module: BISMARK METHYLATIONEXTRACTOR
    //

    BISMARK_METHYLATIONEXTRACTOR(aligned)
    chh_ob   = BISMARK_METHYLATIONEXTRACTOR.out.chh_ob
    chg_ob   = BISMARK_METHYLATIONEXTRACTOR.out.chg_ob
    cpg_ob   = BISMARK_METHYLATIONEXTRACTOR.out.cpg_ob
    mbias    = BISMARK_METHYLATIONEXTRACTOR.out.mbias
    chh_ot   = BISMARK_METHYLATIONEXTRACTOR.out.chh_ot
    chg_ot   = BISMARK_METHYLATIONEXTRACTOR.out.chg_ot
    cpg_ot   = BISMARK_METHYLATIONEXTRACTOR.out.cpg_ot
    bedgraph = BISMARK_METHYLATIONEXTRACTOR.out.bedgraph
    coverage = BISMARK_METHYLATIONEXTRACTOR.out.coverage

    //
    // module: BISULPHITE CONVERSION
    //

    if (params.target_bed) {
        FILTER_BISMARK_MX ( chh_ob,
                            chg_ob,
                            cpg_ob,
                            chh_ot,
                            chg_ot,
                            cpg_ot,
                            bedgraph,
                            coverage,
                            target_bed)

        chh_ob_f = FILTER_BISMARK_MX.out.chh_ob
        chg_ob_f = FILTER_BISMARK_MX.out.chg_ob
        cpg_ob_f = FILTER_BISMARK_MX.out.cpg_ob
        chh_ot_f = FILTER_BISMARK_MX.out.chh_ot
        chg_ot_f = FILTER_BISMARK_MX.out.chg_ot
        cpg_ot_f = FILTER_BISMARK_MX.out.cpg_ot

         BISMARK_CONVERSION(chh_ob_f,
                            chg_ob_f,
                            cpg_ob_f,
                            chh_ot_f,
                            chg_ot_f,
                            cpg_ot_f)
        } else {
            BISMARK_CONVERSION (chh_ob,
                                chg_ob,
                                cpg_ob,
                                chh_ot,
                                chg_ot,
                                cpg_ot)
        }


//    CDSV (ch_versions.unique().collectFile(name: 'collated_versions.yml'))

    emit:
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
    alignment_report = aligned_report.ifEmpty(null)
    chh_ob           = chh_ob.ifEmpty(null)
    chg_ob           = chg_ob.ifEmpty(null)
    cpg_ob           = cpg_ob.ifEmpty(null)
    mbias            = mbias.ifEmpty(null)
    chh_ot           = chh_ot.ifEmpty(null)
    chg_ot           = chg_ot.ifEmpty(null)
    cpg_ot           = cpg_ot.ifEmpty(null)
}
