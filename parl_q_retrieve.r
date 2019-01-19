#source("c:/users/mfitsilis/documents/myr/parl_xml3.r")
require(XML)
require(htmltab)
require(RCurl)
require(stringr)

#use to get full table in results
#for downloading of the files curl can be used

#fileout1.txt is needed as input with the table fields

#pdf link is missing when a question has been withdrawn

#can get table with htmltab - easy as only 1 table!
#getNodeSet can be used for the option lists
#only downside - greek letters don't display in Rstudio (uses UTF-16) - but they extract just fine to csv
#option list show nice in Rstudio but don't extract nice, after converting to data.frames

readfileout <- function(filename){ #read txt file
  con=file(filename,"r") 
  header=readLines(con)
  close(con)
  header
}

#dir1<-"c:/docs/parl"
setwd(dir1) #set directory

#the queries look like this
url<- "https://www.hellenicparliament.gr/Koinovouleftikos-Elenchos/Mesa-Koinovouleutikou-Elegxou?subject=&protocol=&ministry=&datefrom=&dateto=&type=63c1d403-0d19-409f-bb0d-055e01e1487c&SessionPeriod=ef3c0f44-85cc-4dad-be0c-a43300bca218&partyId=&mpId=&pageNo=&SortBy=ake&SortDirection=asc"

# since we're interested in Questions       - type=63c1d403-0d19-409f-bb0d-055e01e1487c
# and for the session 05.02.2015-28.08.2015 - SessionPeriod=ef3c0f44-85cc-4dad-be0c-a43300bca218

#first let's get the following 4 option tables:
# ddSessionPeriod
# ddtype
# ddPoliticalParties
# ddMps
#let's extract those from the previous page - for every parl. session ddPoliticalParties and ddMps may be different 

t1 <- getURL(url,.opts = list(ssl.verifypeer = FALSE) )
t1 <- htmlParse(t1)

options <- getNodeSet(xmlRoot(t1),"//select[@id='ddtype']/option")
ids_ddtype <- sapply(options, xmlGetAttr, "value")
ddtype <- sapply(options, xmlValue)

options <- getNodeSet(xmlRoot(t1),"//select[@id='ddSessionPeriod']/option")
ids_sesper <- sapply(options, xmlGetAttr, "value")
sesper <- sapply(options, xmlValue)

options <- getNodeSet(xmlRoot(t1),"//select[@id='ddPoliticalParties']/option")
ids_polpar <- sapply(options, xmlGetAttr, "value")
polpar <- sapply(options, xmlValue)

options <- getNodeSet(xmlRoot(t1),"//select[@id='ddMps']/option")
ids_mps <- sapply(options, xmlGetAttr, "value")
mps <- sapply(options, xmlValue)

#now let's write those to files (UTF-16, should work in Excel - https://stackoverflow.com/questions/29957678/utf-8-characters-get-lost-when-converting-from-list-to-data-frame-in-r)
df1<- data.frame(ID=ids_ddtype, Name=ddtype)
write.table(df1,'parl_ddtype.csv')
df2<- data.frame(ID=ids_sesper, Name=sesper)
write.table(df2,'parl_sesper.csv')
df3<- data.frame(ID=ids_polpar, Name=polpar)
write.table(df3,'parl_polpar.csv')
df4<- data.frame(ID=ids_mps, Name=mps)
write.table(df4,'parl_mps.csv')

# let's set the session period and also datatype to Question
sp<- ... #27 #ids_sesper[3] #11] #1st item in list is [3]!
dt<- ... #ids_ddtype[2]

