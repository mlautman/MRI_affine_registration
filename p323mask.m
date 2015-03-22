% problem 3.2.3
% Generating template mask

clear;

% initial test image
[averageimage,spacing] = myReadNifti('sub001_seg.nii');

% Create filename string parts
base1 = 'sub00';
base2 = 'sub0';
ending = '_seg.nii';

% Average all test image intensities
for i = 2:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image and store in cell array
    currentimage = myReadNifti(filename) > 0;
    totalintensity = averageimage*(i-1);
    averageimage = (totalintensity + currentimage)/i;
end

% Write to file
myWriteNifti('Avgsegtest0_mri.nii',averageimage,spacing);

% Create 20x1 cell arrays
A_cell = cell(20,1);
b_cell = cell(20,1);

% Create 20x1 cell arrays
image_cell = cell(20,1);

% Populate cells from training segmentation data
for i = 1:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image and store in cell
    image_cell{i} = myReadNifti(filename) > 0;
end

% Definte iteration vector and smoothing factor
iter = [20,10,5];
sigma = 1;
% Initialize evaluation vector
meanovl = zeros(5,1);
path = 'D:\Desktop\Documents\Acads - II\Spring 2015\CIS 537\Grand Challenge 1\train';

% Iterate 5 times
for counts = 1:5
    [A, b] = myAffineRegMultiRes3D(averageimage,double(image_cell{1}),iter,sigma);
    newaverage = myTransformImage(averageimage, double(image_cell{1}), A, b, 'linear');
    A_cell{1} = A;
    b_cell{1} = b;
    % Register each image to current average
    for i = 2:20
        % Perform registration and transformation
        [A, b] = myAffineRegMultiRes3D(averageimage,double(image_cell{i}),iter,sigma);
        transformedimage = myTransformImage(averageimage,double(image_cell{i}), A, b, 'linear');
        A_cell{i} = A;
        b_cell{i} = b;
        
        % Add to moving average
        totalintensity = newaverage*(i-1);
        newaverage = (totalintensity + transformedimage)/i;
    end
    
    % Evaluate performance
    meanovl(counts) = evaluateOnTrainingSet(path, A_cell, b_cell);
       
    % Write averageimage(counts) to file
    start = 'Avgsegtest';
    ending = '_mri.nii';
    filename = strcat(start,num2str(counts),ending);
    myWriteNifti(filename,newaverage,spacing);
    
    averageimage = newaverage;
end