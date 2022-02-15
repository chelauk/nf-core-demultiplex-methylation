process BISMARK_CONVERSION {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::bismark=0.23.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bismark:0.23.0--0' :
        'quay.io/biocontainers/bismark:0.23.0--0' }"

    input:
    tuple val(meta), path(chh_ob)
    tuple val(meta), path(chg_ob)
    tuple val(meta), path(cpg_ob)

    output:
    tuple val(meta), path("*pdf")             , emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fastq      = meta.single_end ? reads : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    bs_conversion_assessment.R ${sample_id}-${index}
    """
    stub:
    """
    touch report.pdf
    """
}
