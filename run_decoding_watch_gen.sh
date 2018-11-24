#!/bin/bash


matlab -nodesktop -nodisplay -nosplash -singleCompThread -r "run run_decoding_watch_gen($1); exit;"
