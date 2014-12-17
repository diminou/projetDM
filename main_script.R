# Projet Data Mining
library(compiler)
install.packages("tiff")
install.packages("mgcv")
install.packages("spatial")
source("http://bioconductor.org/biocLite.R")
biocLite("EBImage")

folder_path <- paste(getwd(), "/kaggle/Julia_char", sep = "")

filepath<-function(filename){
  return (paste(folder_path, filename, sep = "/"))
}

testr_dir<-filepath("testResized")
trainr_dir<-filepath("trainResized")
labels<-read.csv(filepath("trainLabels.csv"))

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
