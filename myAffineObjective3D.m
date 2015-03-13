
function [E,g] = myAffineObjective3D(p,I,J,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Objective function for 3D Affine Transform  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - p,I,J                                                        %%
%% optional - dJ/dy,dJ/dx,dJ/dz                                          %%
%% p - 12 x 1 parameter vector                                           %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%% dJ/dy - gradient of moving image in y direction                       %%
%% dJ/dx - gradient of moving image in x direction                       %%
%% dJ/dz - gradient of moving image in z direction                       %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - E,g                                                         %%
%% E - value of the objective function                                   %%
%% g - gradient of the objective function                                %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if number of arguments are between 3 and 6 
minarg = 3;
maxarg = 6;
narginchk(minarg, maxarg);
    
A = reshape(p(1:9),[3,3]);
b = p(10:12);

% coordinates of voxels in fixed image    
[x, y, z] = ndgrid(1:1:size(I,1),1:1:size(I,2),1:1:size(I,3));
    
X = transpose([x(:) y(:) z(:)]);

b_rep = repmat(b, 1, numel(x));

% transformation parameters
phi = A*X + b_rep;

phi_x = phi(1,:);
phi_y = phi(2,:);
phi_z = phi(3,:);

phi_x = reshape(phi_x, size(I));
phi_y = reshape(phi_y, size(I));
phi_z = reshape(phi_z, size(I));

% resample moving image
data = my_interp3_precompute(size(I), phi_x, phi_y, phi_z);
J_t = my_interp3(J,data);

% J_t = interpn(J,phi_x,phi_y,phi_z,'linear',0);

% compute the difference image
diff_image = I - J_t;

% compute the value of the objective function
E = sum(sum(sum(diff_image.^2)));

% compute gradient of resampled image
if (nargin == 6 && ~isempty(varargin{1}) && ~isempty(varargin{2}) && ~isempty(varargin{3}))
    dJdy = varargin{1};
    dJdx = varargin{2};
    dJdz = varargin{3};
else
    [dJdy, dJdx, dJdz] = gradient(J);
end

dJdx_phi = my_interp3(dJdx,data);
dJdy_phi = my_interp3(dJdy,data);
dJdz_phi = my_interp3(dJdz,data);

% dJdx_phi = interpn(dJdx,phi_x,phi_y,phi_z,'linear',0);
% dJdy_phi = interpn(dJdy,phi_x,phi_y,phi_z,'linear',0);
% dJdz_phi = interpn(dJdz,phi_x,phi_y,phi_z,'linear',0);

% compute partial derivative of E w.r.t. p
g = [-2*sum(sum(sum(diff_image.*dJdx_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdx_phi)));
    -2*sum(sum(sum(diff_image.*dJdy_phi)));
    -2*sum(sum(sum(diff_image.*dJdz_phi)))];

end