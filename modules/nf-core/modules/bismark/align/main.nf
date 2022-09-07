process BISMARK_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::bismark=0.23.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bismark:0.23.0--0' :
        'quay.io/biocontainers/bismark:0.23.0--0' }"

    input:
    tuple val(meta), path(reads)
    path index

    output:
    tuple val(meta), path("*sorted.bam")       , emit: bam
    tuple val(meta), path("*sorted.bam.bai")   , emit: bai
    tuple val(meta), path("*report.txt"), emit: report
    tuple val(meta), path("*fq.gz")     , optional:true, emit: unmapped
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fastq      = meta.single_end ? reads : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    bismark \\
        --unmapped \\
        $fastq \\
        --basename ${prefix} \\
        --genome $index
    
    samtools sort ${prefix}.bam -o ${prefix}_sorted.bam
    samtools index ${prefix}_sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fastq      = meta.single_end ? reads : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    touch ${prefix}.bam
    touch ${prefix}.report.txt
    touch versions.yml
    """

}
