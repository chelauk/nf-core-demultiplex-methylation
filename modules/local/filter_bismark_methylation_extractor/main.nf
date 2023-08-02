process FILTER_BISMARK_MX {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::bedtools:2.31.0--hf5e1c6e_2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.0--hf5e1c6e_2' :
        'quay.io/biocontainers-bedtools:2.31.0--hf5e1c6e_2' }"

    input:
    tuple val(meta), path(chh_ob)
    tuple val(meta), path(chg_ob)
    tuple val(meta), path(cpg_ob)
    tuple val(meta), path(chh_ot)
    tuple val(meta), path(chg_ot)
    tuple val(meta), path(cpg_ot)
    tuple val(meta), path(bedgraph)
    tuple val(meta), path(cov)
    path(target_bed)

    output:
    tuple val(meta), path("*filtered.bedGraph.gz")          , emit: bedgraph
    tuple val(meta), path("*filtered.bismark.cov.gz")               , emit: coverage
    tuple val(meta), path("CHH_OB_*filtered.txt")               , emit: chh_ob
    tuple val(meta), path("CHG_OB_*filtered.txt")               , emit: chg_ob
    tuple val(meta), path("CpG_OB_*filtered.txt")               , emit: cpg_ob
    tuple val(meta), path("CHH_OT_*filtered.txt")               , emit: chh_ot
    tuple val(meta), path("CHG_OT_*filtered.txt")               , emit: chg_ot
    tuple val(meta), path("CpG_OT_*filtered.txt")               , emit: cpg_ot
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for label in CHH_OB CHG_OB CpG_OB CHH_OT CHG_OT CpG_OT    
    do 
      mkfifo ${prefix}.\$label
      awk 'BEGIN{OFS="\t"}NR>1{print \$3,\$4,\$4,\$1,\$2,\$5}' "\$label"_${prefix}_pe.txt > ${prefix}.\$label &
      bedtools intersect -a ${prefix}.\$label -b $target_bed | awk '{OFS="\t"}{print \$4,\$5,\$1,\$2,\$6}'> tmp.\$label
      cat <( echo "Bismark methylation extractor version v0.23.0" ) tmp.\$label > "\$label"_${prefix}_pe_filtered.txt
      rm tmp.\$label
      rm ${prefix}.\$label
      cat <(echo "Bismark methylation extractor version v0.23.0") "\$label"_${prefix}_pe.txt > tmp && mv tmp "\$label"_${prefix}_pe_filtered.txt
    done

    mkfifo bedgraph_fifo
    zcat ${prefix}_pe.bedGraph.gz > bedgraph_fifo &
    bedtools intersect -a bedgraph_fifo -b $target_bed | bgzip > ${prefix}_pe_filtered.bedGraph.gz
    rm bedgraph_fifo
    
    mkfifo cov_fifo
    zcat ${prefix}_pe.bismark.cov.gz > cov_fifo &
    bedtools intersect -a cov_fifo -b $target_bed | bgzip > ${prefix}_pe_filtered.cov.gz
    rm cov_fifo
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(echo \$(bedtools --version 2>&1) | sed 's/bedools v//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for label in CHH_OB CHG_OB CpG_OB CHH_OT CHG_OT CpG_OT 
    do
      touch "\$label"_${prefix}_pe_filtered.txt
    done
    touch ${prefix}_pe_filtered.bedGraph.gz
    touch ${prefix}_pe_filtered.bismark.cov.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: 2.31.1
    END_VERSIONS
    """
}