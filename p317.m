% problem 3.1.7
% Generate baseline groupwise registration

clear;

% test image
[fixed,spacing] = myReadNifti('sub021_mri.nii');

% Create 20x1 cell arrays
A_cell = cell(20,1);
b_cell = cell(20,1);

% Create filename string parts
base1 = 'sub00';
base2 = 'sub0';
ending = '_mri.nii';

% Definte iteration vector and smoothing factor
iter = [20, 10, 5];
sigma = 1;

% Populate cell arrays
for i = 1:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image and perform registration
    [moving,~] = myReadNifti(filename);
    [A_cell{i}, b_cell{i}] = myAffineRegMultiRes3D(fixed,moving,iter,sigma);
end

% Evaluate performance
path = 'F:\Class Stuff\Biomed Image Analysis\Grand Assignment\train';
meanovl = evaluateOnTrainingSet(path, A_cell, b_cell);
