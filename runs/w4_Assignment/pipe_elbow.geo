SetFactory("OpenCASCADE");

// Pipe dimensions

D = 0.1;   // Pipe diameter
L1 = 1;    // Length of horizontal section (x direction)
L2 = 2;    // Length of vertical section (y direction)
R = 0.15;  // Elbow radius (to pipe centreline)

// Number of layers in the elbow (vary this for the sensitivity analysis)
// Override from the command line with: -setnumber N_elbow <value>
DefineConstant[ N_elbow = {10, Name "N_elbow"} ];

// Create circle
Circle(1) = {0, 0, 0, D/2, 0, 2*Pi};

// Rotate circle
Rotate { {0, 1, 0}, {0, 0, 0}, Pi/2 }{ Curve{1}; }

Curve Loop(1) = {1};

Plane Surface(1) = {1};

// Mesh settings

Mesh.CharacteristicLengthMax = 0.02;
Mesh.RecombineAll = 1;

Field[1] = BoundaryLayer;

Field[1].CurvesList = {1}; // Curves that make up wall
Field[1].Size = 0.002; // First layer thickness
Field[1].Ratio = 1.2; // Geometric growth ratio
Field[1].Thickness = 0.02; // Total thickness of prism layer region
Field[1].Quads = 1;

BoundaryLayer Field = 1;


// Preview two-dimensional mesh

Mesh 2;

// Extrude mesh

lx = 0.05;      // Cell length along straight sections
N1 = L1/lx;     // Number of cells in horizontal section
N2 = L2/lx;     // Number of cells in vertical section

// Each Extrude returns: [0] = end face, [1] = volume, [2] = side (wall) surface

// Horizontal straight section (along +x)
p1[] = Extrude {L1, 0, 0}
{
   Surface{1};
   Layers{N1};
   Recombine;
};

// Elbow: revolve the end face of p1 by 90 degrees about the z axis,
// with the rotation axis passing through the centre of curvature (L1, R, 0)
e[] = Extrude { {0, 0, 1}, {L1, R, 0}, Pi/2 }
{
   Surface{p1[0]};
   Layers{N_elbow};
   Recombine;
};

// Vertical straight section (along +y)
p2[] = Extrude {0, L2, 0}
{
   Surface{e[0]};
   Layers{N2};
   Recombine;
};

// Preview three-dimensional mesh

Mesh 3;

// Set boundaries

Physical Surface("inlet") = {1};
Physical Surface("wall") = {p1[2], e[2], p2[2]};
Physical Surface("outlet") = {p2[0]};

// Identify the fluid domain

Physical Volume("fluid") = {p1[1], e[1], p2[1]};