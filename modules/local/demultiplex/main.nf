process DEMULTIPLEX_FASTQ {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::perl=5.26.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(reads)

    output:
    path("*{[ATGC],[ATGC],[ATGC],[ATGC],[ATGC],[ATGC]}.fastq"), emit: demultiplex_fastq
    tuple val(meta), path("*counts"),   optional:true, emit: counts
    tuple val(meta), path("*hiCounts"), optional:true, emit: hiCounts
    tuple val(meta), path("*summ"),     optional:true, emit: summ
    path  "versions.yml",               optional:true, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Add soft-links to original FastQs for consistent naming in pipeline
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    [ ! -f  ${prefix}_1.fastq.gz ] && ln -s ${reads[0]} ${prefix}_1.fastq.gz
    [ ! -f  ${prefix}_2.fastq.gz ] && ln -s ${reads[1]} ${prefix}_2.fastq.gz
    gunzip ${prefix}_1.fastq.gz
    gunzip ${prefix}_2.fastq.gz
    splitFastqPair.pl ${prefix}_1.fastq ${prefix}_2.fastq
    """

    stub:
    def args = task.ext.args ?: ''
    // Add soft-links to original FastQs for consistent naming in pipeline
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    [ ! -f  ${prefix}_1.fastq.gz ] && ln -s ${reads[0]} ${prefix}_1.fastq.gz
    [ ! -f  ${prefix}_2.fastq.gz ] && ln -s ${reads[1]} ${prefix}_2.fastq.gz
    touch ${prefix}_1.AGCTAT.fastq
    touch ${prefix}_2.AGCTAT.fastq
    touch ${prefix}_2.AGCTAT.counts
    touch ${prefix}_2.AGCTAT.hiCounts
    touch ${prefix}_2.AGCTAT.summ
    echo "Version 1" > versions.yml
    """
}
