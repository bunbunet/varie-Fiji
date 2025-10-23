


TableM<-read.csv("C:\\Users\\feder\\Documents\\LAB\\collaborazioni\\Enrica Reflectance\\Result Tables.csv")


TableM_summary<- TableM %>% group_by(Specimen,Region) %>% 
  summarise(n=n(), 
            DAPI_intDen=sum(DAPI_MGV),
            Ref1_intDen=sum(Ref1_MGV),
            Ref2_intDen=sum(Ref2_MGV),
            Ref_MGVsum)
    
    
    
    
    
    
    AreaSeg=(Area*Ref_AreaFraction)/100,
            across(DAPI_MGV:Ref_MGVsum,
                   ~ sum(.x, na.rm = TRUE),
                   .names = "{.col}_sum")
            )
