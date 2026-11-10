#!/bin/bash

gmsh tubeBundle.geo -3
gmshToFoam tubeBundle.msh
changeDictionary
