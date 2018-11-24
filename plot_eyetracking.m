clear all
addpath('../../Toolboxes/graphics_copy/')
file_IDs = {'s16','s19', 's22', 's23', 's24', 's25','s26', 's27', ...
    's28', 's29', 's30','s32'};

%file_IDs = {'s18', 's31', 's33', 's34'};

for s = 1:length(file_IDs)
raster_folder = ['/om/user/lisik/socialInteraction_meg/raster_data/' ...
    file_IDs{s} '_eyelink/'];
load([raster_folder 'raster_ch313.mat'])
LX(s,:,:)= raster_data;
load([raster_folder 'raster_ch314.mat'])
LY(s,:,:) = raster_data;
load([raster_folder 'raster_ch316.mat'])
RX(s,:,:) = raster_data;
load([raster_folder 'raster_ch317.mat'])
RY(s,:,:) = raster_data;
end

%% Plot average across subj for each scenario
for i = 1:12
figure; plot(-199:1000, squeeze(mean(mean([LX(:,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:);...
    RX(:,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:)]))))
hold on;
plot(-199:1000, squeeze(mean(mean([LX(:,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:);...
    RX(:,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:)]))))
title(['Scenario ' num2str(i) ' Mean x position'])
legend({'interact', 'no interact'})

figure; plot(-199:1000, squeeze(mean(mean([LY(:,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:);...
    RY(:,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:)]))))
hold on;
plot(-199:1000, squeeze(mean(mean([LY(:,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:);...
    RY(:,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:)]))))
title(['Scenario ' num2str(i) ' Mean y position'])
legend({'interact', 'no interact'})
keyboard
end

%% Plot average for each subj for one scenario
i = 7;
for j = 1:12
    
figure; plot(-199:1000, mean(squeeze([LX(j,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:),...
    RX(j,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:)])))
hold on;
plot(-199:1000, mean(squeeze([LX(j,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:),...
    RX(j,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:)])))
title(['Scenario ' num2str(i) ', Subject ' num2str(j) ' Mean x position'])
legend({'interact', 'no interact'})

figure; plot(-199:1000, mean(squeeze([LY(j,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:),...
    RY(j,raster_labels.stim_ID==i|raster_labels.stim_ID==i+12,:)])))
hold on;
plot(-199:1000, mean(squeeze([LY(j,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:),...
    RY(j,raster_labels.stim_ID==i+24|raster_labels.stim_ID==i+36,:)])))
title(['Scenario ' num2str(i) ', Subject ' num2str(j) ' Mean y position'])
legend({'interact', 'no interact'})
keyboard
end

% figure; plot(-199:1000, mean([LY(raster_labels.social_ID==1,:);RY(raster_labels.social_ID==1,:)]))
% hold on;
% plot(-199:1000, mean([LY(raster_labels.social_ID==2,:);RY(raster_labels.social_ID==2,:)]))
% title('Mean y position')
% legend({'interact', 'no interact'})
% 
% figure; 
% plot(-199:1000, mean([LY(raster_labels.social_ID==1,:);RY(raster_labels.social_ID==1,:)]))
% hold on;
% plot(-199:1000, mean([LY(raster_labels.social_ID==2,:);RY(raster_labels.social_ID==2,:)]))
% title('Mean y position')
% legend({'interact', 'no interact'})
% 
% 
% [h_lx,p_lx] = ttest(LX(raster_labels.social_ID==1,:), LX(raster_labels.social_ID==2,:) );
% [h_ly,p_ly] = ttest(LY(raster_labels.social_ID==1,:), LY(raster_labels.social_ID==2,:) );
% [h_rx,p_rx] = ttest(RX(raster_labels.social_ID==1,:), RX(raster_labels.social_ID==2,:) );
% [h_ry,p_ry] = ttest(RY(raster_labels.social_ID==1,:), RY(raster_labels.social_ID==2,:) );


for i = 1:5
load(['/mindhive/nklab3/users/lisik/brainstorm/brainstorm_db/social_interaction_meg/data/soc16/s16_tsss_mc_band/data_8_trial00' ...
    num2str(i) '.mat'])
eyepos(i,:) = mean(F([313,314,316,317],600:700),2);
 eyepos2 = F([313,314,316,317],:);
figure; plot(eyepos2')
keyboard
end
