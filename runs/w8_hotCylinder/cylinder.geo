SetFactory("OpenCASCADE");

D = 0.01;

x1 = -10*D;
x2 = 10*D;
y1 = -10*D;
y2 = 20*D;

lc = 3e-3; // Target mesh size at points


// Create box for domain around cylinder

Point(1) = {x1, y1, 0, lc};
Point(2) = {x1, y2, 0, lc};
Point(3) = {x2, y2, 0, lc};
Point(4) = {x2, y1, 0, lc};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

Curve Loop(1) = {1, 2, 3, 4};

// Create circle

// Circle(tag) = {x0, y0, x0, radius, angleStart, angleEnd};
Circle(5) = {0, 0, 0, D/2, 0, 2*Pi};

Curve Loop(2) = {5};


// Define surface between the two curve loops

Plane Surface(1) = {1, 2}; // Curve Loop 2 is a hole


// Mesh size controls

Mesh.MeshSizeFromCurvature = 81;
Mesh.MeshSizeMax = lc;


Field[1] = BoundaryLayer;
Field[1].CurvesList = {5}; 
Field[1].Size = 0.0005; // First layer thickness
Field[1].Ratio = 1.05; // Geometric growth ratio
Field[1].Thickness = 5*D; // Total prism layer region thickness

BoundaryLayer Field = 1;

Mesh.RecombineAll = 1;

out[] = Extrude {0, 0, 0.01} 
{ 
	Surface{1}; 
	Layers{ 1 }; 
	Recombine; 
};

Physical Volume("fluid") = {out[1]};

Mesh 3;

Physical Surface("sides") = {2, 4};
Physical Surface("outlet") = {3};
Physical Surface("inlet") = {5};
Physical Surface("walls") = {6};
Physical Surface("frontAndBack") = {1, 7};

