
function myViewAffineReg(fixed, moving, spacing, A, b)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% myView extended to display affine transformation results  %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - fixed,moving,spacing,A,b                                     %%
%% fixed - fixed image                                                   %%
%% moving - moving image                                                 %%
%% spacing - voxel spacing                                               %%
%% A - 3 x 3 rotation, scaling and shearing matrix                       %%
%% b - 3 x 1 translation matrix                                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fixed = double(fixed);
moving = double(moving);

dimen = size(fixed);

% crosshair at the center of the image
crosshair = round(dimen/2);

% k-means segmentation for XY slice
fixed_xy = transpose(squeeze(fixed(:,:,crosshair(3))));
[idx_xy, ctr_xy] = kmeans(fixed_xy(fixed_xy > 0), 3);
cont_xy = conv(sort(ctr_xy), [0.5 0.5], 'valid');

% k-means segmentation for XZ slice
fixed_xz = transpose(squeeze(fixed(:,crosshair(2),:)));
[idx_xz, ctr_xz] = kmeans(fixed_xz(fixed_xz > 0), 3);
cont_xz = conv(sort(ctr_xz), [0.5 0.5], 'valid');

% k-means segmentation for YZ slice
fixed_yz = transpose(squeeze(fixed(crosshair(1),:,:)));
[idx_yz, ctr_yz] = kmeans(fixed_yz(fixed_yz > 0), 3);
cont_yz = conv(sort(ctr_yz), [0.5 0.5], 'valid');

resampled = myTransformImage(fixed, moving, A, b);

% extract 2D images from  3D array
image_xy = transpose(squeeze(resampled(:,:,crosshair(3))));
image_xz = transpose(squeeze(resampled(:,crosshair(2),:)));
image_yz = transpose(squeeze(resampled(crosshair(1),:,:)));
    
% intensity range    
imin = min(min(min(resampled)));
imax = max(max(max(resampled)));
crange = [imin imax];
     
cmap = 'gray';
       
figure;

% show image for XY plane
subplot(2,2,1)
imagesc(image_xy);
set(gca,'XDir','reverse');
set(gca,'YDir','normal');
    
% set aspect ratio
daspect([spacing(2);spacing(1);1]);
    
% set color axis limits
caxis(crange);
title(['z = ',num2str(crosshair(3))]);
    
% draw crosshairs    
line([0 dimen(1)],[crosshair(2) crosshair(2)],'color','b');
line([crosshair(1) crosshair(1)],[0 dimen(2)],'color','b');

% draw contours
hold on
contour(fixed_xy, cont_xy, 'g');
hold off

% image for YZ plane
subplot(2,2,2)
imagesc(image_yz);
set(gca,'XDir','reverse');
set(gca,'YDir','normal');
daspect([spacing(3);spacing(2);1]);
caxis(crange);
title(['x = ',num2str(crosshair(1))]);
line([0 dimen(2)],[crosshair(3) crosshair(3)],'color','b');
line([crosshair(2) crosshair(2)],[0 dimen(3)],'color','b');
hold on
contour(fixed_yz, cont_yz, 'g');
hold off
    
% image for XZ plane    
subplot(2,2,3)
imagesc(image_xz);
set(gca,'XDir','reverse');
set(gca,'YDir','normal');
daspect([spacing(3);spacing(1);1]);
caxis(crange);
title(['y = ',num2str(crosshair(2))]);
line([0 dimen(1)],[crosshair(3) crosshair(3)],'color','b');
line([crosshair(1) crosshair(1)],[0 dimen(3)],'color','b');
hold on
contour(fixed_xz, cont_xz, 'g');
hold off
    
% show colorbar        
subplot(2,2,4)
caxis(crange);
axis off;
colorbar('south');
    
% display crosshair position and dimensions of image
text(0.2,0.8,sprintf('xhair = [%d %d %d]\ndimen = [%d %d %d]', crosshair, dimen));
   
% set colormap        
colormap(cmap)
hold off

end