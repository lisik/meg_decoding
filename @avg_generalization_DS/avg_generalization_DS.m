classdef avg_generalization_DS < handle

%  avg_generalization_DS implements the functions of generalization_DS with the additional feature
%  that it can average together trials in a given cross validation split.

%  This datasource object (DS) allows one to train a classifier on a specific 
%  set of labels, and then test the classifier on a different set of 
%  labels - which enables one to evaluate how similar neural representations 
%  are across different but related conditions (i.e., does training on one set of
%  conditions generalization to a different but related set of conditions?). This datasource
%  is a subclass of the handle class (i.e., it has a persistent state) and 
%  contains a basic_DS where it gets most of its functionality.  
%
%  The constructor for this datasource has the same arguments
%  as basic_DS, plus two additional arguments 'the_training_label_names' 
%  and 'the_test_label_names' i.e., the constructor has the form:  
%
%     ds = generalization_DS(binned_data_name, specific_binned_label_name, num_cv_splits, the_training_label_names, the_test_label_names, load_data_as_spike_counts, nAvg)
%   
%      the_training_label_names and the_test_label_names are cell arrays that
%        specify which labels should belong to which class, with the first element
%        of these cells arrays specifying the training/test labels for the first class
%        the second element of the cell array specifies which labels belong to 
%        the second class, etc..  For example, suppose one was interested in testing
%        position invariance, and had done an experiment in which data was recorded 
%        while 7 different objects were shown at three different locations.  If the
%        labels for the 7 objects at the first location had labels 'obj1_loc1', 'obj2_loc1', ..., 'obj7_loc1',
%        at the second location were 'obj1_loc2', 'obj2_loc2', ..., 'obj7_loc2',
%        and at the third location were 'obj1_loc3', 'obj2_loc3', ..., 'obj7_loc3',
%        then one could do a test of position invariance by setting the_training_label_names{1} = {'obj1_loc1},
%        setting the_training_label_names{2} = {'obj2_loc1'}, ...,  the_training_label_names{7} = {'obj7_loc1},
%        and setting the the_test_label_names{1} = {'obj1_loc2', 'obj1_loc3'}, 
%        the_test_label_names{2} = {'obj2_loc2', 'obj2_loc3'}, ..., the_test_label_names{7} = {'obj7_loc2', 'obj7_loc3'}. 
%        The object is able to test such generalization from training on one set of labels and
%        testing on a different set of labels by remapping the training label numbers to the
%        index number in the_training_label_names cell array, and remapping the 
%        test label numbers with the the index number into the the_test_label_names cell array.  
%
%     nAvg: the number of trials within each cross validation split to
%           be averaged together

%==========================================================================

%     This code is part of the Neural Decoding Toolbox.
%     Copyright (C) 2011 by Ethan Meyers (emeyers@mit.edu)
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
%==========================================================================  




  
properties 
    
    the_generalization_DS = [];      % the basic_DS that will be used to give this object most of its functionality
    
                                 
  %  the_training_label_names = [];   % a cell array specifying which label names (or numbers) should be used for training the classifier
                                       %  i.e., the_training_label_names{1} = {class_1_training_names}; the_training_label_names{2} = {class_2_training_names}; etc.
    %the_test_label_names = [];       % a cell array specifying which label names (or numbers) should be used for testing the classifier
                                       %   i.e., the_test_label_names{1} = {class_1_test_names}; the_test_label_names{2} = {class_2_test_names}; etc.
                                       
    use_unique_data_in_each_CV_split = 0;  % if this is set to 1 then each CV splits has unique data, i.e.,
                                                         %  each CV split has the amount of data that is typically only in the test set, 
                                                         %  and every CV training set does not consist of (num_cv_splits -1) * num_labels data points
                                                         %  but instead consists of length(cell2mat(the_test_label_names)) training points.
             
    
    num_times_to_repeat_each_label_per_cv_split = 1;     %  how many of each unique label should be in each CV block
    
   
    sample_sites_with_replacement = 0;  %  specify whether to sample neurons with replacement - if they are sampled with replacement, then some features will be repeated within a single point data vector
    num_resample_sites = -1;            %  how many sites should be used for each resample iteration - must be less than length(the_data)
    
    create_simultaneously_recorded_populations = 0;   % to use pseudo-populations or simultaneous populations (2 => that the training set is pseudo and test is simultaneous)
      
    sites_to_use = -1;                   %  a list of indices of which sites (neurons) to use in the the_data cell array 
    sites_to_exclude = [];               %  a list of features that should explicitly be excluded
    time_periods_to_get_data_from = [];  %  a cell array containing vectors that specify which time bins to use from the_data 

                                        
    % randomly shuffles the labels prior to the get_data method being called - which is useful for creating one point in a null distribution to check if decoding results are above what is expected by change.
    randomly_shuffle_labels_before_running = 0;                          
    
    nAvg = [];
                   
                                   
           
end



properties (GetAccess = 'public', SetAccess = 'private')
     

                                
      initialized = 0;
      
end


methods

    
        %function ds = basic_DS
        %end
    
    
        % the constructor
        function ds = avg_generalization_DS(binned_data_name, specific_binned_label_name, ...
                num_cv_splits, the_training_label_names, the_test_label_names, nAvg, load_data_as_spike_counts)
            
            if nargin < 7
                load_data_as_spike_counts = 0;
            end
            
          
            ds.the_generalization_DS = generalization_DS(binned_data_name, specific_binned_label_name, ...
                num_cv_splits, the_training_label_names, the_test_label_names, load_data_as_spike_counts);   % set properties using parent constructor
%         ds.the_generalization_DS = generalization_DS(binned_data_name, specific_binned_label_name, ...
%                 num_cv_splits, the_training_label_names, the_test_label_names, load_data_as_spike_counts);  
            ds.nAvg = nAvg;
                                                            
        end
        
        
        %  This method returns the main property values of the datasource (could be useful for saving what parameters were used)
        function the_properties = get_DS_properties(ds)
            
            the_properties = ds.the_generalization_DS.get_DS_properties;
            the_properties.nAvg = ds.nAvg;
           % keyboard

        end
        
        
        
        function  [XTr_all_time_cv YTr_all XTe_all_time_cv YTe_all] = get_data(ds) 
      
        
            % initialize variables the first time ds.get_data is called
            if ds.initialized == 0
                
                disp('initializing avg_generalization_DS.get_data')
                
                % creating separate variables for this since calling a field of an object in Matlab is slow
                nAvg = ds.nAvg;
                
               % ds.the_basic_DS.num_cv_splits = ds.num_cv_splits;
                %ds.the_basic_DS.label_names_to_use = ds.label_names_to_use;
                
%                 ds.the_generalization_DS.the_training_label_names = ds.the_training_label_names;
%                 ds.the_generalization_DS.the_test_label_names = ds.the_test_label_names;
        
                ds.the_generalization_DS.num_times_to_repeat_each_label_per_cv_split = ds.num_times_to_repeat_each_label_per_cv_split;
                
                ds.the_generalization_DS.sample_sites_with_replacement = ds.sample_sites_with_replacement ;
                ds.the_generalization_DS.num_resample_sites = ds.num_resample_sites;
                
                ds.the_generalization_DS.create_simultaneously_recorded_populations = ds.create_simultaneously_recorded_populations;
                
                ds.the_generalization_DS.sites_to_use = ds.sites_to_use;
                ds.the_generalization_DS.sites_to_exclude = ds.sites_to_exclude;
                ds.the_generalization_DS.time_periods_to_get_data_from = ds.time_periods_to_get_data_from;
                
                ds.the_generalization_DS.randomly_shuffle_labels_before_running = ds.randomly_shuffle_labels_before_running;

                     
                % now that everything has been initialized, set inialized flag to 1     
                ds.initialized = 1;
                
            end   % end initialization
            
            [XTr_all_time_cv YTr_all XTe_all_time_cv YTe_all] = ds.the_generalization_DS.get_data;
            
            XTr_temp = cell(size(XTr_all_time_cv));
            XTe_temp = cell(size(XTe_all_time_cv));
           
            % average data    
            for iTimePeriod = 1:length(XTr_all_time_cv)
            for iCV = 1:length(XTr_all_time_cv{1})
                
                nCh = size(XTr_all_time_cv{1}{1},1);
                nTrain = floor(length(YTr_all)/ds.nAvg);
                nTest = floor(length(YTe_all)/ds.nAvg);
                
                XTr_temp{iTimePeriod}{iCV} = zeros(nCh, nTrain);
                YTr_temp = zeros(nTrain,1);
                
                XTe_temp{iTimePeriod}{iCV} = zeros(nCh, nTest);
                YTe_temp = zeros(nTest,1);
               % keyboard
                for iLabel = 1:length(ds.the_generalization_DS.the_training_label_numbers)
                    indTr=find(YTr_all==iLabel);
                    indTe=find(YTe_all==iLabel);
                    perm_tr = randperm(length(indTr));
                    perm_te = randperm(length(indTe));
                    
                    for iAvg = 1:floor(size(indTr,1)/ds.nAvg)
                      
                        avg_inds = (iAvg-1)*ds.nAvg+1:(iAvg)*ds.nAvg;
                        
                        %average training data
                        curr_train_ind = (iLabel - 1)*floor(size(indTr,1)/ds.nAvg)+iAvg;

                        tempTr = XTr_all_time_cv{iTimePeriod}{iCV}(:,indTr(perm_tr(avg_inds)));
                        XTr_temp{iTimePeriod}{iCV}(:,curr_train_ind) = mean(tempTr,2);
                        YTr_temp(curr_train_ind) = iLabel;
                     
                        %average test data
                        if iAvg <= floor(size(indTe,1)/ds.nAvg)
                            curr_test_ind = (iLabel - 1)*floor(size(indTe,1)/ds.nAvg)+iAvg;
                            tempTe = XTe_all_time_cv{iTimePeriod}{iCV}(:,indTe(perm_te(avg_inds)));
                            XTe_temp{iTimePeriod}{iCV}(:,curr_test_ind) = mean(tempTe,2);
                            YTe_temp(curr_test_ind) = iLabel;
                        end
                    end

                end
                
            end
            end

            XTr_all_time_cv = XTr_temp;
            YTr_all = YTr_temp;
            
            XTe_all_time_cv = XTe_temp;
            YTe_all = YTe_temp;
            
        end   % end get_data
        
        
        
end  % end methods

    
   
   
   
end % end class



