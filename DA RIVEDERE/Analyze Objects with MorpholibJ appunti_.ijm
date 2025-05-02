BaseName=getTitle();
Specimen="miz";
zValue=32;

run("Analyze Regions 3D", "volume surface_area centroid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");

// Rename the results window to result table
				//Table.rename("Dcx-P29bP0.1_pz1_c4r1_z100_40X512_merging_1_ObjectIdentities-morpho", "Results");
				Table.rename(BaseName+"-morpho", "Results");
				// Add columns to specify specimen and section
				n=nResults;
				for (i = 0; i < nResults(); i++) {
				    setResult("Specimen", i, Specimen);
					setResult("Section.ID", i, zValue);
				}
				updateResults();	
				
				
function StripExtension(filename){
	NameSplit=split(filename,".");
	fileWext=NameSplit[0];
	for (i = 1; i < NameSplit.length-1; i++) {
		fileWext=fileWext+"."+NameSplit[i];
	}
	return fileWext;
}