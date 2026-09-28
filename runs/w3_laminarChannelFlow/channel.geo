SetFactory("OpenCASCADE");

// Mesh for a two-dimensional channel (or plate)

//       8-----------------------7
//      / |                     / |
//     /  |                    /  |
//    5-----------------------6   |
//    |   |                   |   |
//    |   4-------------------|---3       z
//    |  /                    |  /        | y
//    | /                     | /         |/
//    1-----------------------2           0-----x

// Parameters

L = 100; // m, length, x // this was too short, our flow was not fully developed (og length 2)
h = 1; // m, height, y
d = 0.1; // m, depth, z

lc = 1e-1; // m, target mesh size used in uniform meshing

Nx = L/lc + 1;
Ny = h/lc + 1;
Nz = 1; // Two-dimensional


// Create points

Point(1) = {0, 0, 0, lc};
Point(2) = {L, 0, 0, lc};
Point(3) = {L, h, 0, lc};
Point(4) = {0, h, 0, lc};

// Connect points to create lines

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Connect lines to create a curve loop

Curve Loop(1) = {1, 2, 3, 4};

// Define a surface based on curve loop

Plane Surface(1) = {1};

// Can altenately create rectangle directly, enabled by OpenCASCADE kernel
// Rectangle(1) = {0, 0, 0, w, h}; //{xmin, ymin, zmin, w, h}

// Specify number of mesh nodes along each line

Transfinite Curve{1} = Nx;
Transfinite Curve{2} = Ny;
Transfinite Curve{3} = Nx;
Transfinite Curve{4} = Ny;

// Define a block-structured surface mesh on Surface(1)

Transfinite Surface{1}; 

// Create quadrangles instead of triangles

Recombine Surface{1};

// Create two-dimensional mesh

Mesh.Algorithm = 8; // 6 is the standard Frontal-Delaunay

Mesh 2;

// Extrude mesh with a length d and Nz elements

out[] = Extrude {0, 0, d} 
{ 
	Surface{1}; 
	Layers{ Nz }; 
	Recombine; 
};

// Create three-dimensional mesh

Physical Volume("fluid") = {out[1]};

Mesh 3;

// Set boundaries

Physical Surface("east") = {3};
Physical Surface("west") = {5};
Physical Surface("north") = {4};
Physical Surface("south") = {2};
Physical Surface("front") = {6};
Physical Surface("back") = {1};

