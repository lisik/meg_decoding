#!/bin/bash


matlab -nodesktop -nodisplay -nosplash -singleCompThread -r "run convert_to_raster($1); exit;"
