

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}

// Example Use
list=newArray("io","tu","egli","noi");
target="noi";

if(contains(list,target)){
	print(target +  " found");
}