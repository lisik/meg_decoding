#!/bin/bash


matlab -nodesktop -nodisplay -nosplash -singleCompThread -r "run run_decoding_itx($1, $2); exit;"
