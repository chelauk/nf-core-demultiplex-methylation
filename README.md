# ![nf-core/demultiplex](docs/images/nf-core-demultiplex_logo.png)

**demultiplex and bismark for rachel**.

[![GitHub Actions CI Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/demultiplex/actions)
[![GitHub Actions Linting Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/demultiplex/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/demultiplex.svg)](https://hub.docker.com/r/nfcore/demultiplex)

## Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

i. Install [`nextflow`](https://nf-co.re/usage/installation)

ii. git clone  the pipeline 

```bash
git clone https://github.com/chelauk/nf-core-demultiplex/
```

i. Start running your own analysis!

```bash
nextflow run nf-core-demultiplex --reads '*R{1,2}.fastq.gz' -profile icr_davros,singularity -c local.config -r resume -with-tower
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The nf-core/demultiplex pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

The pipeline demultiplexes fastq.gz files, runs bismark and bis

## Credits

nf-core/demultiplex was originally written by chela.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on [Slack](https://nfcore.slack.com/channels/demultiplex) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citation

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nf-core/demultiplex for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).  
> ReadCube: [Full Access Link](https://rdcu.be/b1GjZ)
