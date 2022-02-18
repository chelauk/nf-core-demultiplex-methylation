process BISMARK_CONVERSION {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "r::tidverse=1.2.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-tidyverse:1.2.1' :
        'quay.io/biocontainers/r-tidyverse:1.2.1' }"

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
    """
    bs_conversion_assessment.R ${prefix}
    """
    stub:
    """
    touch report.pdf
    """
}
