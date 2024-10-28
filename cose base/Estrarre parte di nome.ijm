tag="ciccio_pz1_20x_GFP.roi"

splitTag=split(tag,"_");
BaseName=splitTag[0];
for (i = 1; i < splitTag.length-1; i++) {
	BaseName=BaseName+"_"+splitTag[i];
}

print(BaseName);