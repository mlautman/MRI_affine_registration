% problem 3.2.2
% Registration to a population-derived template

clear;

% initial image
[averageimage,~] = myReadNifti('sub001_mri.nii');

% Create filename string parts
base1 = 'sub00';
base2 = 'sub0';
ending = '_mri.nii';

% Create 20x1 cell arrays
image_cell = cell(20,1);

image_cell{1} = averageimage;

% Average all training image intensities
for i = 2:20
    % Create filename
    imagenum = num2str(i);
    if i<10
        filename = strcat(base1,imagenum,ending);
    else
        filename = strcat(base2,imagenum,ending);
    end
    % Read image and store in cell array
    [currentimage,~] = myReadNifti(filename);
    image_cell{i} = currentimage;
    % Add image to moving average
    totalintensity = averageimage*(i-1);
    averageimage = (totalintensity + currentimage)/i;
end

% Iterate 5 times
for counts = 1:5
    % Register each image to current average
    % Initialize A and b
    A = eye(3);
    b = zeros(3,1);

    p = [reshape(A,9,1);b];
    % Gaussian LPF
    sigma = 1;
    smoothedaverage = myGaussianLPF(averageimage,2*sigma);
    subsampavg = smoothedaverage(1:2:end,1:2:end,1:2:end);

    % Create a struct object for storing gradient of moving image
    g_struct = struct('dy',{},'dx',{},'dz',{});
    for i = 1:20
        % Optimize objective function
        currentimage = image_cell{i};
        smoothedcurrent = myGaussianLPF(currentimage,2*sigma);

        % subsample images in each dimension by 2
        subsampcurrent = smoothedcurrent(1:2:end,1:2:end,1:2:end);

        % compute gradient of moving image
        [g_struct(1).dy, g_struct(1).dx, g_struct(1).dz] = gradient(subsampcurrent);

        % Set options for optimization
        options = optimset('GradObj','on','Display','iter','MaxIter',50);

        % Run optimization
        [p,fval] = fminunc(@(x)(myAffineObjective3D(x, subsampavg, subsampcurrent, g_struct(1).dy, g_struct(1).dx, g_struct(1).dz)), p, options);
        A = [p(1:3) p(4:6) p(7:9)];
        b = p(10:12);

        % Register image to average
        image_cell{i} = myTransformImage(averageimage, currentimage, A, b, 'linear');
    end
    
    % Compute new average
    averageimage = image_cell{1};
    for i = 2:20
        currentimage = image_cell{i};
        % Add image to moving average
        totalintensity = averageimage*(i-1);
        averageimage = (totalintensity + currentimage)/i;
    end
    
    % Write averageimage(counts) to file
    start = 'Avgimg';
    ending = '_mri.nii';
    filename = strcat(start,num2str(counts),ending);
    myWriteNifti(filename,averageimage,[80, 96, 80]);
end
