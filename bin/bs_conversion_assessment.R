#!/usr/local/bin/Rscript --vanilla
args <- commandArgs(trailingOnly = TRUE)
library("ggplot2")

# Read in the table
CHH_OB <- read.table(list.files(pattern = "^CHH_OB_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CHH_OB$V5 = factor(CHH_OB$V5, levels = c("h", "H"))

CHG_OB <- read.table(list.files(pattern = "^CHG_OB_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CHG_OB$V5 = factor(CHG_OB$V5, levels = c("x", "X"))

CpG_OB <- read.table(list.files(pattern = "^CpG_OB_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CpG_OB$V5 = factor(CpG_OB$V5, levels = c("z", "Z"))

CHH_OT <- read.table(list.files(pattern = "^CHH_OT_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CHH_OT$V5 = factor(CHH_OT$V5, levels = c("h", "H"))

CHG_OT <- read.table(list.files(pattern = "^CHG_OT_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CHG_OT$V5 = factor(CHG_OT$V5, levels = c("x", "X"))

CpG_OT <- read.table(list.files(pattern = "^CpG_OT_"),
    sep = "\t",
    skip = 1, stringsAsFactors = FALSE
)
CpG_OT$V5 = factor(CpG_OT$V5, levels = c("z", "Z"))

# Get sample id
sample <- args[1]

# Calculate percentages
ob_meth_percs <- c(table(CHH_OB$V5) / length(CHH_OB$V5), table(CHG_OB$V5) / length(CHG_OB$V5))

ot_meth_percs <- c(table(CHH_OT$V5) / length(CHH_OT$V5), table(CHG_OT$V5) / length(CHG_OT$V5))

# Add in global
ob_summed.global <- c(table(CHH_OB$V5)["h"] + table(CHG_OB$V5)["x"], table(CHH_OB$V5)["H"] + table(CHG_OB$V5)["X"])

ot_summed.global <- c(table(CHH_OT$V5)["h"] + table(CHG_OT$V5)["x"], table(CHH_OT$V5)["H"] + table(CHG_OT$V5)["X"])

# Calculate global percentages
ob_global_percs <- ob_summed.global / sum(ob_summed.global)

ot_global_percs <- ot_summed.global / sum(ot_summed.global)

# Total CpG OB methylation
cpg_ob <- table(CpG_OB$V5) / length(CpG_OB$V5)

# Total CpG OT methylation
cpg_ot <- table(CpG_OT$V5) / length(CpG_OT$V5)

# ob Bisulphite conversion statistics
ob_bs.conversion <- data.frame(
    Type = c("CHH", "CHH", "CHG", "CHG", "Total non-CpG", "Total non-CpG", "Total CpG", "Total CpG"),
    Percentage = c(
        ob_meth_percs["h"], ob_meth_percs["H"], ob_meth_percs["x"],
        ob_meth_percs["X"], ob_global_percs["h"], ob_global_percs["H"],
        cpg_ob["z"], cpg_ob["Z"]
    ),
    Methyl_status = rep(c("Unmethylated", "Methylated"), times = 4)
)

# ot Bisulphite conversion statistics
ot_bs.conversion <- data.frame(
    Type = c("CHH", "CHH", "CHG", "CHG", "Total non-CpG", "Total non-CpG", "Total CpG", "Total CpG"),
    Percentage = c(
        ot_meth_percs["h"], ot_meth_percs["H"], ot_meth_percs["x"],
        ot_meth_percs["X"], ot_global_percs["h"], ot_global_percs["H"],
        cpg_ot["z"], cpg_ot["Z"]
    ),
    Methyl_status = rep(c("Unmethylated", "Methylated"), times = 4)
)

# Reorder
ob_bs.conversion$Type <- factor(ob_bs.conversion$Type, levels = c("CHH", "CHG", "Total non-CpG", "Total CpG"))

ot_bs.conversion$Type <- factor(ob_bs.conversion$Type, levels = c("CHH", "CHG", "Total non-CpG", "Total CpG"))

# Plots for each methylation rate
ob_bc <- ggplot() +
    geom_bar(aes(y = Percentage, x = Type, fill = Methyl_status),
             data = ob_bs.conversion,
             stat = "identity"
    ) +
    scale_y_continuous(breaks = c(0,0.5,1), name = "Fraction") +
    annotate("text", c(1, 2, 3, 4), 1.1, label = paste0("n=",c(nrow(CHH_OB), nrow(CHG_OB), sum(ob_summed.global), nrow(CpG_OB)))) +
    ggtitle(paste0("Methylation Fraction of original bottom (OB) strands - ", sample))

ot_bc <- ggplot() +
    geom_bar(aes(y = Percentage, x = Type, fill = Methyl_status),
        data = ot_bs.conversion,
        stat = "identity"
    ) +
    scale_y_continuous(breaks = c(0,0.5,1), name = "Fraction") +
    annotate("text", c(1, 2, 3, 4), 1.1, label = paste0("n=",c(nrow(CHH_OT), nrow(CHG_OT), sum(ot_summed.global), nrow(CpG_OT)))) +
    ggtitle(paste0("Methylation Fraction of original top (OT) strands - ", sample))

# Calculate percentages
all_meth_percs <- c((table(CHH_OB$V5) + table(CHH_OT$V5)) / (length(CHH_OB$V5) + length(CHH_OT$V5)), 
                    (table(CHG_OB$V5) + table(CHG_OT$V5)) / (length(CHG_OB$V5) + length(CHG_OT$V5)))
# Add in global
all_summed.global <- c(table(CHH_OB$V5)["h"] + table(CHG_OB$V5)["x"] + table(CHH_OT$V5)["h"] + table(CHG_OT$V5)["x"], 
                       table(CHH_OB$V5)["H"] + table(CHG_OB$V5)["X"] + table(CHH_OT$V5)["H"] + table(CHG_OT$V5)["X"])

# Calculate global percentages
all_global_percs <- all_summed.global / sum(all_summed.global)

# Total CpG OB methylation
cpg_all <- (table(CpG_OB$V5) + table(CpG_OT$V5)) / (length(CpG_OB$V5) + length(CpG_OT$V5))

# ob Bisulphite conversion statistics
all_bs.conversion <- data.frame(
    Type = c("CHH", "CHH", "CHG", "CHG", "Total non-CpG", "Total non-CpG", "Total CpG", "Total CpG"),
    Percentage = c(
        all_meth_percs["h"], all_meth_percs["H"], all_meth_percs["x"],
        all_meth_percs["X"], all_global_percs["h"], all_global_percs["H"],
        cpg_all["z"], cpg_all["Z"]
    ),
    Methyl_status = rep(c("Unmethylated", "Methylated"), times = 4)
)

# Reorder
all_bs.conversion$Type <- factor(all_bs.conversion$Type, levels = c("CHH", "CHG", "Total non-CpG", "Total CpG"))

# Plots for each methylation rate
all_bc <- ggplot() +
    geom_bar(aes(y = Percentage, x = Type, fill = Methyl_status),
             data = all_bs.conversion,
             stat = "identity"
    ) +
    scale_y_continuous(breaks = c(0,0.5,1), name = "Fraction") +
    annotate("text", c(1, 2, 3, 4), 1.1, label = paste0("n=",c((nrow(CHH_OB) + nrow(CHH_OT)), 
                                                               (nrow(CHG_OB) + nrow(CHG_OT)), 
                                                               sum(all_summed.global), 
                                                               (nrow(CpG_OB) + nrow(CpG_OT))))) +
    ggtitle(paste0("Methylation Fraction of both strands - ", sample))

# Create output file of the graph
pdf(paste0(sample, "_ob.pdf"))
ob_bc
pdf(paste0(sample, "_ot.pdf"))
ot_bc
dev.off()
pdf(paste0(sample, "_both.pdf"))
all_bc
dev.off()