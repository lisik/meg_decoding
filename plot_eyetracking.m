load('raster_ch313.mat')
[h,p] = ttest(raster_data(raster_labels.social_ID==1,:), raster_data(raster_labels.social_ID==2,:));