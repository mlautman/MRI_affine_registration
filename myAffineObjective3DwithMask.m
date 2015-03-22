

function [E,g,H] = myAffineObjective3DwithMask(p,I,J,seg,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Objective function for 3D Affine Transform  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - p,I,J,seg                                                    %%
%% optional - dJ/dy,dJ/dx,dJ/dz                                          %%
%% p - 12 x 1 parameter vector                                           %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%% seg - segmetation of fixed image                                      %%
%% dJ/dy - gradient of moving image in y direction                       %%
%% dJ/dx - gradient of moving image in x direction                       %%
%% dJ/dz - gradient of moving image in z direction                       %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - E,g                                                         %%
%% E - value of the objective function                                   %%
%% g - gradient of the objective function                                %%
%% H - Hessian of the objective function                                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if number of arguments are between 3 and 6 
minarg = 4;
maxarg = 7;
narginchk(minarg, maxarg);
    
A = reshape(p(1:9),[3,3]);
b = p(10:12);

% coordinates of voxels in the mask    
[l, m, n] = ind2sub(size(seg),find(seg ~= 0));

[p, q, r] = ndgrid(min(l):min(l), min(m):max(m), min(n):max(n));

S = transpose([p(:) q(:) r(:)]);
b_rep = repmat(b, 1, numel(p));

% transformation parameters
phi = A*S + b_rep;

phi_x = phi(1,:);
phi_y = phi(2,:);
phi_z = phi(3,:);

phi_x = reshape(phi_x, size(p));
phi_y = reshape(phi_y, size(p));
phi_z = reshape(phi_z, size(p));

% resample moving image
J_t = interpn(J,phi_x,phi_y,phi_z,'linear',0);

% extract points in fixed image relevent to mask
I_i = interpn(I,p,q,r,'linear',0);

% compute the difference image
diff_image = I_i - J_t;

% compute the value of the objective function
E = sum(sum(sum(diff_image.^2)));

% compute gradient of resampled image
if (nargin == 7 && ~isempty(varargin{1}) && ~isempty(varargin{2}) && ~isempty(varargin{3}))
    dJdy = varargin{1};
    dJdx = varargin{2};
    dJdz = varargin{3};
else
    [dJdy, dJdx, dJdz] = gradient(J);
end

dJdx_phi = interpn(dJdx,phi_x,phi_y,phi_z,'linear',0);
dJdy_phi = interpn(dJdy,phi_x,phi_y,phi_z,'linear',0);
dJdz_phi = interpn(dJdz,phi_x,phi_y,phi_z,'linear',0);

% compute partial derivative of E w.r.t. p
g = [-2*sum(sum(sum(diff_image.*dJdx_phi.*p)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*p)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*p)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*q)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*q)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*q)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*r)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*r)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*r)));
    -2*sum(sum(sum(diff_image.*dJdx_phi)));
    -2*sum(sum(sum(diff_image.*dJdy_phi)));
    -2*sum(sum(sum(diff_image.*dJdz_phi)))];

% compute 2nd order partial derivatives
[Jxy, Jxx, Jxz] = gradient(dJdx);
[Jyy, Jyx, Jyz] = gradient(dJdy);
[Jzy, Jzx, Jzz] = gradient(dJdz);

Jxx_phi = interpn(Jxx,phi_x,phi_y,phi_z,'linear',0);
Jxy_phi = interpn(Jxy,phi_x,phi_y,phi_z,'linear',0);
Jxz_phi = interpn(Jxz,phi_x,phi_y,phi_z,'linear',0);
Jyx_phi = interpn(Jyx,phi_x,phi_y,phi_z,'linear',0);
Jyy_phi = interpn(Jyy,phi_x,phi_y,phi_z,'linear',0);
Jyz_phi = interpn(Jyz,phi_x,phi_y,phi_z,'linear',0);
Jzx_phi = interpn(Jzx,phi_x,phi_y,phi_z,'linear',0);
Jzy_phi = interpn(Jzy,phi_x,phi_y,phi_z,'linear',0);
Jzz_phi = interpn(Jzz,phi_x,phi_y,phi_z,'linear',0);

% compute Hessian of E w.r.t. p
H = zeros(12,12);

