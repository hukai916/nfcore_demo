# Setup a nf-core environment

## Step0: create new conda env: demo_nfcore
conda create --name demo_nfcore python=3.9 <br>
conda activate demo_nfcore

## Step1: install Nextflow:
conda install -c bioconda nextflow <br>
which nextflow <br>
(To upgrade, use "NXF_VER=20.08.0-edge nextflow self-update
".)

## Step2: install and upgrade nf-core to dev version
conda install -c bioconda nf-core=2.1 <br>
nf-core --version (2.1) <br>
(To upgrade, use "pip install --upgrade --force-reinstall git+https://github.com/nf-core/tools.git@dev", there seems a bug in nf-core versioning.) <br>

Note that the TEMPLATE is quickly evolving, you can use "nf-core sync" to sync to a specific TEMPLATE branch.

## Step3: initialize pipeline template
nf-core create <br>
-- Workflow Name: geotofastq <br>
-- Description: Given text file containing GEO ids, retrieve sample sheet, download fastq, and perform FastQC, cutadapt and finally generate a multiQC report. <br>
-- Auther: your name

cd /Users/kaihu/GitHub/demo_nfcore/nf-core-geotofastq
git remote add origin git@github.com:USERNAME/REPO_NAME.git
git push --all origin

## References:
1.  Install Nextflow:
https://anaconda.org/bioconda/nextflow
https://www.nextflow.io/docs/latest/getstarted.html

2.  Install nf-core:
https://nf-co.re/usage/installation