#now we'll build the url
#this is the homepage
url0<- "https://www.hellenicparliament.gr"
q0<-"/Koinovouleftikos-Elenchos/Mesa-Koinovouleutikou-Elegxou?"
q1<-"subject="
q2<-"&protocol="
#q3<-"&type=63c1d403-0d19-409f-bb0d-055e01e1487c"
q3<-paste("&type=",ids_ddtype[dt],sep="")
#q4<-"&SessionPeriod=ef3c0f44-85cc-4dad-be0c-a43300bca218"
q4<-paste("&SessionPeriod=",ids_sesper[sp],sep="")
q5<-"&partyId="
q6<-"&mpId="
q7<-"&ministry="
q8<-"&datefrom="
q9<-"&dateto="
q10<-"&pageNo="
q11<-"&SortBy=ake&SortDirection=asc"
#q10<-paste("&pageNo=",pn,sep="")
url<- paste(url0,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,sep="")

#now let's read the 1st page

t1 <- getURL(url,.opts = list(ssl.verifypeer = FALSE) )
t1 <- htmlParse(t1)

#we'll use htmltab to extract the table, we're lucky there's only one table in the page, so we don't specify location
t2<- htmltab(doc = t1,which=1)
cname<- colnames(t2)[1] #get header
#pagenum has total num of result pages - we'll use them in q10<-"pageNo="
cnums<-as.numeric(unique(unlist(regmatches(cname, gregexpr("[0-9]+", cname))))) #extract total num, cur page, total page num
pagenum<- cnums[3]
qtotnum<- cnums[1]
#write table to file with no header and without last line - are irrelevant

#now lets query all pages and collect the results into one dataframe

t51=readfileout("fileout1.txt") #file contains the header with 12 fields - one entry per line

totnum=pagenum # dowload how many pages : 1 - pagenum
a5=c(NULL)
for(i in 1:totnum){
  #i=613
  url<-paste(url0,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9,"&SortBy=ake&SortDirection=asc",q10,i,sep="")
  t1<- getURL(url,.opts = list(ssl.verifypeer = FALSE) )
  t1<- htmlParse(t1)
  t2<- htmltab(doc = t1,rm_nodata_cols = F,which=1)
  #print(paste("t2",nrow(a3),ncol(a3)))
  t2<- t2[,1:4]
  t2<-t2[1:nrow(t2)-1,] #remove last row
  
  #now get the links from the table
  g1<-as.character(getNodeSet(xmlRoot(t1), "//a/@href")) #filter xml for href
  l1=c(NULL) #using for loop slows things down - sapply would be faster
  for(j in 1:length(g1)){  #the links should have ?pcm_id=
    l1[j]=length(unlist(strsplit(g1[j],"[?=]"))) # result should be 3
  }
  
  g2<-g1[which(l1==3)]  #these should be the links
  g2<- paste(url0,g2,sep="")
  #append links as last column
  g3<-cbind(t2,data.frame(g2))  
  
  #now get the fields after the link
  a1=c(NULL)
  for(k in 1:length(g2)){
    #k=3
    t3<-getURL(g3[k,5],.opts = list(ssl.verifypeer = FALSE) )
    t4<- htmlParse(t3)
    t5 <- xpathSApply(t4, "//dt", xmlValue) # titles
    t6 <- xpathSApply(t4, "//dd", xmlValue) # values
    t6<-gsub("\\r\\n","-",t6)   # if length=13 discard 8th field : Information (empty)
    t6<-gsub("\\t","",t6)
    
    #write the header to fileout2 to compare to t51 - because of unicode encoding in R it doesn't work correctly otherwise
    write.table(iconv(t5,from="",to=""),file="fileout2.txt",row.names = F,quote = F, col.names = F)
    t52=readfileout("fileout2.txt")
    
    t53<-match(t52,t51)  #position of the field or NA if not available
    t54<-match(seq(12),t53)
    t55<-c(NULL) 
    for (j in 1:12){ #copy correct element or empty string
      t55<-c(t55,ifelse(is.na(t54[j]),"",t6[t54[j]]))
    }
    t6<-t55 # copy to initial vector
    
      t7<-as.character(getNodeSet(xmlRoot(t4), "//a/@href")) #1st is question - rest are answer files
      t8<-substr(t7,str_length(t7)-2,str_length(t7))
      t9<-which(t8=="pdf") #only keep links ending in "pdf"
      t10<-paste(url0,t7[t9],sep="")
      if(length(t10)>0){ #question file
        t6[11]<-t10[1]
      }
      if(length(t10)>1){ #answer files
        t6[12]<-toString(t10[-1])
      }
     
      t61<-unlist(str_split(unlist(str_split(t6[11],"/"))[6],".pdf"))[1] #just the question link
      t61<-ifelse(is.na(t61),"",t61) 
      t6<-c(t6,t61) #add link as 13th field
      
      #print(length(t6))
    
    a1<-iconv(c(a1,t6),from="",to="") #necessary character conversion
  }
  
  a2<-matrix(a1,nrow = length(t6))  #convert vector to matrix
  a3<-cbind(g3,t(a2))  #append the fields at the end of the table

  #change column titles - use only english names because greek characters cannot be saved reliably in r script despite utf-8 encoding
  colnames(a3)<-c("Protocol Number","Date","Type","Subject","Link","Number","Type","Session/Period","Subject","Party","Date","Date Last Modified","Submitter","Ministries","Ministers","Question File","Answer Files","link serialNr")
  
  #append to last table
  a5= rbind(a5,a3)
  print(i) #print page num
}

