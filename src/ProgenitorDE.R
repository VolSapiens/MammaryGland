# Figure 4

library(dplyr)
library(edgeR)
source("functions.R")

dataList <- readRDS("../data/Robjects/ExpressionList_QC_norm_clustered_clean.rds")
m <- dataList[[1]]
pD <- dataList[[2]]
fD <- dataList[[3]]

# Cells
m <- m[,pD$keep]
pD <- pD[pD$keep,]

comps <- c("Lp-NP","Lp-PI")
out <- list()

# DE for each progenitor cluster versus all other luminal cells
for (choice in comps) {
    # subset data
    rmClust <- setdiff(c("Lp-NP","Lp-PI"),choice)
    pD.sub <- filter(pD, !(SubCluster %in% c("Bsl-G1","Bsl","Myo","Prc",rmClust)))
    m.sub <- m[,as.character(pD.sub$barcode)]
    keep <- rowMeans(m.sub) > 0.01
    m.sub <- m.sub[keep,]
    fD.sub <- fD[keep,]
    rownames(m.sub) <- fD.sub$symbol

    # DGEList object 
    nf <- log(pD.sub$sf/pD.sub$UmiSums)
    pD.sub$nf <- exp(nf-mean(nf))
    y <- DGEList(counts=m.sub,
		 samples=pD.sub,
		 genes=fD.sub,
		 norm.factors=pD.sub$nf)


    # DE
    cluster <- factor(as.numeric(pD.sub$SubCluster==choice))
    de.design <- model.matrix(~cluster)
    y <- estimateDisp(y, de.design, prior.df=0,trend="none")
    fit <- glmFit(y, de.design)
    res <- glmTreat(fit,lfc=1)
    resTab <- topTags(res,n=Inf,sort.by="PValue")
    topTab <- resTab$table
    out[[choice]] <- topTab
}
tabNulPar <- out[["Lp-NP"]]
tabPar <- filter(out[["Lp-PI"]],symbol %in% tabNulPar$symbol)
rownames(tabNulPar) <- tabNulPar$symbol
tabNulPar <- tabNulPar[tabPar$symbol,]

progenitorDE <- data.frame("NullParFC"=tabNulPar$logFC,
		      "ParousFC"=tabPar$logFC,
		      "Gene"=tabPar$symbol)

write.csv(progenitorDE,file="../data/Robjects/ProgenitorDE.csv",
	  row.names=FALSE)

# ---- DEC4vsLp ----

# reload data
m <- dataList[[1]]
pD <- dataList[[2]]
fD <- dataList[[3]]

m <- m[,keepCells]
pD <- pD[keepCells,]

# DE C4 vs Lp

# subset data
pD.sub <- filter(pD, (cluster %in% c(4,5)))
m.sub <- m[,as.character(pD.sub$barcode)]
keep <- rowMeans(m.sub) > 0.1
m.sub <- m.sub[keep,]
fD.sub <- fD[keep,]
rownames(m.sub) <- fD.sub$symbol

# DGEList object
nf <- log(pD.sub$sf/pD.sub$UmiSums)
pD.sub$nf <- exp(nf-mean(nf))
y <- DGEList(counts=m.sub,
	     samples=pD.sub,
	     genes=fD.sub,
	     norm.factors=pD.sub$nf)


# DE
choice <- 4
cluster <- factor(as.numeric(pD.sub$cluster==choice))
de.design <- model.matrix(~cluster)
y <- estimateDisp(y, de.design, prior.df=0,trend="none")
fit <- glmFit(y, de.design)
res <- glmTreat(fit,lfc=1)
resTab <- topTags(res,n=Inf,sort.by="PValue")
topTab <- resTab$table

# Write DE table for supps
topTab <- select(topTab, id, symbol, logFC, unshrunk.logFC, logCPM, PValue, FDR)
write.csv(topTab,file="../data/Robjects/C4vsLpDE.csv", row.names=FALSE)
