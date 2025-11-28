suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(data.table)
})

table_all <- read.csv("C:/Users/feder/Documents/LAB/ProgettoQA/SOX2/Sox2_J/Results/table_all.csv")

setwd("C:/Users/feder/Documents/LAB/ProgettoQA/SOX2/Sox2_J/")

##############################################################################################x

cell_types <- c(
  "SOX2-SOX9",
  "SOX9",
  "SOX2",
  "Ki67-SOX2",
  "DCX-Ki67-SOX2",
  "DCX-SOX2",
  "DCX",
  "DCX-Ki67",
  "Ki67",
  "DCX-SOX2-SOX9",
  "Ki67-SOX2-SOX9",
  "DCX-SOX9",
  "DCX-Ki67-SOX9",
  "Ki67-SOX9",
  "DCX-Ki67-SOX2-SOX9"
)


px_size=0.5687376

# #-------------------------------EXPORT COORDINATES TO ImageJ ROIs------------------------------
# This version avoids nested for-loops: it binds once, cleans once, and writes per group with data.table
# Dependencies: data.table (fast IO), dplyr, stringr

#choose a tag for the cells you want to export

tag<-"SOX9_coordinates"

out_dir <- file.path("Export", tag)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cells_to_export<- cell_types #all cells
#cell_type[cell_type != "SOX9"] # all cells but SOX9 only.

# Filter cell types and columns
all_dt<-table_all %>% 
  filter(ColocByDist2 %in% cells_to_export) %>% 
  select(ImageName,ROI_name,Marker,ColocByDist2,label,X,Y,Z,Zmin,Zmax) %>%
  mutate (Xpx = round(X/px_size,0))  %>%
  mutate (Ypx = round(Y/px_size,0))  %>%
  mutate (Zpx = round(Z/px_size,0))  %>% 
  mutate (Zpx2= round(Zmin+(Zmax-Zmin)/2,0))  %>%# get the centroid in pixels
  mutate (ROIc=paste(Marker,".",ColocByDist2,"x",label)) # set the name fo the ROI to show in ROI manager
# A . will separate the segmentation marker, a x the label


# Assicurati che ImageName sia un factor o un character
all_dt$ImageName <- as.character(all_dt$ImageName)

# Suddivide in una lista di data frame, uno per livello di ImageName
dt_by_image <- split(all_dt, all_dt$ImageName)


# Esporta ogni tabella come CSV usando il nome della sezione
all_dt$ImageName <- as.character(all_dt$ImageName)

dt_by_image <- split(all_dt, all_dt$ImageName)

for (nm in names(dt_by_image)) {
  write.csv(dt_by_image[[nm]][, c("Xpx","Ypx","Zpx","Zpx2","ROIc")],
            file.path(out_dir, paste0(nm, ".csv")),
            row.names = FALSE,
            quote = FALSE)
}


#cat("✔️ Esportazione completata! File salvati in:", out_dir, "\n")

