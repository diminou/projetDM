# Projet Data Mining
library(compiler)
install.packages("ROCR")
install.packages("readbitmap")
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

grayscale<-cmpfun(function(image){
  return(apply(image,  c(1, 2), sum))
})

gray<-grayscale(img)

unroll<-cmpfun(function(gray_img){
  return(c(gray_img))
})
length(dir(testr_dir))
dim(labels)
