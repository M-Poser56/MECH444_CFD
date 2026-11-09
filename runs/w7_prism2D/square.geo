SetFactory("OpenCASCADE");

// Domain dimensions
D = 0.01;

x1 = -12*D;
x2 = 20*D;
y1 = -12*D;
y2 = 12*D;

lc = 3e-3; // Target mesh size at points

// Create box for domain around prism

Point(1) = {x1, y1, 0, lc};
Point(2) = {x1, y2, 0, lc};
Point(3) = {x2, y2, 0, lc};
Point(4) = {x2, y1, 0, lc};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

Curve Loop(1) = {1, 2, 3, 4}; // Box around cylinder

// Create cylinder
Circle(5) = {0, 0, 0, D/2};   // one closed curve, centred at same place as prism
Curve Loop(2) = {5};

// Define surface between the two curve loops

Plane Surface(1) = {1, 2}; // Curve Loop 2 is a hole

// Mesh size controls
Mesh.MeshSizeFromCurvature = 81;
Mesh.MeshSizeMax = lc;


//boundary layer field, following naca
Field[1] = BoundaryLayer;
Field[1].CurvesList = {5};     // cylinder wall
Field[1].Size = 0.0005;        // first layer thickness
Field[1].Ratio = 1.05;         // growth ratio
Field[1].Thickness = 5*D;      // total BL thickness
BoundaryLayer Field = 1;


Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = 0.0004; // Target element size close to prism
Field[2].SizeMax = lc; // Target element size far away
Field[2].DistMin = 0.2*D; // Within this distance -> SizeMin
Field[2].DistMax = 5*D; // Beyond this distance -> SizeMax

Background Field = 2;

// Recombine mesh
Mesh.RecombineAll = 1;

// Extrude
out[] = Extrude {0, 0, 0.01} 
{ 
	Surface{1}; 
	Layers{ 1 }; 
	Recombine; 
};

// Preview three-dimensional mesh
Mesh 3;

// Identify physical surfaces and volume
Physical Volume("fluid") = {out[1]};

Physical Surface("inlet") = {2};
Physical Surface("top") = {3};
Physical Surface("bottom") = {5};
Physical Surface("outlet") = {4};
Physical Surface("prism") = {6}; //leave as the same name for ease
Physical Surface("frontAndBack") = {1, 7};
