%% problem 3.1.4
% Minimizing the objective function and displaying resulting registration

clear;

% load images
[image1,spacing1] = myReadNifti('sub001_mri.nii');
[image2,spacing2] = myReadNifti('sub003_mri.nii');

% Gaussian LPF
sigma = 1;
smoothedimage1 = myGaussianLPF(image1,2*sigma);
smoothedimage2 = myGaussianLPF(image2,2*sigma);

% subsample images in each dimension by 2
subsamp1 = smoothedimage1(1:2:end,1:2:end,1:2:end);
subsamp2 = smoothedimage2(1:2:end,1:2:end,1:2:end);

% Create a struct object for storing gradient of moving image
g_struct = struct('dy',{},'dx',{},'dz',{});

% compute gradient of moving image
[g_struct(1).dy, g_struct(1).dx, g_struct(1).dz] = gradient(subsamp2);

% Set options for optimization
% OPT1 HESSIAN
options = optimset(...
    'GradObj','on','Hessian','on','Display','iter','MaxIter', 50);

% OPT 2 BASE
% options = optimset(...
%     'GradObj','on','Display','iter','MaxIter',50);

% Run optimization
pstart = [1,0,0,0,1,0,0,0,1,0,0,0]';

% OPT1 Hessian and precomputed gradient 
[p,fval] = fminunc(@(x)(...
    myAffineObjective3DwithHessian(...
        x, subsamp1, subsamp2, ...
        g_struct(1).dy, g_struct(1).dx, g_struct(1).dz ...
    )), pstart, options);

% OPT2 Precomputed Gradient 
% [p,fval] = fminunc(@(x)(...
%     myAffineObjective3D(x, subsamp1, subsamp2, ...
%       g_struct(1).dy, g_struct(1).dx, g_struct(1).dz) ...
%     ), pstart, options);

% OPT3 Base
% [p,fval] = fminunc(@(x)(...
%     myAffineObjective3D(x, subsamp1, subsamp2)), pstart, options);

% output original results
Aorig = reshape(pstart(1:9),[3,3]);
borig = pstart(10:12);
myViewAffineReg(subsamp1,subsamp2,spacing1,Aorig,borig);

% output optimal results
A = reshape(p(1:9),[3,3]);
b = p(10:12);
myViewAffineReg(subsamp1,subsamp2,spacing1,A,b);