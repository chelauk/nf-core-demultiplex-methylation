//
// Read QC, UMI extraction and trimming
//

include { FASTQC           } from '../../modules/nf-core/fastqc/main'
include { TRIMGALORE       } from '../../modules/nf-core/trimgalore/main'

//
// MODULE: Installed from local/modules
//

include { DEMULTIPLEX_FASTQ           } from '../../modules/local/demultiplex/main'

//
// functions to get demultiplexed ids
//

def create_fastq_channels_dem(row) {
    def meta = [:]
    meta.id  = row[0]

    def array = []
        array = [ meta, [ file(row[1][0]), file(row[1][1]) ] ]
    return array
}

def get_sample_id ( file ){
     // using RegEx to extract the SampleID
    sample_regex = /.+\/([\w_\-]+)_[12].fastq.[ATGC]{6}.fastq/
    sample_id    = (file =~ sample_regex)[0][1]
    index_regex  = /.+_[12].fastq.([ATGC]{6}).fastq/
    index_id     = (file =~ index_regex)[-1][1]
    return sample_id + "_" + index_id
}

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

    counts   = Channel.empty()
    hiCounts = Channel.empty()
    summ     = Channel.empty()
    if (!skip_demultiplex) {
        DEMULTIPLEX_FASTQ (reads)
        demux_reads = DEMULTIPLEX_FASTQ.out.demultiplex_fastq
        counts      = DEMULTIPLEX_FASTQ.out.counts
        hiCounts    = DEMULTIPLEX_FASTQ.out.hiCounts
        summ        = DEMULTIPLEX_FASTQ.out.summ
        ch_versions = ch_versions.mix(DEMULTIPLEX_FASTQ.out.versions.first())
        demux_reads = demux_reads
            .flatMap()
            .map{ it -> [get_sample_id(it),it]}
            .groupTuple()
            .map{ it -> create_fastq_channels_dem(it) }
        }

    trim_html  = Channel.empty()
    trim_zip   = Channel.empty()
    trim_log   = Channel.empty()
    if (!skip_trimming && !skip_demultiplex) {
        TRIMGALORE ( demux_reads )
        trim_html     = TRIMGALORE.out.html
        trim_zip      = TRIMGALORE.out.zip
        trim_log      = TRIMGALORE.out.log
        prepped_reads = TRIMGALORE.out.reads
        ch_versions   = ch_versions.mix(TRIMGALORE.out.versions.first())
    }
    if (!skip_trimming && skip_demultiplex) {
        TRIMGALORE ( reads )
        trim_html   = TRIMGALORE.out.html
        trim_zip    = TRIMGALORE.out.zip
        trim_log    = TRIMGALORE.out.log
        prepped_reads = TRIMGALORE.out.reads
        ch_versions = ch_versions.mix(TRIMGALORE.out.versions.first())
    }

    if (skip_trimming && skip_demultiplex) {
        prepped_reads = reads
    }

    emit:
    reads = prepped_reads // channel: [ val(meta), [ reads ] ]

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
