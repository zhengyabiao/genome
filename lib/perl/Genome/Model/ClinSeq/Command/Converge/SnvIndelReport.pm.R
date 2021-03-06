#!/usr/bin/env Rscript
#Written by Malachi Griffith

args = (commandArgs(TRUE))
case_name = args[1]
infile = args[2]
sample_names_string = args[3]
combined_vaf_cols_string = args[4]
target_name = args[5]
outdir = args[6]
sample_types_string = args[7]
timepoint_names_string = args[8]
timepoint_positions_string = args[9]
sample1_vaf_cols_string = args[10]
sample2_vaf_cols_string = args[11]
sample3_vaf_cols_string = args[12]
sample4_vaf_cols_string = args[13]

sample_names = strsplit(sample_names_string, " ")[[1]]
sample_types = strsplit(sample_types_string, " ")[[1]]
timepoint_names = strsplit(timepoint_names_string, " ")[[1]]
timepoint_positions = as.numeric(strsplit(timepoint_positions_string, " ")[[1]])
combined_vaf_cols = as.numeric(strsplit(combined_vaf_cols_string, " ")[[1]])

sample1_vaf_cols = NULL
sample2_vaf_cols = NULL
sample3_vaf_cols = NULL
sample4_vaf_cols = NULL
if(!is.na(sample1_vaf_cols_string)){ sample1_vaf_cols = as.numeric(strsplit(sample1_vaf_cols_string, " ")[[1]]) }
if(!is.na(sample2_vaf_cols_string)){ sample2_vaf_cols = as.numeric(strsplit(sample2_vaf_cols_string, " ")[[1]]) }
if(!is.na(sample3_vaf_cols_string)){ sample3_vaf_cols = as.numeric(strsplit(sample3_vaf_cols_string, " ")[[1]]) }
if(!is.na(sample4_vaf_cols_string)){ sample4_vaf_cols = as.numeric(strsplit(sample4_vaf_cols_string, " ")[[1]]) }

#Define input variables
#infile="/path_to_snv_indel_report_results/H_KA-174556_final_filtered_coding_clean.tsv"
#sample_names = c("normal", "day0_tumor", "day30_tumor")
#combined_vaf_cols = c(19,22,25)
#target_name="AML_RMG"
#outdir="/path_to_store_summarized_results/H_KA-174556/"
#sample1_vaf_cols = c(34,37,40)
#sample2_vaf_cols = c(43,46,49)
#sample3_vaf_cols = c(52,55,58)
#sample4_vaf_cols = c(61,64,67)

if (length(args) < 7){
  message_text1 = "Required arguments missing: ./SnvIndelReport.pm.R ..."
  stop(message_text1)
}

#Define sample display colors
sample_colors = c("light blue")
if (length(sample_names) == 2) {sample_colors = c("light blue","red")}
if (length(sample_names) == 3) {sample_colors = c("light blue","red","orange")}
if (length(sample_names) == 4) {sample_colors = c("light blue","red4","red","orange")}

#There must be at least 1 set of sample VAFs
sample_vaf_cols = sample1_vaf_cols
if (length(sample2_vaf_cols) > 0) {sample_vaf_cols = c(sample_vaf_cols,sample2_vaf_cols)}
if (length(sample3_vaf_cols) > 0) {sample_vaf_cols = c(sample_vaf_cols,sample3_vaf_cols)}
if (length(sample4_vaf_cols) > 0) {sample_vaf_cols = c(sample_vaf_cols,sample4_vaf_cols)}


#Load in raw data
data = read.table(infile, header=TRUE, as.is = 1:16, sep="\t")

