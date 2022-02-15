//
// Read QC, UMI extraction and trimming
//

include { BISMARK_ALIGN    }                      from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_METHYLATED }   from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_ALIGN as BISMARK_UNMETHYLATED } from '../../modules/nf-core/modules/bismark/align/main'
include { BISMARK_METHYLATIONEXTRACTOR }          from '../../modules/nf-core/modules/bismark/methylationextractor/main'
include { BISMARK_CONVERSION }                    from '../../modules/local/bs_conversion/main'

workflow METHYLATION {
    take:
    reads                // channel: [ val(meta), [ reads ] ]
    bismark_refdir       // path: bismark reference
    methylated_control   // path: methylated control
    unmethylated_control // path: unmethylated control


    main:
    ch_versions = Channel.empty()
    // open channel to put aligned outputs
    aligned  = Channel.empty()
    //
    // module: BISMARK ALIGN
    //
    BISMARK_ALIGN(reads,bismark_refdir)
    aligned = aligned.mix(BISMARK_ALIGN.out.bam)
    //
    // module: BISMARK ALIGN METHYLATED CONTROL
    //
    BISMARK_METHYLATED(reads,methylated_control)
    aligned = aligned.mix(BISMARK_METHYLATED.out.bam)
    //
    // module: BISMARK ALIGN UNMETHYLATED CONTROL
    //
    BISMARK_UNMETHYLATED(reads,unmethylated_control)
    aligned = aligned.mix(BISMARK_UNMETHYLATED.out.bam)
    //
    // module: BISMARK METHYLATIONEXTRACTOR
    //
    BISMARK_METHYLATIONEXTRACTOR(aligned)
    //
    // module: BISULPHITE CONVERSION
    //
    BISMARK_CONVERSION (BISMARK_METHYLATIONEXTRACTOR.out.chh_ob,
                        BISMARK_METHYLATIONEXTRACTOR.out.chg_ob,
                        BISMARK_METHYLATIONEXTRACTOR.out.cpg_ob)

    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}
