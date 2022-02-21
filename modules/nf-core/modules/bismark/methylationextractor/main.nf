process BISMARK_METHYLATIONEXTRACTOR {
    errorStrategy 'ignore'
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::bismark=0.23.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bismark:0.23.0--0' :
        'quay.io/biocontainers/bismark:0.23.0--0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bedGraph.gz")          , emit: bedgraph
    tuple val(meta), path("*pe.txt")                , emit: methylation_calls
    tuple val(meta), path("*.cov.gz")               , emit: coverage
    tuple val(meta), path("*_splitting_report.txt") , emit: report
    tuple val(meta), path("*.M-bias.txt")           , emit: mbias
    tuple val(meta), path("*CHH_OB_*")              , emit: chh_ob
    tuple val(meta), path("*CHG_OB_*")              , emit: chg_ob
    tuple val(meta), path("*CpG_OB_*")              , emit: cpg_ob
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def seqtype  = meta.single_end ? '-s' : '-p'
    """
    bismark_methylation_extractor \\
        --bedGraph \\
        --no_overlap \\
        $bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bismark: \$(echo \$(bismark -v 2>&1) | sed 's/^.*Bismark Version: v//; s/Copyright.*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def seqtype  = meta.single_end ? '-s' : '-p'
    """
    touch ${meta.id}.bedGraph.gz
    touch ${meta.id}.pe.txt
    touch ${meta.id}.cov.gz
    touch ${meta.id}._splitting_report.txt
    touch ${meta.id}.M-bias.txt
    touch ${meta.id}.CHH_OB_txt
    touch ${meta.id}.CHG_OB_txt
    touch ${meta.id}.CpG_OB_txt
    touch versions.yml
    """
}
