//
// Read QC, UMI extraction and trimming
//

include { FASTQC           } from '../../modules/nf-core/modules/fastqc/main'
include { TRIMGALORE       } from '../../modules/nf-core/modules/trimgalore/main'

//
// MODULE: Installed from local/modules
//

include { DEMULTIPLEX_FASTQ           } from '../../modules/local/demultiplex/main'


workflow PREP_SAMPLES {
    take:
    reads            // channel: [ val(meta), [ reads ] ]
    skip_fastqc      // boolean: true/false
    skip_trimming    // boolean: true/false
    skip_demultiplex // boolean: true/false

    main:

    ch_versions = Channel.empty()
    fastqc_html = Channel.empty()
    fastqc_zip  = Channel.empty()
    if (!skip_fastqc) {
        FASTQC ( reads ).html.set { fastqc_html }
        fastqc_zip  = FASTQC.out.zip
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }

    //
    // module: Demultiplex
    //

    counts      = Channel.empty()
    hiCounts    = Channel.empty()
    summ        = Channel.empty()
    if (!skip_demultiplex) {
        DEMULTIPLEX_FASTQ (reads)
    }
    demux_reads = DEMULTIPLEX_FASTQ.out.demultiplex_fastq
    ch_versions = ch_versions.mix(DEMULTIPLEX_FASTQ.out.versions.first())

    if (!skip_demultiplex) {
        trim_reads = reads
        }else{
        trim_reads = demux_reads
        }

    trim_html  = Channel.empty()
    trim_zip   = Channel.empty()
    trim_log   = Channel.empty()
    if (!skip_trimming) {
        TRIMGALORE ( trim_reads )
        trim_html   = TRIMGALORE.out.html
        trim_zip    = TRIMGALORE.out.zip
        trim_log    = TRIMGALORE.out.log
        ch_versions = ch_versions.mix(TRIMGALORE.out.versions.first())
    }

    emit:
    reads = trim_reads // channel: [ val(meta), [ reads ] ]

    fastqc_html        // channel: [ val(meta), [ html ] ]
    fastqc_zip         // channel: [ val(meta), [ zip ] ]

    counts             // channel: [ val(meta), [ txt ] ]
    hiCounts           // channel: [ val(meta), [ txt ] ]
    summ               // channel: [ val(meta), [ txt ] ]

    trim_html          // channel: [ val(meta), [ html ] ]
    trim_zip           // channel: [ val(meta), [ zip ] ]
    trim_log           // channel: [ val(meta), [ txt ] ]

    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}
