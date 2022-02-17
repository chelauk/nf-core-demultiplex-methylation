//
// Read QC, UMI extraction and trimming
//

include { FASTQC           } from '../../modules/nf-core/modules/fastqc/main'
include { TRIMGALORE       } from '../../modules/nf-core/modules/trimgalore/main'

//
// MODULE: Installed from local/modules
//

include { DEMULTIPLEX_FASTQ           } from '../../modules/local/demultiplex/main'

//
// functions to get demultiplexed ids
//

def create_fastq_channels_dem(row) {
    def meta = [:]
    meta.id           = row[0]
    meta.single_end   = false

    def array = []
    if (meta.single_end) {
        array = [ meta, [ row[1] ] ]
    } else {
        array = [ meta, [ row[1][0], row[1][1] ] ]
    }
    return array
}

def getSampleID( file ){
     // using RegEx to extract the SampleID
    regexpPE = /.+\/([\w_\-]+)_[12].fastq.[ATGC]{6}.fastq/
    (file =~ regexpPE)[0][1]
}
def getIndex( file ){
     // using RegEx to extract the SampleID
    regexpPE = /.+_[12].fastq.([ATGC]{6}).fastq/
    (file =~ regexpPE)[0][1]
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
        }

        demux_reads = demux_reads
                        .map { it -> [getSampleID(it) + "_" +  getIndex(it), it] }
                        .groupTuple(by:[0])
                        .map{ it -> create_fastq_channels_dem(it) }
                        .view()

    if (!skip_demultiplex) {
        trim_reads = demux_reads
        }else{
        trim_reads = reads
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