#Create a function to plot VAFs from replicates
plot_vafs = function(file, x_label, main_label_vafs, main_label_covs, gene_i){  
  gene_count = length(gene_i)
  pdf(file, width=8.5, height=11)
  layout(c(1,2), widths = c(1,1), heights=c(0.3,0.7))


  #Adjust point sizes and gene labels if there are too many genes
  point_cex=1
  names_cex=1
  if (gene_count >= 35){
    fraction1 = gene_count/35
    point_cex = point_cex/fraction1
  }
  if (gene_count >= 45){
    fraction2 = gene_count/45
    names_cex = point_cex/fraction2
  }

  if (point_cex < 0.1){
    point_cex = 0.1
  }

  #PANEL 1 - REPLICATE COVERAGE VALUES
  par(mar=c(1,6,4,2)) #c(bottom, left, top, right)
  par(mgp=c(5,1,0)) #axis title, axis labels and axis line.
  par(font.lab=2)
  covs = data[gene_i,(sample_vaf_cols-2)] + data[gene_i,(sample_vaf_cols-1)]
  y_max = max(covs) + 20

  y_label = "Coverage"
  boxplot(t(data[gene_i,34]), names=data[gene_i,"default_gene_name"], ylim=c(0,y_max), border="white", color="white", xlab=NA, ylab=y_label, main=main_label_covs, las=2, xaxt="n")
  xp = 0
  for (i in gene_i){
    xp = xp+1
    flank = 0.125
   
    #Only display individual replicates if there not too many genes
    if (gene_count <= 25){
      if (length(sample1_vaf_cols) > 0){
        xpoints = runif(n=length(sample1_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample1_vaf_cols-2]+data[i,sample1_vaf_cols-1], col=sample_colors[1], pch=16, cex=point_cex)
      }

      if (length(sample2_vaf_cols) > 0){
        xpoints = runif(n=length(sample2_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample2_vaf_cols-2]+data[i,sample2_vaf_cols-1], col=sample_colors[2], pch=16, cex=point_cex)
      }

      if (length(sample3_vaf_cols) > 0){
        xpoints = runif(n=length(sample3_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample3_vaf_cols-2]+data[i,sample3_vaf_cols-1], col=sample_colors[3], pch=16, cex=point_cex)
      }

      if (length(sample4_vaf_cols) > 0){
        xpoints = runif(n=length(sample4_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample4_vaf_cols-2]+data[i,sample4_vaf_cols-1], col=sample_colors[4], pch=16, cex=point_cex)
      }

    }else{
      if (length(sample1_vaf_cols) > 0){ points(x=xp, y=data[i,(combined_vaf_cols[1])-2]+data[i,(combined_vaf_cols[1])-1], col=sample_colors[1], pch=16, cex=point_cex) }
      if (length(sample2_vaf_cols) > 0){ points(x=xp, y=data[i,(combined_vaf_cols[2])-2]+data[i,(combined_vaf_cols[2])-1], col=sample_colors[2], pch=16, cex=point_cex) }
      if (length(sample3_vaf_cols) > 0){ points(x=xp, y=data[i,(combined_vaf_cols[3])-2]+data[i,(combined_vaf_cols[3])-1], col=sample_colors[3], pch=16, cex=point_cex) }
      if (length(sample4_vaf_cols) > 0){ points(x=xp, y=data[i,(combined_vaf_cols[4])-2]+data[i,(combined_vaf_cols[4])-1], col=sample_colors[4], pch=16, cex=point_cex) }
    }
  }



  #PANEL 2 - REPLICATE VAF VALUES
  par(mar=c(6,6,4,2)) #c(bottom, left, top, right)
  par(mgp=c(5,1,0)) #axis title, axis labels and axis line.
  par(font.lab=2)

  #Find the max value observed and use that to limit the y-axis
  y_max = max(data[gene_i,sample_vaf_cols]) + 20
  round(y_max, digits = -1)  
  if (y_max > 100){
    y_max = 100
  }
  if (y_max < 25){
    y_max = 25
  }

  n = length(gene_i)
  y_label = paste("Variant allele frequency (VAF) [n = ", n, "]", sep="")
  boxplot(t(data[gene_i,34]), names=data[gene_i,"default_gene_name"], ylim=c(0,y_max), border="white", color="white", xlab=x_label, ylab=y_label, main=main_label_vafs, las=2, xaxt="n")

  #Drop the gene labels entirely if there are too many genes
  if (gene_count < 50){
    axis(1, cex.axis=names_cex, labels=data[gene_i,"default_gene_name"], las=2, at=1:length(gene_i))
  }

  xp = 0
  for (i in gene_i){
    xp = xp+1
    flank = 0.125
   
    #Only display individual replicates if there not too many genes
    if (gene_count <= 25){
      if (length(sample1_vaf_cols) > 0){
        xpoints = runif(n=length(sample1_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample1_vaf_cols], col=sample_colors[1], pch=16, cex=point_cex)
        lines(x=c(xp-0.25,xp+0.25), y=rep(data[i,combined_vaf_cols[1]],2), col=sample_colors[1], lwd=2)
      }

      if (length(sample2_vaf_cols) > 0){
        xpoints = runif(n=length(sample2_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample2_vaf_cols], col=sample_colors[2], pch=16, cex=point_cex)
        lines(x=c(xp-0.25,xp+0.25), y=rep(data[i,combined_vaf_cols[2]],2), col=sample_colors[2], lwd=2)
      }

      if (length(sample3_vaf_cols) > 0){
        xpoints = runif(n=length(sample3_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample3_vaf_cols], col=sample_colors[3], pch=16, cex=point_cex)
        lines(x=c(xp-0.25,xp+0.25), y=rep(data[i,combined_vaf_cols[3]],2), col=sample_colors[3], lwd=2)
      }

      if (length(sample4_vaf_cols) > 0){
        xpoints = runif(n=length(sample4_vaf_cols), min=(xp-flank), max=(xp+flank))
        points(x=xpoints, y=data[i,sample4_vaf_cols], col=sample_colors[4], pch=16, cex=point_cex)
        lines(x=c(xp-0.25,xp+0.25), y=rep(data[i,combined_vaf_cols[4]],2), col=sample_colors[4], lwd=2)
      }

    }else{
      if (length(sample1_vaf_cols) > 0){ points(x=xp, y=data[i,combined_vaf_cols[1]], col=sample_colors[1], pch=16, cex=point_cex) }
      if (length(sample2_vaf_cols) > 0){ points(x=xp, y=data[i,combined_vaf_cols[2]], col=sample_colors[2], pch=16, cex=point_cex) }
      if (length(sample3_vaf_cols) > 0){ points(x=xp, y=data[i,combined_vaf_cols[3]], col=sample_colors[3], pch=16, cex=point_cex) }
      if (length(sample4_vaf_cols) > 0){ points(x=xp, y=data[i,combined_vaf_cols[4]], col=sample_colors[4], pch=16, cex=point_cex) }
    }
  }
  legend_text = sample_names[1]
  if (length(sample2_vaf_cols) > 0) {legend_text = c(legend_text,sample_names[2]) }
  if (length(sample3_vaf_cols) > 0) {legend_text = c(legend_text,sample_names[3]) }
  if (length(sample4_vaf_cols) > 0) {legend_text = c(legend_text,sample_names[4]) }
  legend_colors = sample_colors[1]
  if (length(sample2_vaf_cols) > 0) {legend_colors = c(legend_colors,sample_colors[2]) }
  if (length(sample3_vaf_cols) > 0) {legend_colors = c(legend_colors,sample_colors[3]) }
  if (length(sample4_vaf_cols) > 0) {legend_colors = c(legend_colors,sample_colors[4]) }


  legend("topright", legend=legend_text, col=legend_colors, pch=16)
  dev.off()
}


