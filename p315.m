% problem 3.1.5
% Multi-resolution affine registration

clear;

% load images
[image1,spacing] = myReadNifti('sub001_mri.nii');
[image2,spacing2] = myReadNifti('sub003_mri.nii');

% Perform registration
iter = [20,10,5];
sigma = 1;
[A,b] = myAffineRegMultiRes3D(image1,image2,iter,sigma);

% output original results
Aorig = eye(3,3);
borig = zeros(3,1);
myViewAffineReg(image1,image2,spacing,Aorig,borig);

% output optimal results
myViewAffineReg(image1,image2,spacing,A,b);
