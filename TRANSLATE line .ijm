#@ String(label="Cell Name") name
#@ Integer(label="Number of Lines") num
#@ Float (label="Pixel displacement") disp
#@ String (choices={"L", "C", "R"}, style="radioButtonHorizontal") LeftRight
#@ String (choices={"U", "C", "D"}, style="radioButtonHorizontal") UpDown

// Calculate the displacements
if (LeftRight=="L" && UpDown=="U") {
	Xdisp=disp*(-cos(0.785));
	Ydisp=disp*(-cos(0.785));
}

if (LeftRight=="L" && UpDown=="D") {
	Xdisp=disp*(-cos(0.785));
	Ydisp=disp*(cos(0.785));
}

if (LeftRight=="R" && UpDown=="U") {
	Xdisp=disp*(cos(0.785));
	Ydisp=disp*(-cos(0.785));
}

if (LeftRight=="R" && UpDown=="D") {
	Xdisp=disp*(cos(0.785));
	Ydisp=disp*(cos(0.785));
}

if (LeftRight=="L" && UpDown=="C") {
	Xdisp=-disp;
	Ydisp=0;
}

if (LeftRight=="R" && UpDown=="C") {
	Xdisp=disp;
	Ydisp=0;
}

if (LeftRight=="C" && UpDown=="U") {
	Xdisp=0;
	Ydisp=-disp;
}

if (LeftRight=="C" && UpDown=="D") {
	Xdisp=0;
	Ydisp=disp;
}

//print("X "+Xdisp);
//print("Y "+Ydisp);

roiManager("Add");
nRois=roiManager("count");
roiManager("select",nRois-1);
roiManager("rename", name);


for (i = 0; i < num; i++) {
	roiManager("select",nRois-1);
	run("Translate... ", "x="+Xdisp+" y="+Ydisp+"");
	roiManager("Add");
	roiManager("select",nRois+i);
	roiManager("rename", name+"-"+(i+1)*num);	
}

