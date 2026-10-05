SetFactory("OpenCASCADE");

// Pipe dimensions
//intermediare 

D = 0.1;
L = 1;

// Create circle
Circle(1) = {0, 0, 0, D/2, 0, 2*Pi};

// Rotate circle
Rotate { {0, 1, 0}, {0, 0, 0}, Pi/2 }{ Curve{1}; }

Curve Loop(1) = {1};

Plane Surface(1) = {1};

// Mesh settings

Mesh.CharacteristicLengthMax = 0.008;
Mesh.RecombineAll = 1;

Field[1] = BoundaryLayer;

Field[1].CurvesList = {1}; // Curves that make up wall
Field[1].Size = 0.0008; // First layer thickness
Field[1].Ratio = 1.2; // Geometric growth ratio
Field[1].Thickness = 0.02; // Total thickness of prism layer region
Field[1].Quads = 1;

BoundaryLayer Field = 1;


// Preview two-dimensional mesh

Mesh 2;

// Extrude mesh

lx = 0.03; // Cell length in x direction
N = L/lx + 1; // Number of cells in x direction

Extrude {L, 0, 0}
{
   Surface{1};
   Layers{N};
   Recombine;
}

// Preview three-dimensional mesh

Mesh 3;

// Set boundaries

Physical Surface("inlet") = {1};
Physical Surface("wall") = {2};
Physical Surface("outlet") = {3};

// Identify the fluid domain

Physical Volume("fluid") = {1};