H(1,:) = [-2*(sum(sum(sum(-(dJdx_phi.*p).^2 + diff_image.*Jxx_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdx_phi.*p + diff_image.*Jxy_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdx_phi.*p + diff_image.*Jxz_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdx_phi.*p + diff_image.*Jxx_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdx_phi.*p + diff_image.*Jxy_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdx_phi.*p + diff_image.*Jxz_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdx_phi.*p + diff_image.*Jxx_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdx_phi.*p + diff_image.*Jxy_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdx_phi.*p + diff_image.*Jxz_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*p + diff_image.*Jxx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*p + diff_image.*Jxy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*p + diff_image.*Jxz_phi.*p))))];

H(2,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdy_phi.*p + diff_image.*Jyx_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-(dJdy_phi.*p).^2 + diff_image.*Jyy_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdy_phi.*p + diff_image.*Jyz_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdy_phi.*p + diff_image.*Jyx_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdy_phi.*p + diff_image.*Jyy_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdy_phi.*p + diff_image.*Jyz_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdy_phi.*p + diff_image.*Jyx_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdy_phi.*p + diff_image.*Jyy_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdy_phi.*p + diff_image.*Jyz_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*p + diff_image.*Jyx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*p + diff_image.*Jyy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*p + diff_image.*Jyz_phi.*p))))];

H(3,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdz_phi.*p + diff_image.*Jzx_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdz_phi.*p + diff_image.*Jzy_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-(dJdz_phi.*p).^2 + diff_image.*Jzz_phi.*(p.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdz_phi.*p + diff_image.*Jzx_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdz_phi.*p + diff_image.*Jzy_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdz_phi.*p + diff_image.*Jzz_phi.*p.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdz_phi.*p + diff_image.*Jzx_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdz_phi.*p + diff_image.*Jzy_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdz_phi.*p + diff_image.*Jzz_phi.*p.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*p + diff_image.*Jzx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*p + diff_image.*Jzy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*p + diff_image.*Jzz_phi.*p))))];

H(4,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdx_phi.*q + diff_image.*Jxx_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdx_phi.*q + diff_image.*Jxy_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdx_phi.*q + diff_image.*Jxz_phi.*q.*p)))),...
    -2*(sum(sum(sum(-(dJdx_phi.*q).^2 + diff_image.*Jxx_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdx_phi.*q + diff_image.*Jxy_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdx_phi.*q + diff_image.*Jxz_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdx_phi.*q + diff_image.*Jxx_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdx_phi.*q + diff_image.*Jxy_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdx_phi.*q + diff_image.*Jxz_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*q + diff_image.*Jxx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*q + diff_image.*Jxy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*q + diff_image.*Jxz_phi.*q))))];

H(5,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdy_phi.*q + diff_image.*Jyx_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdy_phi.*q + diff_image.*Jyy_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdy_phi.*q + diff_image.*Jyz_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdy_phi.*q + diff_image.*Jyx_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-(dJdy_phi.*q).^2 + diff_image.*Jyy_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdy_phi.*q + diff_image.*Jyz_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdy_phi.*q + diff_image.*Jyx_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdy_phi.*q + diff_image.*Jyy_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdy_phi.*q + diff_image.*Jyz_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*q + diff_image.*Jyx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*q + diff_image.*Jyy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*q + diff_image.*Jyz_phi.*q))))];

H(6,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdz_phi.*q + diff_image.*Jzx_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdz_phi.*q + diff_image.*Jzy_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdz_phi.*q + diff_image.*Jzz_phi.*q.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdz_phi.*q + diff_image.*Jzx_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdz_phi.*q + diff_image.*Jzy_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdz_phi.*q + diff_image.*Jzz_phi.*(q.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdz_phi.*q + diff_image.*Jzx_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdz_phi.*q + diff_image.*Jzy_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdz_phi.*q + diff_image.*Jzz_phi.*q.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*q + diff_image.*Jzx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*q + diff_image.*Jzy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*q + diff_image.*Jzz_phi.*q))))];

