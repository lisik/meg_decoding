#!/bin/bash


matlab -nodesktop -nodisplay -nosplash -singleCompThread -r "run run_decoding_itx_gen($1); exit;"
