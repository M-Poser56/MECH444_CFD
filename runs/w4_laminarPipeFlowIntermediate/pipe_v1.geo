SetFactory("OpenCASCADE");
//pipe dimensions
D = 0.1; //meters
L = 1;

//create cylinder
Cylinder(1) = {0, 0, 0, L, 0, 0, D/2}; //{x0, y0, z0, dx, dy, dz, radius}

//mesh sizing
Mesh.CharacteristicLengthMax = 0.02;

//+
Show "*";

//set boundaries
Physical Surface("wall") = {1};
Physical Surface("inlet") = {3};
Physical Surface("outlet") = {2};


//identify fluid domain
Physical Volume("fluid") = {1};

//previw mesh
Mesh 3;//+
Show "*";