#################################################################################################
#Boxplots of aggregate VAFs for each sample                                                     #
#################################################################################################
plot_boxplots = function(outfile, gene_i, main_label_vafs){

  pdf(outfile)
  par(font.lab=2)
  par(font.axis=2)
  par(mgp=c(3,1.5,0)) #axis title, axis labels and axis line.
  vaf_dist = list(data[gene_i,combined_vaf_cols[1]])
  bp_names = paste(sample_names[1], "\n", "(", round(median(data[gene_i,combined_vaf_cols[1]]),digits=2), "%)", sep="")  
  
  if (length(sample2_vaf_cols) > 0) {
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]])
    bp_names = c(bp_names, paste(sample_names[2], "\n", "(", round(median(data[gene_i,combined_vaf_cols[2]]),digits=2), "%)", sep=""))
  }
  if (length(sample3_vaf_cols) > 0) { 
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]], data[gene_i,combined_vaf_cols[3]]) 
    bp_names = c(bp_names, paste(sample_names[3], "\n", "(", round(median(data[gene_i,combined_vaf_cols[3]]),digits=2), "%)", sep=""))
  }
  if (length(sample4_vaf_cols) > 0) { 
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]], data[gene_i,combined_vaf_cols[3]], data[gene_i,combined_vaf_cols[4]]) 
    bp_names = c(bp_names, paste(sample_names[4], "\n", "(", round(median(data[gene_i,combined_vaf_cols[4]]),digits=2), "%)", sep=""))
  }

  n = length(gene_i)
  ii = which(data[gene_i,target_name] == 1)
  y_label = paste("Variant allele frequency (VAF) [n = ", n, "]", sep="")
  point_col = "grey50"
  point_cex = 0.6
  text_col = "black"

  #Starting box plot
  boxplot(vaf_dist, col=sample_colors, names=bp_names, ylab=y_label, main=main_label_vafs, pch=NA, border="grey50")

  #Individual points and horizontal lines at median of each distribution
  flank = 0.150
  xp = 1
  xpoints1 = NULL; ypoints1=NULL; xpoints2 = NULL; ypoints2=NULL; xpoints3 = NULL; ypoints3=NULL; xpoints4 = NULL; ypoints4=NULL; 
  xpoints1 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
  ypoints1 = data[gene_i,combined_vaf_cols[1]]
  points(x=xpoints1, y=ypoints1, col=point_col, pch=16, cex=1)
  abline(h=median(data[gene_i,combined_vaf_cols[1]]), lty=2, lwd=1, col=sample_colors[1])
  if (length(ii) > 0){ text(x=xpoints1[ii], y=ypoints1[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }

  if (length(sample2_vaf_cols) > 0) { 
    xp = 2
    xpoints2 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints2 = data[gene_i,combined_vaf_cols[2]]
    points(x=xpoints2, y=ypoints2, col=point_col, pch=16, cex=1)
    abline(h=median(data[gene_i,combined_vaf_cols[2]]), lty=2, lwd=1, col=sample_colors[2]) 
    segments(x0=xpoints1, x1=xpoints2, y0=ypoints1, y1=ypoints2, lty=3, lwd=0.75, col="black")
    if (length(ii) > 0){ text(x=xpoints2[ii], y=ypoints2[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }
  if (length(sample3_vaf_cols) > 0) { 
    xp = 3
    xpoints3 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints3 = data[gene_i,combined_vaf_cols[3]]
    points(x=xpoints3, y=ypoints3, col=point_col, pch=16, cex=1)
    abline(h=median(data[gene_i,combined_vaf_cols[3]]), lty=2, lwd=1, col=sample_colors[3]) 
    segments(x0=xpoints2, x1=xpoints3, y0=ypoints2, y1=ypoints3, lty=3, lwd=0.75, col="black")
    if (length(ii) > 0){ text(x=xpoints3[ii], y=ypoints3[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }
  if (length(sample4_vaf_cols) > 0) { 
    xp = 4
    xpoints4 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints4 = data[gene_i,combined_vaf_cols[4]]
    points(x=xpoints4, y=ypoints4, col=point_col, pch=16, cex=1)
    abline(h=median(data[gene_i,combined_vaf_cols[4]]), lty=2, lwd=1, col=sample_colors[4]) 
    segments(x0=xpoints3, x1=xpoints4, y0=ypoints3, y1=ypoints4, lty=3, lwd=0.75, col="black")
    if (length(ii) > 0){ text(x=xpoints4[ii], y=ypoints4[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }
  dev.off()
}


#Create a plot where points are plotted as a time series
# - one block for each $timepoint_names, one color category for each $sample_types, order blocks according to $timepoint_positions
#                      [day0, day0, day30]                          [normal, tumor, tumor]                  [1,1,2]
plot_timeline = function(outfile, gene_i, main_label_vafs){

  pdf(outfile)
  par(font.lab=2)
  par(font.axis=2)
  par(mgp=c(3,1.5,0)) #axis title, axis labels and axis line.
  vaf_dist = list(data[gene_i,combined_vaf_cols[1]])
  
  if (length(sample2_vaf_cols) > 0) {
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]])
  }
  if (length(sample3_vaf_cols) > 0) { 
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]], data[gene_i,combined_vaf_cols[3]]) 
  }
  if (length(sample4_vaf_cols) > 0) { 
    vaf_dist = list(data[gene_i,combined_vaf_cols[1]], data[gene_i,combined_vaf_cols[2]], data[gene_i,combined_vaf_cols[3]], data[gene_i,combined_vaf_cols[4]]) 
  }
  max_y = max(unlist(vaf_dist))
  n = length(gene_i)
  ii = which(data[gene_i,target_name] == 1)
  y_label = paste("Variant allele frequency (VAF) [n = ", n, " variants]", sep="")
  point_cex = 1
  text_col = "black"

  #Starting box plot
  test_data = list(c(0,25,50), c(0,25,50))
  if (length(unique(timepoint_names)) == 3){
    test_data = list(c(0,25,50), c(0,25,50), c(0,25,50))
  }
  if (length(unique(timepoint_names)) == 4){
    test_data = list(c(0,25,50), c(0,25,50), c(0,25,50), c(0,25,50))
  }

  boxplot(test_data, col=NA, border=NA, names=unique(timepoint_names), ylab=y_label, main=main_label_vafs, pch=NA, ylim=c(0,max_y+5))

  #Individual points and horizontal lines at median of each distribution
  xpoints1 = NULL; ypoints1=NULL; xpoints2 = NULL; ypoints2=NULL; xpoints3 = NULL; ypoints3=NULL; xpoints4 = NULL; ypoints4=NULL; 
  flank = 0.150
  
  #Sample 1
  if (length(sample1_vaf_cols) > 0) {
    tp_name = timepoint_names[1]
    xp = timepoint_positions[1]
    xpoints1 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints1 = data[gene_i,combined_vaf_cols[1]]
    points(x=xpoints1, y=ypoints1, col=sample_colors[1], pch=16, cex=1)
    if (length(ii) > 0 & sample_types[1] != "normal"){ text(x=xpoints1[ii], y=ypoints1[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }

  #Sample 2
  if (length(sample2_vaf_cols) > 0) { 
    tp_name = timepoint_names[2]
    xp = timepoint_positions[2]    
    xpoints2 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints2 = data[gene_i,combined_vaf_cols[2]]
    points(x=xpoints2, y=ypoints2, col=sample_colors[2], pch=16, cex=1)
    if (sample_types[1] != "normal" & sample_types[2] != "normal"){
      segments(x0=xpoints1, x1=xpoints2, y0=ypoints1, y1=ypoints2, lty=3, lwd=0.75, col="black")
    }
    if (length(ii) > 0 & sample_types[2] != "normal"){ text(x=xpoints2[ii], y=ypoints2[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }

  #Sample 3
  if (length(sample3_vaf_cols) > 0) { 
    tp_name = timepoint_names[3]
    xp = timepoint_positions[3]
    xpoints3 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints3 = data[gene_i,combined_vaf_cols[3]]
    points(x=xpoints3, y=ypoints3, col=sample_colors[3], pch=16, cex=1)
    if (sample_types[2] != "normal" & sample_types[3] != "normal"){
      segments(x0=xpoints2, x1=xpoints3, y0=ypoints2, y1=ypoints3, lty=3, lwd=0.75, col="black")
    }
    if (length(ii) > 0 & sample_types[3] != "normal"){ text(x=xpoints3[ii], y=ypoints3[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }

  #Sample 4
  if (length(sample4_vaf_cols) > 0) { 
    tp_name = timepoint_names[4]
    xp = timepoint_positions[4]
    xpoints4 = runif(n=length(gene_i), min=(xp-flank), max=(xp+flank))
    ypoints4 = data[gene_i,combined_vaf_cols[4]]
    points(x=xpoints4, y=ypoints4, col=sample_colors[4], pch=16, cex=1)
    if (sample_types[3] != "normal" & sample_types[4] != "normal"){
      segments(x0=xpoints3, x1=xpoints4, y0=ypoints3, y1=ypoints4, lty=3, lwd=0.75, col="black")
    }
    if (length(ii) > 0 & sample_types[4] != "normal"){ text(x=xpoints4[ii], y=ypoints4[ii], labels=data[gene_i[ii], "default_gene_name"], cex=point_cex, col=text_col, font=4) }
  }

  #Legend
  legend("topright", sample_names, col=sample_colors[1:length(sample_names)], pch=16, cex=1)
  dev.off()
}


#################################################################################################
#VAF/Coverage plots AND Boxplots of distribution - with different subsets of variants           #
#################################################################################################

#Plot variants that overlapped the target gene list (e.g. RMG list)
target_gene_i = which(data[,target_name] == 1)
if (length(target_gene_i) > 0){
  outfile1 = paste(outdir, case_name, "_target_gene_vafs.pdf", sep="")
  outfile2 = paste(outdir, case_name, "_target_gene_vafs_boxplots.pdf", sep="")
  outfile3 = paste(outdir, case_name, "_target_gene_vafs_timeline.pdf", sep="")

  x_label = paste(target_name, " Gene Mutations", sep="")
  main_label = paste("Aggregate VAFs for target genes: ", target_name, " (", case_name, ")", sep="")
  main_label_vafs = paste("Replicate VAFs for target genes: ", target_name, sep="")
  main_label_covs = paste("Replicate coverages for target genes: ", target_name, " (", case_name, ")",  sep="")
  plot_vafs(outfile1, x_label, main_label_vafs, main_label_covs, target_gene_i)
  plot_boxplots(outfile2, target_gene_i, main_label)
  plot_timeline(outfile3, target_gene_i, main_label)
}

#Plot the top 10 variants (ranked by max tumor vaf observed)
o = order(data[,"max_tumor_vaf_observed"], decreasing=TRUE)
target_gene_i = o
if (length(o) >= 10){
  target_gene_i = o[1:10]
}

if (length(target_gene_i) > 0){
  outfile1 = paste(outdir, case_name, "_top_gene_vafs.pdf", sep="")
  outfile2 = paste(outdir, case_name, "_top_gene_vafs_boxplots.pdf", sep="")
  outfile3 = paste(outdir, case_name, "_top_gene_vafs_timeline.pdf", sep="")
  x_label = "Gene Mutations"
  main_label = paste("Aggregate VAFs for highest VAF mutations", " (", case_name, ")", sep="")
  main_label_vafs = "Replicate VAFs for highest VAF mutations"
  main_label_covs = paste("Replicate coverages for highest VAF mutations", " (", case_name, ")", sep="")
  plot_vafs(outfile1, x_label, main_label_vafs, main_label_covs, target_gene_i)
  plot_boxplots(outfile2, target_gene_i, main_label)
  plot_timeline(outfile3, target_gene_i, main_label)
}

#Plot all variants called by at least 2 callers
target_gene_i = which(data[,"variant_source_caller_count"] > 1)
if (length(target_gene_i) > 0){
  outfile1 = paste(outdir, case_name, "_multicaller_vafs.pdf", sep="")
  outfile2 = paste(outdir, case_name, "_multicaller_vafs_boxplots.pdf", sep="")
  outfile3 = paste(outdir, case_name, "_multicaller_vafs_timeline.pdf", sep="")
  x_label = "Gene Mutations"
  main_label = paste("Aggregate VAFs for variants called by >= 2 callers", " (", case_name, ")", sep="")
  main_label_vafs = "Replicate VAFs for variants called by >= 2 callers"
  main_label_covs = paste("Replicate coverages for variants called by >= 2 callers", " (", case_name, ")", sep="")
  plot_vafs(outfile1, x_label, main_label_vafs, main_label_covs, target_gene_i)
  plot_boxplots(outfile2, target_gene_i, main_label)
  plot_timeline(outfile3, target_gene_i, main_label)
}

#Plot all variants
o = order(data[,"max_tumor_vaf_observed"], decreasing=TRUE)
target_gene_i = o
if (length(target_gene_i) > 0){
  outfile1 = paste(outdir, case_name, "_all_gene_vafs.pdf", sep="")
  outfile2 = paste(outdir, case_name, "_all_gene_vafs_boxplots.pdf", sep="")
  outfile3 = paste(outdir, case_name, "_all_gene_vafs_timeline.pdf", sep="")
  x_label = "Gene Mutations"
  main_label = paste("Aggregate VAFs for all mutations", " (", case_name, ")", sep="")
  main_label_vafs = "Replicate VAFs for all mutations"
  main_label_covs = paste("Replicate coverages for all mutations", " (", case_name, ")", sep="")
  if (length(target_gene_i) > 25){
    main_label_vafs = "Aggregate VAFs for all mutations"
    main_label_covs = paste("Aggregate coverages for all mutations", " (", case_name, ")", sep="")
  }
  plot_vafs(outfile1, x_label, main_label_vafs, main_label_covs, target_gene_i)
  plot_boxplots(outfile2, target_gene_i, main_label)
  plot_timeline(outfile3, target_gene_i, main_label)
}