H(7,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdx_phi.*r + diff_image.*Jxx_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdx_phi.*r + diff_image.*Jxy_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdx_phi.*r + diff_image.*Jxz_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdx_phi.*r + diff_image.*Jxx_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdx_phi.*r + diff_image.*Jxy_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdx_phi.*r + diff_image.*Jxz_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdx_phi.*r + diff_image.*Jxx_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdx_phi.*r + diff_image.*Jxy_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdx_phi.*r + diff_image.*Jxz_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*r + diff_image.*Jxx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*r + diff_image.*Jxy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*r + diff_image.*Jxz_phi.*r))))];

H(8,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdy_phi.*r + diff_image.*Jyx_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdy_phi.*r + diff_image.*Jyy_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdy_phi.*r + diff_image.*Jyz_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdy_phi.*r + diff_image.*Jyx_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdy_phi.*r + diff_image.*Jyy_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdy_phi.*r + diff_image.*Jyz_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdy_phi.*r + diff_image.*Jyx_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdy_phi.*r + diff_image.*Jyy_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdy_phi.*r + diff_image.*Jyz_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*r + diff_image.*Jyx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*r + diff_image.*Jyy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*r + diff_image.*Jyz_phi.*r))))];

H(9,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdz_phi.*r + diff_image.*Jzx_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdz_phi.*r + diff_image.*Jzy_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdz_phi.*r + diff_image.*Jzz_phi.*r.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdz_phi.*r + diff_image.*Jzx_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdz_phi.*r + diff_image.*Jzy_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdz_phi.*r + diff_image.*Jzz_phi.*r.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdz_phi.*r + diff_image.*Jzx_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdz_phi.*r + diff_image.*Jzy_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdz_phi.*r + diff_image.*Jzz_phi.*(r.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*r + diff_image.*Jzx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*r + diff_image.*Jzy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*r + diff_image.*Jzz_phi.*r))))];

H(10,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdx_phi + diff_image.*Jxx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdx_phi + diff_image.*Jxy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdx_phi + diff_image.*Jxz_phi.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdx_phi + diff_image.*Jxx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdx_phi + diff_image.*Jxy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdx_phi + diff_image.*Jxz_phi.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdx_phi + diff_image.*Jxx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdx_phi + diff_image.*Jxy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdx_phi + diff_image.*Jxz_phi.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi + diff_image.*Jxx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi + diff_image.*Jxy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi + diff_image.*Jxz_phi))))];

H(11,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdy_phi + diff_image.*Jyx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdy_phi + diff_image.*Jyy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdy_phi + diff_image.*Jyz_phi.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdy_phi + diff_image.*Jyx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdy_phi + diff_image.*Jyy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdy_phi + diff_image.*Jyz_phi.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdy_phi + diff_image.*Jyx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdy_phi + diff_image.*Jyy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdy_phi + diff_image.*Jyz_phi.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi + diff_image.*Jyx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi + diff_image.*Jyy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi + diff_image.*Jyz_phi))))];

H(12,:) = [-2*(sum(sum(sum(-dJdx_phi.*p.*dJdz_phi + diff_image.*Jzx_phi.*p)))),...
    -2*(sum(sum(sum(-dJdy_phi.*p.*dJdz_phi + diff_image.*Jzy_phi.*p)))),...
    -2*(sum(sum(sum(-dJdz_phi.*p.*dJdz_phi + diff_image.*Jzz_phi.*p)))),...
    -2*(sum(sum(sum(-dJdx_phi.*q.*dJdz_phi + diff_image.*Jzx_phi.*q)))),...
    -2*(sum(sum(sum(-dJdy_phi.*q.*dJdz_phi + diff_image.*Jzy_phi.*q)))),...
    -2*(sum(sum(sum(-dJdz_phi.*q.*dJdz_phi + diff_image.*Jzz_phi.*q)))),...
    -2*(sum(sum(sum(-dJdx_phi.*r.*dJdz_phi + diff_image.*Jzx_phi.*r)))),...
    -2*(sum(sum(sum(-dJdy_phi.*r.*dJdz_phi + diff_image.*Jzy_phi.*r)))),...
    -2*(sum(sum(sum(-dJdz_phi.*r.*dJdz_phi + diff_image.*Jzz_phi.*r)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi + diff_image.*Jzx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi + diff_image.*Jzy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi + diff_image.*Jzz_phi))))];

end