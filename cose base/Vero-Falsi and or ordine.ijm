
print("--------------------3------------------------------");

if(false & true & true){
	print("false & true & true VERO");
} else  {
	print("false & true & true FALSO");
}

if(false | true | true){
	print("false | true | true VERO");
} else  {
	print("false | true | true FALSO");
}

if (false & true | true){
	print("false & true | true VERO");
} else  {
	print("false & true | true FALSO");
}

print("--------------------4------------------------------");

if(false & true & true | false){
	print("false & true & true | false VERO");
} else  {
	print("false & true & true | false FALSO");
}

if(false | true | true & false){
	print("false | true | true & false VERO");
} else  {
	print("false | true | true & false FALSO");
}

if(false | false | false & true){
	print("false | false | false & true VERO");
} else  {
	print("false | false | false & true FALSO");
}

if(false | false | true & true){
	print("false | false | true & true VERO");
} else  {
	print("false | false | true & true FALSO");
}