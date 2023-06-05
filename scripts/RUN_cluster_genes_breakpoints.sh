#!/bin/bash
#module load R/3.5.1
#module load python/2.7.11
cff=$1
outdir=$2


#Generate intersections file for both gene name and breakpoint
fid_intersection_file=$outdir/FID.intersections.tsv
python intersect_breakpoints_and_gene_names.py $cff > $fid_intersection_file

# Graph clustering
fid_clusters_file=$outdir/FID.clusters.tsv
#ls -l $fid_intersection_file
#ls -l $fusiontools_dir/cluster_intersections.local.R
Rscript cluster_intersections.R $fid_intersection_file $fid_clusters_file

# generate cluster file using clustered FIDs and cff file
python generate_cluster_file.py $cff $fid_clusters_file