#save to table with # delimiter
write.table(a5,"result.csv",sep="#",col.names = T,row.names = F, quote=F) #set separator to # because ",; are already used



 G�W�D$�T$��W�D$�T$��|$X�GԠ���= ��    �G�W��������   �GfW�f.�����������G�W�D$�T$��|$X�G԰���= ��    ���o����o����D$PȨ�D$   �D$�����|$X�G�����= ��    �G�W�>����    �����88���1   �98���%   �D$�L$��|$X�G����= ��    �6   �G�W�D$�T$�D$   �D$������|$X�G����= ��    �G�G�����I�������   �GfW�f.��V����?����G�W�D$�T$��|$X�G����= ��    ���#��������D$TȨ�D$ȯ���|$X�G�(���= ��    �G�W������D$�T$�D$XȨ��|$X�G�<���= ��    �G�W������    � ����D$�T$�D$\Ȩ��|$X�GԐ���= ��    �G�W�����88���1   �98���%   �D$�L$��|$X�GԴ���= ��    �(   �D$�T$�L$�\$��|$X�GԴ���= ��    ���G�G�������������   �GfW�f.������������G�W�D$�T$��|$X�G�����= ��    ������������D$`Ȩ�D$   �D$ԯ���|$X�G�����= ��    �G�W�`����    �����D$dȨ�D$   �D$����|$X�G����= ��    �G�W�����    ������D$hȨ�D$   �D$����|$X�G�T���= ��    �G�W�����    ������D$�T$�D$lȨ��|$X�GԘ���= ��    �G�W���������   �GfW�f.������������G�W�D$�T$��|$X�GԼ���= ��    ������������D$pȨ�D$   �D$�����|$X�G�����= ��    �G�W�[����    �����D$dȨ�D$   �D$����|$X�G����= ��    �G�W�|����    ������D$hȨ�D$   �D$����|$X�G�L���= ��    �G�W�����    ������D$PȨ�D$   �D$�����|$X�GԐ���= ��    �G�W�����    ������88���1   �98���%   �D$�L$��|$X�G�����= ��    �6   �G�W�D$�T$�D$   �D$������|$X�G�����= ��    �G�G������������   �GfW�f.�����������G�W�D$�T$��|$X�G�����= ��    ��������y����D$hȨ�D$   �D$����|$X�G�����= ��    �G�W�C����    �����D$dȨ�D$   �D$����|$X�G�0���= ��    �G�W�X����    �����D$tȨ�D$   �D$����|$X�G�l���= ��    �G�W�m����D$�T$�D$xȨ��|$X�GԄ���= ��    �G�W�[����    �����D$TȨ�D$ȯ���|$X�G�����=