classdef avg_DS < handle

%  avg_DS implements the functions of basic_DS with the additional feature
%  that it can average together trials in a given cross validation split.
%
% Like all DS objects, basic_DS implements the method get_data, which has the following form:  
%
%  [XTr_all_time_cv YTr_all XTe_all_time_cv YTe_all] = get_data(ds);   where:
%
%    a. XTr_all_time_cv{iTime}{iCV} = [num_features x num_training_points] is a
%         cell array that has the training data for all times and cross-validation splits
%    b. YTr_all = [num_training_point x 1] a vector of the training labels  (the same training labels are used at all times and CV splits)
%    c. XTe_all_time_cv{iTime}{iCV} = [num_features x num_test_points] is a
%         cell array that has the test data for all times and cross-validation splits;   
%    d. YTe_all = [num_test_point x 1] a vector has the test labels (the same test labels are used at all times and CV splits)
%
%
%  The constructor for this object has the form:
%
%   ds = avg_DS(binned_data_name, specific_binned_label_name, num_cv_splits, load_data_as_spike_counts, nAvg), where:
%
%     a. binned_data_name: is string that has the name of a file that has data in binned-format, or is a cell array of binned-format binned_data      
%     b. specific_binned_labels_name: is a string containing a specific binned-format label name, or is a cell array/vector containing 
%           the specific binned names (i.e., binned_labels.specific_binned_label_name)
%     c. num_cv_splits = is a scalar indicating how many cross-validation splits there should be
%     d. nAvg: the number of trials within each cross validation split to
%           be averaged together
%     e. load_data_as_spike_counts:  an optional flag that can be set that will cause the data to be converted to spike counts if set to an integer rather than 0
%           (the create_binned_data_from_raster_data function saves data as firing rates by default).  This flag is useful
%           when using the Poison Naive Bayes classifier that needs spike counts rather than firing rates. If this flag is not set, the default behavior
%           is to use firing rates.
%
%
%  The avg_DS also has the following properties from basic_DS that can be set:
%
%  1. create_simultaneously_recorded_populations (default = 0).  If the data from all sites
%      was recorded simultaneously, then setting this variable to 1 causes the 
%      function to return simultaneous populations rather than pseudo-populations 
%      (for this to work all sites in 'the_data' must have the trials in the same order).  
%      If this variable is set to 2, then the training set is pseudo-populations and the
%      test set is simultaneous populations.  This allows one to estimate I_diag, as
%      described by Averbeck, Latham and Pouget in 'Neural correlations, population coding
%      and computation', Nature Neuroscience, May, 2006.  I_diag is a measure that gives a 
%      sense of whether training on pseudo-populations leads to a the same decision rule as 
%      when training on simultaneous populations.  
%
%  2.  sample_sites_with_replacement (default = 0).  This variable specifies whether 
%        the sites should be sample with replacement - i.e., if the data is 
%        sampled with replacement, then some sites will be repeated within a single 
%        population vector.  This allows one to do a bootstrap estimate of variance
%        of the results if different sites from a larger population had been selected
%        while also ensuring that there is no overlapping data between the training
%        and test sets.  
%                    
%  3. num_times_to_repeat_each_label_per_cv_split (default = 1).  This variable 
%        specifies how many times each label should appear in each cross-validation split.
%        For example, if this value is set to k, this means that there will be k
%        population vectors from each class in each test set, and there will be 
%        k * (num_cv_splits - 1) population vectors for each class in each training set split.  
%     
%  4. label_names_to_use (default = [] meaning all unique label names in the_labels are used).  
%       This specifies which labels names (or numbers) to use, out of the unique label
%       names that are present in the the_labels cell array. If only a subset of labels are listed, 
%       then only population vectors that have the specified labels will be returned.  
%
%  5. num_resample_sites (default = -1, which means use all sites).  This variable specifies
%        how many sites should be randomly selected each time the get_data method is called.
%        For example, suppose length(the_data) = n, and num_resample_sites = k, then each
%        time get_data is called, k of the n sites would randomly be selected to be included
%        as features in the population vector.  
%      
%  6. sites_to_use (default = -1, which means select features from all sites).  This
%       variable allows one to only choose features from the sites listed in this vector
%       (i.e., features will only be randomly selected from the sites listed in this vector).
%    
%  7. sites_to_exclude (default = [], which means do not exclude any sites).  This allows          
%       one to not select features from particular sites (i.e., features will NOT be
%       selected from the sites listed in this vector).
%
%  8. time_periods_to_get_data_from (default = [], which means create one feature
%       for all times that are present in the_data{iSite} matrix).  This variable 
%       can be set to a cell array that contains vectors that specify which time bins 
%       to use as features from the_data. For examples, if time_periods_to_get_data_from = {[2 3], [4 5], [10 11]}
%       then there will be three time periods for XTr_all_time_cv and  XTe_all_time_cv 
%       (i.e., length(XTr_all_time_cv) = 3), and the population vectors for the 
%       time period will have 2 * num_resample_sites features, with the population 
%       vector for the first time period having data from each resample site from times
%       2 and 3 in the_data{iSite} matrix, etc..  
%
%  9. randomly_shuffle_labels_before_running (default = 0). If this variable is set to one
%       then the labels are randomly shuffled prior to the get_data method being called (thus all calls
%       to get_data return the same randomly shuffled labels). This method is useful for creating a 
%       null distribution to test whether a decoding result is above what one would expect by chance.  
%
%
%  This object also has two addition method which are:
%  
%  1.  the_properties = get_DS_properties(ds)
%       This method returns the main property values of the datasource.
%
%  2.  ds = set_specific_sites_to_use(ds, curr_resample_sites_to_use)
%        This method causes the get_data to use specific sites rather than
%        choosing sites randomly.  This method should really only be used by 
%        other datasources that are extending the functionality of basic_DS.
%
%
%  Note: this class is a subclass of the handle class, meaning that when this object is created a
%   reference to the object is returned.  Thus when fields of the object are changed a copy of the 
%   object does not need to be returned (by default matlab objects are passed by value). The
%   advantage of having this object inherit from the handle class is that if the object changes its
%   state within a method, a copy of the object does not need to be returned (this is particularly
%   useful for the randomly_permute_labels_before_running method so that the labels can be randomly
%   shuffled once prior to the get_data method being called, and the same shuffled labels will
%   be used throughout all subsequent calls to get_data, allowing one to create a full null distribution
%   by running the code multiple times).
%    



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
    
    the_basic_DS = [];      % the basic_DS that will be used to give this object most of its functionality
    
                                  
    % some properties of basic_DS that will also be available in generalization_DS by setting the basic_DS properties
    %the_labels                    %  a cell array that contains vectors of labels that specify what occurred during each trial for all neurons the_data cell array  
    
  %  num_cv_splits                 %  how many cross-validation splits there should be 
 
    
    num_times_to_repeat_each_label_per_cv_split = 1;     %  how many of each unique label should be in each CV block
    
    label_names_to_use = [];     %  which set of labels names should be used (or which numbers should be used if the_labels{iSite} is a vector of numbers)

    
    sample_sites_with_replacement = 0;  %  specify whether to sample neurons with replacement - if they are sampled with replacement, then some features will be repeated within a single point data vector
    num_resample_sites = -1;            %  how many sites should be used for each resample iteration - must be less than length(the_data)
    
    create_simultaneously_recorded_populations = 0;   % to use pseudo-populations or simultaneous populations (2 => that the training set is pseudo and test is simultaneous)
      
    sites_to_use = -1;                   %  a list of indices of which sites (neurons) to use in the the_data cell array 
    sites_to_exclude = [];               %  a list of features that should explicitly be excluded
    time_periods_to_get_data_from = [];  %  a cell array containing vectors that specify which time bins to use from the_data 

                                        
    % randomly shuffles the labels prior to the get_data method being called - which is useful for creating one point in a null distribution to check if decoding results are above what is expected by change.
    randomly_shuffle_labels_before_running = 0;                          
    
    nAvg = []; % number of stimulus repetitions to average in each CV split
                   
                                   
           
