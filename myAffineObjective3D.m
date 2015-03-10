
function [E,g] = myAffineObjective3D(p,I,J,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Objective function for 3D Affine Transform  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - p,I,J,dJ/dX (optional)                                       %%
%% p - 12 x 1 parameter vector                                           %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%% dJ/dX - [dJ/dy dJ/dy dJ/dz], gradient of moving image                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - E,g                                                         %%
%% E - value of the objective function                                   %%
%% g - gradient of the objective function                                %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if number of arguments are between 3 and 4 
minarg = 3;
maxarg = 4;
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

%J_t = myTransformImage(I,J,A,b,'linear');

% compute the difference image
diff_image = I - J_t;

% compute the value of the objective function
E = sum(sum(sum(diff_image.^2)));

% compute gradient of resampled image
if nargin == 4 && ~isempty(varargin{1});
    [dJdy, dJdx, dJdz] = varargin{1};
else
    [dJdy, dJdx, dJdz] = gradient(J);
end

dJdx_phi = my_interp3(dJdx,data);
dJdy_phi = my_interp3(dJdy,data);
dJdz_phi = my_interp3(dJdz,data);

% dJdx_phi = interpn(dJdx,phi_x,phi_y,phi_z,'linear',0);
% dJdy_phi = interpn(dJdy,phi_x,phi_y,phi_z,'linear',0);
% dJdz_phi = interpn(dJdz,phi_x,phi_y,phi_z,'linear',0);

g = zeros(12,1);

% compute partial derivative w.r.t. p1
g(1) = -2*sum(sum(sum(diff_image.*dJdx_phi.*x)));

% compute partial derivative w.r.t. p2
g(2) = -2*sum(sum(sum(diff_image.*dJdy_phi.*x)));

% compute partial derivative w.r.t. p3
g(3) = -2*sum(sum(sum(diff_image.*dJdz_phi.*x)));

% compute partial derivative w.r.t. p4
g(4) = -2*sum(sum(sum(diff_image.*dJdx_phi.*y)));

% compute partial derivative w.r.t. p5
g(5) = -2*sum(sum(sum(diff_image.*dJdy_phi.*y)));

% compute partial derivative w.r.t. p6
g(6) = -2*sum(sum(sum(diff_image.*dJdz_phi.*y)));

% compute partial derivative w.r.t. p7
g(7) = -2*sum(sum(sum(diff_image.*dJdx_phi.*z)));

% compute partial derivative w.r.t. p8
g(8) = -2*sum(sum(sum(diff_image.*dJdy_phi.*z)));

% compute partial derivative w.r.t. p9
g(9) = -2*sum(sum(sum(diff_image.*dJdz_phi.*z)));

% compute partial derivative w.r.t. p10
g(10) = -2*sum(sum(sum(diff_image.*dJdx_phi)));

% compute partial derivative w.r.t. p11
g(11) = -2*sum(sum(sum(diff_image.*dJdy_phi)));

% compute partial derivative w.r.t. p12
g(12) = -2*sum(sum(sum(diff_image.*dJdz_phi)));

end