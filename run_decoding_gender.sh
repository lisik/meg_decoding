#!/bin/bash


matlab -nodesktop -nodisplay -nosplash -singleCompThread -r "run run_decoding_gender($1); exit;"
