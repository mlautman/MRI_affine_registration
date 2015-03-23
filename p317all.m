% problem 3.1.7, for all test images
% Generate baseline groupwise registration

clear;

% Create filename string parts
base = 'sub0';
ending = '_mri.nii';
fixed_cell = cell(20,1);

% Read all test images
for i = 1:20
    % Create filename
    imagenum = num2str(i+20);
    filename = strcat(base,imagenum,ending);
    % Read image
    [fixed_cell{i},~] = myReadNifti(filename);
end

% Create filename string parts
base1 = 'sub00';
base2 = 'sub0';
ending = '_mri.nii';
moving_cell = cell(20,1);

% Read all training images
for i = 1:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image
    [moving_cell{i},~] = myReadNifti(filename);
end

% Create 20x1 cell arrays
A_cell = cell(20,1);
b_cell = cell(20,1);

% Define iteration vector and smoothing factor
iter = [20, 10, 5];
sigma = 1;


% Evaluate performance
if isunix()
    path = strcat(pwd,'/train');
else
    path = strcat(pwd,'\train');
end

% Loop over each test image
meanovl = zeros(20,1);
for idx = 1:20
    for i = 1:20
        % Perform registration and populate cell arrays
        [A_cell{i}, b_cell{i}] = myAffineRegMultiRes3D(fixed_cell{idx},moving_cell{i},iter,sigma);
    end

    % Evaluate performance
    meanovl(idx) = evaluateOnTrainingSet(path, A_cell, b_cell);
end
