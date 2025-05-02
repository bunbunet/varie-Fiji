// INIZIALIZZAZIONE
labelImagePath = "/path/labelImage.tif";
roiPath = "/path/rois.zip";
fluos = newArray("/path/FluoChannel1.tif", "/path/FluoChannel2.tif");

// Carica immagine etichettata
open(labelImagePath);
rename("Labels");
run("Set Label Map", "");
selectWindow("Labels");

// Carica ROI
roiManager("Reset");
roiManager("Open", roiPath);
nROIs = roiManager("Count");

// Loop su ROI
for (r = 0; r < nROIs; r++) {
    roiManager("Select", r);
    roiManager("Rename", "ROI_"+r);
    run("Duplicate...", "title=Labels_ROI_"+r+"");
    run("Clear Outside"); // maschera fuori ROI

    // Loop su canali di fluorescenza
    for (f = 0; f < fluos.length; f++) {
        open(fluos[f]);
        rename("Fluo_"+f);
        run("Duplicate...", "title=Fluo_"+f+"_ROI_"+r+"");
        run("Clear Outside");

        // Analisi MorphoLibJ 3D
        run("Region Morphometry 3D", "input=Labels_ROI_"+r+" grayscale=Fluo_"+f+"_ROI_"+r+" exclude_border=false");

        // Salva la tabella (puoi salvare CSV se vuoi)
        saveAs("Results", "/percorso/output/Morpho3D_results_ROI"+r+"_ch"+f+".csv");
        run("Close");
        run("Close");
    }

    // Pulisce immagini temporanee
    selectWindow("Labels_ROI_"+r);
    run("Close");
}

// Chiudi tutto
roiManager("Reset");
