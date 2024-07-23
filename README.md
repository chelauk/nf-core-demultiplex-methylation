# ![nf-core/demultiplex-methylation](docs/images/nf-core-demultiplex_logo_light.png#gh-light-mode-only) ![nf-core/demultiplex](docs/images/nf-core-demultiplex_logo_dark.png#gh-dark-mode-only)

[![GitHub Actions CI Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/demultiplex/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/demultiplex/actions?query=workflow%3A%22nf-core+linting%22)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/demultiplex/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.3-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23demultiplex-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/demultiplex)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/demultiplex-demultiplex** is a bioinformatics best-practice analysis pipeline to optionally demultiplex
fastq files run bismark against a human reference and pUC19 methylated and unmethylated controls.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

## Pipeline summary

This pipeline will process methylseq data including RRBS.

1. Demultiplex if necessary ([`Demultiplex`](https://github.com/GaitiLab/scRRBS_pipeline/blob/main/splitFastqPair.pl))
2. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
3. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))
4. Trim using RRBS specific flags with TrimGalore ([`Trim Galore`](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/))
5. Align to reference genome with BISMARK ([`bismark`](https://github.com/FelixKrueger/Bismark/))
6. Align to fully methylated control with BISMARK ([`bismark`](https://github.com/FelixKrueger/Bismark/))
7. Align to unmethylated control with BISMARK ([`bismark`](https://github.com/FelixKrueger/Bismark/))
8. Bismark methylation extractor ([`bismark`](https://github.com/FelixKrueger/Bismark/))
9. optional: filter Bismark methylation extractor output using a bed file
10. Bisulphite conversion assessment
11. Post alignment QC

## slurm specific instructions

1. Download the pipeline:

    ```console
    git clone https://github.com/chelauk/nf-core-demultiplex-methylation.git
    ```

2. Edit your .bashrc file to set the following variables:

   ```bash
   # Set all the Singularity cache dirs to Scratch
   export SINGULARITY_CACHEDIR=**/your/selected/scratch/folder/singularity_imgs**
   export SINGULARITY_TMPDIR=$SINGULARITY_CACHEDIR/tmp
   export SINGULARITY_LOCALCACHEDIR=$SINGULARITY_CACHEDIR/localcache
   export SINGULARITY_PULLFOLDER=$SINGULARITY_CACHEDIR/pull
   # match the NXF_SINGULARITY_CACHEDIR
   export NXF_SINGULARITY_CACHEDIR=**/your/selected/scratch/folder/singularity_imgs**
   ```

3. Start running your own analysis
   edit a sbatch script

    ```bash
    #!/bin/bash -l
    #SBATCH --job-name=demultiplex
    #SBATCH --output=nextflow_out.txt
    #SBATCH --partition=master-worker
    #SBATCH --ntasks=1
    #SBATCH --time=120:00:00

    nextflow run **/location/of/your/nextflow_pipelines/nf-core-demultiplex-methylation** \
    --input input.csv  \
    -profile slurm,singularity \
    -resume
    ```

4. Start your sbatch job:

   ```console
   sbatch runNextflow.sh
   ````

## Documentation

The nf-core/demultiplex pipeline comes with documentation about the pipeline [usage](https://github.com/chelauk/nf-core-demultiplex-methylation/blob/master/docs/usage.md) and [output](https://github.com/chelauk/nf-core-demultiplex-methylation/blob/master/docs/output.md).

## Credits

nf-core-demultiplex-methylation was originally written by Chela James

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
