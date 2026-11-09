#!/bin/bash

gmsh cylinder.geo -3
gmshToFoam cylinder.msh
changeDictionary
