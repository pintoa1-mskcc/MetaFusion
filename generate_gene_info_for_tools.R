# __author__      = "Alexandria Dymun"
# __email__       = "pintoa1@mskcc.org"
# __contributor__ = "Anne Marie Noronha (noronhaa@mskcc.org)"
# __version__     = "0.0.1"
# __status__      = "Dev"


library(dplyr)
library(stringr)
### primary gtf is v75, also used in arriba
primary_gtf <-  as.data.frame(rtracklayer::import("/work/taylorlab/cmopipeline/mskcc-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Annotation/Genes/genes.gtf"))

### Fusion catcher has custom gene names/gene_ids....
## https://github.com/ndaniel/fusioncatcher/blob/ebc46fd1a8046fc909a56e09944a2ec2d69cc808/bin/add_custom_gene.py#L704-L715
fc_custom_bed_gene_names <- read.table("/work/taylorlab/cmopipeline/forte/GRCh37/fusioncatcher/fusioncatcher_human_v102/custom_genes.bed")
fc_custom_bed_gene_names$gene_name <- str_split_fixed(fc_custom_bed_gene_names$V4,"-",n=2)[,1]
fc_custom_bed_gene_names$gene_id <- str_split_fixed(fc_custom_bed_gene_names$V4,"-",n=3)[,2]
star_fusion_ref <- as.data.frame(rtracklayer::import("/work/taylorlab/cmopipeline/rnaseq_reference/GRCh37/starfusion/ctat_genome_lib_build_dir/ref_annot.gtf"))
fusioncatcher_ref <- as.data.frame(rtracklayer::import("/work/taylorlab/cmopipeline/rnaseq_reference/GRCh37/fusioncatcher/organism.gtf"))


all_my_gene_ids_and_names <- list(primary_gtf,fc_custom_bed_gene_names,star_fusion_ref,fusioncatcher_ref)
### whichever gtf you label as primary should also be the same version of the gene_bed file generated for metafusion
names(all_my_gene_ids_and_names) <- c("primary","one","two","three")
unique_id_to_names <- lapply( all_my_gene_ids_and_names,function(gtf) {
  ### If gene id has versions, strip them off 
  if(all(grepl("\\.",gtf$gene_id))){
    gtf$gene_id_with_version <- gtf$gene_id
    gtf$gene_id <- str_split_fixed(gtf$gene_id_with_version,"\\.",n=2)[,1]
    return(unique(gtf[,c("gene_name","gene_id","gene_id_with_version")]))
    
  } else{
   return(unique(gtf[,c("gene_name","gene_id")]))
  }
  })


gene_info <- unique_id_to_names$primary
### tack on missing gene_ids from other references to gene info
versioned_gtf <-unlist(sapply(names(unique_id_to_names)[names(unique_id_to_names) != "primary"],function(name){
  if(any(colnames(unique_id_to_names[[name]]) == "gene_id_with_version")){
    return(name)
  }
}))


add_these_exess_gene_ids <- do.call(rbind,lapply(names(unique_id_to_names)[names(unique_id_to_names) != "primary"],function(name){
  add_symbols_and_ids <- unique_id_to_names[[name]]
  add_symbols_and_ids <- add_symbols_and_ids[!add_symbols_and_ids$gene_id %in% gene_info$gene_id,]
  if(name %in% versioned_gtf){
    add_symbols_and_ids <-add_symbols_and_ids[,c("gene_name","gene_id_with_version")]
    colnames(add_symbols_and_ids) <- c("gene_name","gene_id")
  }
  return(add_symbols_and_ids)

}))
# Excess genes being added (genes will be flagged as gene not in v75)
gene_info <- rbind(gene_info,add_these_exess_gene_ids)

gene_info <- merge(gene_info,do.call(rbind,unique_id_to_names[versioned_gtf])[,c("gene_id","gene_id_with_version")],by = "gene_id",all.x = T, all.y = F)
table(is.na(gene_info$gene_id_with_version))
# 
# FALSE  TRUE 
# 63232  8780 
gene_info$Synonyms <- ifelse(is.na(gene_info$gene_id_with_version),gene_info$gene_id,paste0(gene_info$gene_id,"|",gene_info$gene_id_with_version))
gene_info$Symbol <- gene_info$gene_name

gene_info <- gene_info[,c("Symbol","Synonyms")]

write.table(gene_info,"/work/ccs/pintoa1/metafusion_refs/meta_fusion_bed_generation/gene_info_20230714.txt",sep ="\t",quote = F,row.names = F)
write.table(add_these_exess_gene_ids,"/work/ccs/pintoa1/metafusion_refs/meta_fusion_bed_generation/excess_gene_ids_20230714.txt",sep ="\t",quote = F,row.names = F)
