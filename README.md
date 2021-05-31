# qretrieve
This script is used by the Hellenic OCR Team to download freely available data on parliamentary questions and responses (metadata and respective pdf links) from the Hellenic Parliament servers: [https://hellenicocrteam.gr/](https://hellenicocrteam.gr/)

For parsing the website that links to parliamentary control data, the **rvest** package is used. Another dependency is **XML** for accessing the individual nodes of the downloaded page and **htmltab** for the handling of table data (for versioning, see below).

First, the path of the output directory is set using **setwd()**. In **pageScrape()** the individual table of a response is requested. The 12 fields in *fileout1.txt* are the ones of interest. These correspond to the metadata parameters captured for each parliamentary question. Sometimes, the order they appear may vary, causing discrepancies in matching the data to the respective parameters. Therefore, due to the way unicode works in R, a workaround has been applied: for every htms table, the header is saved in *fileout2.txt* and compared to the header of *fileout1.txt*, to be found in the GitHub repo. 

The function **writeQueryTables()** creates four files in the output directory containing the different parliamentary quenstion types, parliamentary periods and sessions, political parties, and members of parliament. The function **selectPeriodsDataTypes()** defines the data to be extracted. 
Finally, the function **getQueries(number/range)**, given a number or range, returns a file (*result.csv*) containing the details of the earlier specified number(s) of parliamentary question(s). 

**Examples:**
```
# Defining the parliametary session/period and control means (type)
session$sp = 1 # specifies parliamentary session 1  
session$dt = 2 # specifies data type (2 is "Question")  

# Types of queries
getQueries(7)                           # returns the 7th query from the specified period
getQueries(c(1,2,8))                    # returns the queries 1,2,8 from the specified period 
getQueries(createRandomList(5))         # returns a list of five random queries from the specified period
getQueries(createRandomList(prc=0.003)) # returns a list with 0.003% of the queries from the specified period
```
**Tested with:** R4.1 64bit <br>
**Package versions**, 
"XML": 3.99.0.6, 
"htmltab": 0.8.1, 
"rvest": 1.0.0
