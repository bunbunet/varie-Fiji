Title=getTitle();
print(Title);
run("Split Channels");
run("Merge Channels...", "c1=C4-"+Title+" c2=C1-"+Title+" c3=C3-"+Title+" c4=C2-"+Title+" create");
Stack.setChannel(1);
run("Cyan");
Stack.setChannel(2);
run("Green");
Stack.setChannel(3);
run("Red");
Stack.setChannel(4);
run("Grays");
