function myView3D(image,spacing,crosshair,crange,cmap)
% myView3D: Display orthogonal slices in an image in a 3D view
% usage:
%         myView3D(image,spacing,crosshair,crange,cmap)
% required parameters:
%         image                   3D image volume
%         spacing                 3x1 vector of voxel spacings
% optional parameters:
%         crosshair               3x1 vector giving the crosshair position.
%                                 Defaults to the center of the image.
%         crange                  1x2 vector giving the range of intensity
%                                 to be displayed. Defaults to [imin imax]
%                                 where imin and imax are the minimum and 
%                                 maximum intensity in the image.
%         cmap                    String, giving the name of the color map
%                                 to use. Defaults to 'gray'

if (nargin < 5 || isempty(cmap))
    cmap = 'gray';
end

if (nargin < 4 || isempty(crange))
    crange = [min(image(:)) max(image(:))];
end

if (nargin < 3 || isempty(crosshair))
    crosshair = round(size(image) / 2);
end


% Clear the display
clf;

% Generate a slice display
h = slice(image, crosshair(2), crosshair(1), crosshair(3));
set(h, 'EdgeColor', 'none');
axis vis3d;
daspect([1/spacing(2) 1/spacing(1) 1/spacing(3)]);

% Set up color range
caxis(crange);
colormap(cmap);
colorbar;

% Set title
title(sprintf('Crosshair = [%d %d %d]', crosshair));
