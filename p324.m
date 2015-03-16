
% 3.2.4 Testing the Correctness of Hessian Computation
clear;

[image1,spacing] = myReadNifti('sub001_mri.nii');
[image2,spacing2] = myReadNifti('sub002_mri.nii');
p = [1,0,0,0,1,0,0,0,1,0,0,0]';

% Gaussian LPF
sigma = 1;
smoothedimage1 = myGaussianLPF(image1,sigma);
smoothedimage2 = myGaussianLPF(image2,sigma);

% analytical Hessian
[~,~,H] = myAffineObjective3DwithHessian(p,smoothedimage1,smoothedimage2);

% numerical Hessian
epsilon = 1e-4;
Hnumer = ones(12,12);

for j = 1:12
    % Create ej vector
    ej = zeros(12,1);
    ej(j) = 1;

    % Add/subtract ej*epsilon vector to p
    pup = p + ones(12,1).*ej*epsilon;
    pdown = p - ones(12,1).*ej*epsilon;
    
    % Compute g terms for numerical Hessian approximation
    [~,gup] = myAffineObjective3D(pup,smoothedimage1,smoothedimage2);
    [~,gdown] = myAffineObjective3D(pdown,smoothedimage1,smoothedimage2);
    
    % Compute dg/dpj
    Hnumer(:,j) = (gup - gdown)./(2*epsilon);
end

% Compute relative error
diffvector = H - Hnumer;
relerr = 100.*(diffvector./H);