
% 3.2.3 Groupwise Registration with template mask
clear;

% Create a 20x1 cell array for A, b
A_cell = cell(20,1);
b_cell = cell(20,1);

% Read fixed image
[I,~] = myReadNifti('sub030_mri.nii');

% Read average mask
[seg,~] = myReadNifti('Avgsegtest0_mri.nii');

% Define iter and sigma
iter = 50;
sigma = 1;

% Populate gradient of images and cell array
for i = 1:20
    % Read moving image
    if i < 10
        [J,~] = myReadNifti(sprintf('sub00%d_mri.nii',i));
    else
        [J,~] = myReadNifti(sprintf('sub0%d_mri.nii',i));
    end
    
    [A_cell{i}, b_cell{i}] = myAffineRegMultiRes3DwithMask(I,J,seg,iter,sigma);
end

% Compute overlap

if isunix()
    path = strcat(pwd,'/train');
else
    path = strcat(pwd,'\train');
end
meanovl = evaluateOnTrainingSet(path, A_cell, b_cell);
