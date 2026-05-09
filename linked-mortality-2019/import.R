# *****************************************************************************************
# May 2022
# 
# ** PUBLIC-USE LINKED MORTALITY FOLLOW-UP THROUGH DECEMBER 31, 2019 **
#
# The following R code can be used to read the fixed-width format ASCII public-use Linked
# Mortality Files (LMFs) from a stored location into a R data frame.  Basic frequencies
# are also produced.  
# 
# NOTE:   With the exception of linkage eligibility-status (ELIGSTAT), the other discrete
#         variables (e.g., MORTSTAT) are designated as integers. We provide the definitions
#         of the variable values in the comments but leave it up to the user to decide 
#         whether integer or factor variables is/are preferred for their analyses.  
#
# NOTE:   As some variables are survey specific, we have created two versions of the program: 
#         one for NHIS and another for NHANES.
# 
# *****************************************************************************************   
#
# NOTE:   To download and save the public-use LMFs to your hard-drive, go to the website:  
#
#         https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/
#
# SEE ALSO: 
#
#         https://www.cdc.gov/nchs/data/datalinkage/public-use-linked-mortality-file-description.pdf
#
# *****************************************************************************************   

## Note: permth_exm and permth_int are time to death (or follow up) in
## "person-months" since exam and interview respectively. This should
## permit regular survival analysis.


ystart <- seq(1999, 2017, by = 2)
cycles <- sprintf("%g_%g", ystart, ystart + 1)


import_cycle <- function(cycle, eligible.only = TRUE)
{
    infile <- sprintf("NHANES_%s_MORT_2019_PUBLIC.dat", cycle)
    ## read in the fixed-width format ASCII file
    mort <- read.fwf(file = infile,
                     widths = c(6, -8, 1, 1, 3, 1, 1, -21, 3, 3),
                     header = FALSE,
                     col.names = c("SEQN", "eligstat", "mortstat",
                                   "ucod_leading", "diabetes", 
                                   "hyperten", "permth_int", "permth_exm"),
                     na.strings = c(".", ".  "),
                     colClasses = "integer")
    mort <- cbind(cycle = cycle, mort)
    if (eligible.only) subset(mort, eligstat == 1) else mort
}

mort <- lapply(cycles, import_cycle, FALSE) |> do.call(what = rbind)



# NOTE:   SEQN is the unique ID for NHANES.

# Structure and contents of data
str(mort)


# Variable frequencies

#ELIGSTAT: Eligibility Status for Mortality Follow-up
xtabs(~ eligstat, mort)
#1 = "Eligible"
#2 = "Under age 18, not available for public release"
#3 = "Ineligible"

#MORTSTAT: Final Mortality Status
xtabs(~ mortstat, mort, addNA = TRUE)
# 0 = Assumed alive
# 1 = Assumed deceased
# <NA> = Ineligible or under age 18


xtabs(~ mortstat + eligstat, mort, addNA = TRUE)

mort <- subset(mort, eligstat == 1)





#UCOD_LEADING: Underlying Cause of Death: Recode
xtabs(~ ucod_leading, mort, addNA = TRUE)
# 1 = Diseases of heart (I00-I09, I11, I13, I20-I51)
# 2 = Malignant neoplasms (C00-C97)
# 3 = Chronic lower respiratory diseases (J40-J47)
# 4 = Accidents (unintentional injuries) (V01-X59, Y85-Y86)
# 5 = Cerebrovascular diseases (I60-I69)
# 6 = Alzheimer's disease (G30)
# 7 = Diabetes mellitus (E10-E14)
# 8 = Influenza and pneumonia (J09-J18)
# 9 = Nephritis, nephrotic syndrome and nephrosis (N00-N07, N17-N19, N25-N27)
# 10 = All other causes (residual)
# <NA> = Ineligible, under age 18, assumed alive, or no cause of death data available

#DIABETES: Diabetes Flag from Multiple Cause of Death (MCOD)
table(mort$diabetes, useNA="ifany")
# 0 = No - Condition not listed as a multiple cause of death
# 1 = Yes - Condition listed as a multiple cause of death
# <NA> = Assumed alive, under age 18, ineligible for mortality follow-up, or MCOD not available

#HYPERTEN: Hypertension Flag from Multiple Cause of Death (MCOD)
table(mort$hyperten, useNA="ifany")
# 0 = No - Condition not listed as a multiple cause of death
# 1 = Yes - Condition listed as a multiple cause of death
# <NA> = Assumed alive, under age 18, ineligible for mortality follow-up, or MCOD not available


saveRDS(mort, file = "nhanes-linked-mortality.rds")