end



properties (GetAccess = 'public', SetAccess = 'private')
     

                                
      initialized = 0;
      
end


methods

    

    
        % the constructor
        function ds = avg_DS(binned_data_name, specific_binned_label_name, num_cv_splits, nAvg, load_data_as_spike_counts)
            if nargin < 5
                load_data_as_spike_counts = 0;
            end
            
            ds.the_basic_DS = basic_DS(binned_data_name, specific_binned_label_name, num_cv_splits, load_data_as_spike_counts);   % set properties using parent constructor
            ds.nAvg = nAvg;
            
            
        end
        
        
        %  This method returns the main property values of the datasource (could be useful for saving what parameters were used)
        function the_properties = get_DS_properties(ds)
            the_properties = ds.the_basic_DS.get_DS_properties;
            the_properties.nAvg = ds.nAvg;

        end
        
        
        
        function  [XTr_all_time_cv YTr_all XTe_all_time_cv YTe_all] = get_data(ds) 
      
            % initialize variables the first time ds.get_data is called
            if ds.initialized == 0
                
                disp('initializing avg_DS.get_data')
                
                % creating separate variables for this since calling a field of an object in Matlab is slow
                nAvg = ds.nAvg;
                
               % ds.the_basic_DS.num_cv_splits = ds.num_cv_splits;
                ds.the_basic_DS.label_names_to_use = ds.label_names_to_use;
                ds.the_basic_DS.num_times_to_repeat_each_label_per_cv_split = ds.num_times_to_repeat_each_label_per_cv_split;
                
                ds.the_basic_DS.sample_sites_with_replacement = ds.sample_sites_with_replacement ;
                ds.the_basic_DS.num_resample_sites = ds.num_resample_sites;
                
                ds.the_basic_DS.create_simultaneously_recorded_populations = ds.create_simultaneously_recorded_populations;
                
                ds.the_basic_DS.sites_to_use = ds.sites_to_use;
                ds.the_basic_DS.sites_to_exclude = ds.sites_to_exclude;
                ds.the_basic_DS.time_periods_to_get_data_from = ds.time_periods_to_get_data_from;
                
                ds.the_basic_DS.randomly_shuffle_labels_before_running = ds.randomly_shuffle_labels_before_running;

                
                % check that you are not trying to average too many trials
                % together
                if (ds.nAvg>ds.num_times_to_repeat_each_label_per_cv_split)
                    error(['nAvg must be less than or equal to the num_times_to_repeat_each_label_per_cv_split']);
                end
                
                
                % now that everything has been initialized, set inialized flag to 1     
                ds.initialized = 1;
                
            end   % end initialization
            
            [XTr_all_time_cv YTr_all XTe_all_time_cv YTe_all] = ds.the_basic_DS.get_data;
            
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
                
                for iLabel = 1:length(ds.label_names_to_use)
                    indTr=find(YTr_all==ds.the_basic_DS.label_names_to_use(iLabel));
                    indTe=find(YTe_all==ds.the_basic_DS.label_names_to_use(iLabel));
                    perm_tr = randperm(length(indTr));
                    perm_te = randperm(length(indTe));
                    
                    for iAvg = 1:floor(size(indTr,1)/ds.nAvg)
                      
                        avg_inds = (iAvg-1)*ds.nAvg+1:(iAvg)*ds.nAvg;
                        
                        %average training data
                        curr_train_ind = (iLabel - 1)*floor(size(indTr,1)/ds.nAvg)+iAvg;

                        tempTr = XTr_all_time_cv{iTimePeriod}{iCV}(:,indTr(perm_tr(avg_inds)));
                        XTr_temp{iTimePeriod}{iCV}(:,curr_train_ind) = mean(tempTr,2);
                        YTr_temp(curr_train_ind) = ds.the_basic_DS.label_names_to_use(iLabel);
                     
                        %average test data
                        if iAvg <= floor(size(indTe,1)/ds.nAvg)
                            curr_test_ind = (iLabel - 1)*floor(size(indTe,1)/ds.nAvg)+iAvg;
                            tempTe = XTe_all_time_cv{iTimePeriod}{iCV}(:,indTe(perm_te(avg_inds)));
                            XTe_temp{iTimePeriod}{iCV}(:,curr_test_ind) = mean(tempTe,2);
                            YTe_temp(curr_test_ind) = ds.the_basic_DS.label_names_to_use(iLabel);
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



