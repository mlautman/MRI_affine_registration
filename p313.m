
% 3.1.3 Testing the Correctness of Gradient Computation
[image1,spacing] = myReadNifti('sub001_mri.nii');
[image2,spacing2] = myReadNifti('sub002_mri.nii');
p = [1,0,0,0,1,0,0,0,1,0,0,0]';

% Gaussian LPF
sigma = 1;
smoothedimage1 = myGaussianLPF(image1,sigma);
smoothedimage2 = myGaussianLPF(image2,sigma);

% analytical gradient
[E,g] = myAffineObjective3D(p,smoothedimage1,smoothedimage2);

% numerical gradient
epsilon = 1e-4;
gnumer = ones(12,1);

for j = 1:12
    % Create ej vector
    ej = zeros(12,1);
    ej(j) = 1;

    % Add/subtract ej*epsilon vector to p
    pup = p + ones(12,1).*ej*epsilon;
    pdown = p - ones(12,1).*ej*epsilon;
    
    % Compute E terms for numerical gradient approximation
    [Eup,~] = myAffineObjective3D(pup,smoothedimage1,smoothedimage2);
    [Edown,~] = myAffineObjective3D(pdown,smoothedimage1,smoothedimage2);
    
    % Compute dE/dpj
    gnumer(j) = (Eup - Edown)/(2*epsilon);
end

% Compute relative error
diffvector = g - gnumer;
relerr = 100.*(diffvector./g);