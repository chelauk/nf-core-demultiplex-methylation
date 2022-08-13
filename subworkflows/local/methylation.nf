//
// Read QC, UMI extraction and trimming
//

include { BISMARK_ALIGN    }                      from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_METHYLATED }   from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_UNMETHYLATED } from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_METHYLATIONEXTRACTOR }          from '../../modules/nf-core/modules/bismark/methylationextractor/main'
include { BISMARK_CONVERSION }                    from '../../modules/local/bs_conversion/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS as CDSV }   from '../../modules/nf-core/modules/custom/dumpsoftwareversions/main'

workflow METHYLATION {
    take:
    reads                // channel: [ val(meta), [ reads ] ]
    bismark_refdir       // path: bismark reference
    methylated_control   // path: methylated control
    unmethylated_control // path: unmethylated control


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
    //
    // module: BISMARK ALIGN METHYLATED CONTROL
    //
    BISMARK_METHYLATED(reads,methylated_control)
    aligned = aligned.mix(BISMARK_METHYLATED.out.bam)
    aligned_report = aligned_report.mix(BISMARK_METHYLATED.out.report)
    //
    // module: BISMARK ALIGN UNMETHYLATED CONTROL
    //
    BISMARK_UNMETHYLATED(reads,unmethylated_control)
    aligned = aligned.mix(BISMARK_UNMETHYLATED.out.bam)
    aligned_report = aligned_report.mix(BISMARK_UNMETHYLATED.out.report)
    //
    // module: BISMARK METHYLATIONEXTRACTOR
    //

    BISMARK_METHYLATIONEXTRACTOR(aligned)
    chh_ob   = BISMARK_METHYLATIONEXTRACTOR.out.chh_ob
    chg_ob   = BISMARK_METHYLATIONEXTRACTOR.out.chg_ob
    cpg_ob   = BISMARK_METHYLATIONEXTRACTOR.out.cpg_ob
    mbias_ob = BISMARK_METHYLATIONEXTRACTOR.out.mbias_ob
    chh_ot   = BISMARK_METHYLATIONEXTRACTOR.out.chh_ot
    chg_ot   = BISMARK_METHYLATIONEXTRACTOR.out.chg_ot
    cpg_ot   = BISMARK_METHYLATIONEXTRACTOR.out.cpg_ot
    mbias_ot = BISMARK_METHYLATIONEXTRACTOR.out.mbias_ot

    //
    // module: BISULPHITE CONVERSION
    //
    BISMARK_CONVERSION (chh_ob,
                        chg_ob,
                        cpg_ob,
                        chh_ot,
                        chg_ot,
                        cpg_ot)

//    CDSV (ch_versions.unique().collectFile(name: 'collated_versions.yml'))

    emit:
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
    alignment_report = aligned_report.ifEmpty(null)
    chh_ob           = ch_chh_ob.ifEmpty(null)
    chg_ob           = ch_chg_ob.ifEmpty(null)
    cpg_ob           = ch_cpg_ob.ifEmpty(null)
    mbias_ob         = ch_mbias_ob.ifEmpty(null)
    chh_ot           = ch_chh_ot.ifEmpty(null)
    chg_ot           = ch_chg_ot.ifEmpty(null)
    cpg_ot           = ch_cpg_ot.ifEmpty(null)
    mbias_ot         = ch_mbias_ot.ifEmpty(null)
}
