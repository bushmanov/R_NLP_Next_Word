# rm(list=ls(all=T))
# library(pryr)
# library(lineprof)
library(data.table)
library(stylo)
source("./clean_function.R")

# Read data

conTw <- file("./final/en_US/en_US.twitter.txt")
conNw <- file("./final/en_US/en_US.news.txt")
conBl <- file("./final/en_US/en_US.blogs.txt")
twRaw <- readLines(conTw, skipNul=T)
nwRaw <- readLines(conNw, skipNul=T)
blRaw <- readLines(conBl, skipNul=T)
closeAllConnections()
# sample for train and test
rawCorpus <- c(twRaw, nwRaw, blRaw)
rm(twRaw, nwRaw, blRaw)
set.seed(1)
train <- .6 # part of the whole to go to train
leng <- length(rawCorpus)
trainInd <- sample(1:leng, size = train*leng, replace=FALSE)
trainCorpus <- rawCorpus[trainInd]
# testCorpus <- rawCorpus[-trainInd]
# save(testCorpus, file="./testCorpus.RData")
rm(rawCorpus)


# Clean data
cleanCorpus <- .clean(trainCorpus)
rm(trainCorpus)

# write.table(nwClean, "../srilm/tw", quote = F, row.names = F)

# One sentence per line
delimCorpus <- tolower(unlist(strsplit(cleanCorpus, "\\.\\s")))
delimCorpus <- gsub("\\.$", "", delimCorpus)
rm(cleanCorpus)

# Tokenize
tokenCorpus <- strsplit(delimCorpus, " ")
rm(delimCorpus)
# Make n-grams

# 1. Drop too short sentences
tokenCorpus <- tokenCorpus[sapply(tokenCorpus, length) >= 3]

# 1. unigrams
uni <- data.table(tok=unlist(tokenCorpus))
rm(tokenCorpus)
lengthUni <- nrow(uni)
uni[,ord:=1:lengthUni]
uniTable <- uni[,.N, keyby=tok][order(-N)]

# 1. Define vocabulary and insert <UNK>
vocab <- uniTable[N>=2]
save(vocab, file="vocab.RData")
setkey(uni, tok)
uni[!vocab, tok:="<UNK>"]
rm(vocab)
setkey(uni, ord)
uni[,ord:=NULL]
uniTable <- uni[,.N, keyby=tok][order(-N)]
save(uniTable, file= "./UniTable.RData")
rm(uniTable)

# 2. bigrams
bi <- data.table(tok=make.ngrams(uni[,tok], 2))
biTable <- bi[,.N, keyby=tok][N>=2][order(-N)]
rm(bi)
rexp <- "^(.*)\\s(.*)$"
biTable <- biTable[,.(Key=sub(rexp,"\\1",tok), Value=sub(rexp,"\\2",tok), freq=N)]
biTable[, nKey:=nrow(.SD),by=Key][,Imp:=freq/nKey]
save(biTable, file= "./biTable.RData")
biModel <- biTable[,.SD[1:3], by=Key]
rm(biTable)
biModel <- biModel[Value != "NA"][Imp>=3]
save(biModel, file="./biModel.RData")
rm(biModel)

# 3. trigrams
tri <- data.table(tok=make.ngrams(uni[,tok], 3))
rm(uni)
triTable <- tri[,.N, by=tok][N>2][order(-N)]
rm(tri)
rexp3 <- "^(.*\\s.*)\\s(.*)$"
triTable <- triTable[,.(Key=sub(rexp3,"\\1",tok), Value=sub(rexp3,"\\2",tok), freq=N)]
triTable[, nKey:=nrow(.SD),by=Key][,Imp:=freq/nKey]
save(triTable, file="./triTable.RData")
triModel <- triTable[,.SD[1:3], by=Key]
rm(triTable)
triModel <- triModel[Value!="NA"][Imp >=3]
# triModel[,`:=`(freq=NULL, nKey=NULL, Imp=NULL)]
save(triModel, file="./triModel.RData")
