
And_Xor(1,3);
And_Xor(2,3);

function And_Xor(x, y) {
    roiManager("Select", newArray(x, y));
    roiManager("AND");
    roiManager("Add");
    nr = roiManager("count") - 1;//get the index of the temporary ROI
    roiManager("Select", newArray(x, nr));
    roiManager("XOR");
    roiManager("Update");
    roiManager("Select", nr);
    roiManager("Delete");
}
