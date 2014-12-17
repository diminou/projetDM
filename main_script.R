# Projet Data Mining
library(compiler)
install.packages("tiff")
install.packages("mgcv")
install.packages("spatial")
install.packages("ROCR")
install.packages("readbitmap")
source("http://bioconductor.org/biocLite.R")
biocLite("EBImage")
library(EBImage)
library(readbitmap)

folder_path <- paste(getwd(), "/kaggle/Julia_char", sep = "")

filepath<-function(filename){
  return (paste(folder_path, filename, sep = "/"))
}

testr_dir<-filepath("testResized")
trainr_dir<-filepath("trainResized")
labels<-read.csv(filepath("trainLabels.csv"))

f<-system.file(paste(testr_dir, "9999.Bmp", sep="/"))
img <- read.bitmap(paste(testr_dir, "9999.Bmp", sep="/"))

grayscale<-function(image){
  return(apply(image,  c(1, 2), sum))
}




test<-read.table(paste(folder_path, "/test.tsv", sep = ""), sep = "\t", header = T)
train<-read.table(paste(folder_path, "/train.tsv", sep = ""), sep = "\t", header = T)

con<-file(filepath("train.tsv"), "rt")
lines<-readLines(con)
print(lines[38260])
close(con)

linesbis<-sapply(lines, function(string){ return (strsplit(string,"\t", fixed = T)) })

train<-data.frame(matrix(data = NA, nrow = 0, ncol = 4, byrow = T))
names(train)<-linesbis[[1]]
linesbis[[1]] <- NULL
for(i in linesbis){
  train<-rbind(train, i)
}

train<-data.frame(linesbis)
head(train)
names(train)<-train[1,1:4]
