library(ampvis2)
otutable <- amp_import_usearch(otutab = "/home/kapper/Dropbox/AAU/PhD/Data/Amplicon data/[2019-02-06] Immigration/ASVtable.tsv", 
                               sintax = "/home/kapper/Dropbox/AAU/PhD/Data/Amplicon data/[2019-02-06] Immigration/ASVs.R1.sintax")
test <- amp_load(otutable)
tax_aggregate <- "Species"

#aggregate OTU's to the particular level
test$abund <- ampvis2:::aggregate_abund(abund = test$abund, 
                                        tax = test$tax, 
                                        format = "abund",
                                        tax_aggregate = tax_aggregate,
                                        calcSums = FALSE,
                                        tax_add = NULL #don't use tax_add
                                        )
#subset taxonomy accordingly
test$tax <- test$tax[test$tax[[tax_aggregate]] %in% rownames(test$abund),]

#Copy the taxa names of tax_aggregate to tax levels lower than tax_aggregate
test$tax[,(which(colnames(test$tax) %in% tax_aggregate)+1):ncol(test$tax)] <- test$tax[[tax_aggregate]]

#remove duplicates, previously because multiple OTU's/ASV's in each tax_aggregate level
test$tax <- unique(test$tax)
rownames(test$tax) <- test$tax[[tax_aggregate]]

#make sure the order is the same between $abund and $tax
test$tax <- test$tax[rownames(test$abund),]
