% problem 3.2.2
% Registration to a population-derived template

clear;

% initial test image
[averageimage,spacing] = myReadNifti('sub021_mri.nii');

% Create filename string parts
% base1 = 'sub00';
% base2 = 'sub0';
base = 'sub0';
ending = '_mri.nii';

% Average all test image intensities
for i = 2:20
    % Create filename
    imagenum = num2str(i+20);
    filename = strcat(base,imagenum,ending);
    % Read image
    [currentimage,~] = myReadNifti(filename);
    % Add image to moving average
    totalintensity = averageimage*(i-1);
    averageimage = (totalintensity + currentimage)/i;
end

% Write to file
myWriteNifti('Avgimgtest0_nomultires_mri.nii',averageimage,spacing);

% Create filename string parts
base1 = 'sub00';
base2 = 'sub0';

% Create 20x1 cell arrays
A_cell = cell(20,1);
b_cell = cell(20,1);

% Create 20x1 cell arrays
image_cell = cell(20,1);

% Populate training image cells
for i = 1:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image and store in cell
    [image_cell{i},~] = myReadNifti(filename);
end

% Definte iteration vector and smoothing factor
iter = [5, 0, 0];
sigma = 1;
% Initialize evaluation vector
meanovl = zeros(5,1);
path = 'F:\Class Stuff\Biomed Image Analysis\Grand Assignment\train';

% Iterate 5 times
for counts = 1:5
    % Gaussian LPF
    sigma = 1;
    smoothedimage1 = myGaussianLPF(averageimage,2*sigma);
    smoothedimage2 = myGaussianLPF(image_cell{1},2*sigma);

    % subsample images in each dimension by 2
    subsamp1 = smoothedimage1(1:2:end,1:2:end,1:2:end);
    subsamp2 = smoothedimage2(1:2:end,1:2:end,1:2:end);

    % Create a struct object for storing gradient of moving image
    g_struct = struct('dy',{},'dx',{},'dz',{});

    % compute gradient of moving image
    [g_struct(1).dy, g_struct(1).dx, g_struct(1).dz] = gradient(subsamp2);

    % Set options for optimization
    options = optimset('GradObj','on','Hessian','on','Display','iter','MaxIter',50);
    % options = optimset('GradObj','on','Display','iter','MaxIter',50);

    % Run optimization
    pstart = [1,0,0,0,1,0,0,0,1,0,0,0]';
    [p,fval] = fminunc(@(x)(myAffineObjective3DwithHessian(x, subsamp1, subsamp2, g_struct(1).dy, g_struct(1).dx, g_struct(1).dz)), pstart, options);
    A = reshape(p(1:9),[3,3]);
    b = p(10:12);
    
    newaverage = myTransformImage(averageimage, image_cell{1}, A, b, 'linear');
    A_cell{1} = A;
    b_cell{1} = b;
    % Register each image to current average
    for i = 2:20
        % Perform registration and transformation
        % Gaussian LPF
        sigma = 1;
        smoothedimage1 = myGaussianLPF(averageimage,2*sigma);
        smoothedimage2 = myGaussianLPF(image_cell{i},2*sigma);

        % subsample images in each dimension by 2
        subsamp1 = smoothedimage1(1:2:end,1:2:end,1:2:end);
        subsamp2 = smoothedimage2(1:2:end,1:2:end,1:2:end);

        % Create a struct object for storing gradient of moving image
        g_struct = struct('dy',{},'dx',{},'dz',{});

        % compute gradient of moving image
        [g_struct(1).dy, g_struct(1).dx, g_struct(1).dz] = gradient(subsamp2);

        % Set options for optimization
        options = optimset('GradObj','on','Hessian','on','Display','iter','MaxIter',50);
        % options = optimset('GradObj','on','Display','iter','MaxIter',50);

        % Run optimization
        pstart = [1,0,0,0,1,0,0,0,1,0,0,0]';
        [p,fval] = fminunc(@(x)(myAffineObjective3DwithHessian(x, subsamp1, subsamp2, g_struct(1).dy, g_struct(1).dx, g_struct(1).dz)), pstart, options);
        A = reshape(p(1:9),[3,3]);
        b = p(10:12);
        
        transformedimage = myTransformImage(averageimage, image_cell{i}, A, b, 'linear');
        A_cell{i} = A;
        b_cell{i} = b;
        
        % Add to moving average
        totalintensity = newaverage*(i-1);
        newaverage = (totalintensity + transformedimage)/i;
    end
    
    % Evaluate performance
    meanovl(counts) = evaluateOnTrainingSet(path, A_cell, b_cell);
       
    % Write averageimage(counts) to file
    start = 'Avgimgtest';
    ending = '_nomultires_mri.nii';
    filename = strcat(start,num2str(counts),ending);
    myWriteNifti(filename,newaverage,spacing);
    
    averageimage = newaverage;
end
