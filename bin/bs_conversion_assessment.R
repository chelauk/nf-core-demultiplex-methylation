#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
# library ggplot2
library(ggplot2)

# Read in the table
CHH    = read.table(list.files('^CHH_OB_'), sep = '\t',
				 skip = 1, stringsAsFactors = FALSE )

CHG    = read.table(list.files('^CHG_OT_'), sep = '\t',
				 skip = 1, stringsAsFactors = FALSE )

CpG_OB = read.table(list.files('^CpG_OB_'), sep = '\t',
				 skip =1, stringsAsFactors = FALSE )
# Get sample id
sample = args[1]

# Calculate percentages
meth_percs = c(table(CHH$V5) / length(CHH$V5), table(CHG$V5) / length(CHG$V5))

# Add in global
summed.global = c(table(CHH$V5)["h"] + table(CHG$V5)["x"], table(CHH$V5)["H"] + table(CHG$V5)["X"])

# Calculate global percentages
global_percs = summed.global / sum(summed.global)

# Total CpG OB methylation
cpg_ob = table(CpG_OB$V5) / length(CpG_OB$V5)

# Bisulphite conversion statistics
bs.conversion = data.frame(Type = c("CHH", "CHH", "CHG", "CHG", "Total non-CpG", "Total non-CpG", "Total CpG", "Total CpG"),
                           Percentage = c(meth_percs["h"], meth_percs["H"], meth_percs["x"], 
                                          meth_percs["X"], global_percs["h"], global_percs["H"],
                                          cpg_ob["z"], cpg_ob["Z"]),
                           Methyl_status = rep(c("Unmethylated", "Methylated"), times = 4))

# Reorder
bs.conversion$Type = factor(bs.conversion$Type, levels = c("CHH", "CHG", "Total non-CpG", "Total CpG"))

# Plots for each methylation rate
bc = ggplot() + geom_bar(aes(y = Percentage, x = Type, fill = Methyl_status), 
                         data = bs.conversion,
                         stat = "identity") + ggtitle(paste0("Methylation Percentages of original bottom (OB) strands - ",sample))

# Create output file of the graph
pdf(paste0(sample,".pdf"))
bc
dev.off()
