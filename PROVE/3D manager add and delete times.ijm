
run("3D Manager");
Ext.Manager3D_Close();
Ext.Manager3D_Reset();


print("----------RESET-------");
Ext.Manager3D_Reset();
start=getTime();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);
Ext.Manager3D_Reset();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);

print("----------SELECT ALL AND DELETE-------");
Ext.Manager3D_Reset();
start=getTime();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
end=getTime();
print("time: "+end-start);
print("Number of Objects:",Nb_of_objects)
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);

print("----------RESET-------");
Ext.Manager3D_Reset();
start=getTime();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);
Ext.Manager3D_Reset();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);

print("----------SELECT ALL AND DELETE-------");
Ext.Manager3D_Reset();
start=getTime();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
end=getTime();
print("time: "+end-start);
print("Number of Objects:",Nb_of_objects)
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects)
end=getTime();
print("time: "+end-start);


