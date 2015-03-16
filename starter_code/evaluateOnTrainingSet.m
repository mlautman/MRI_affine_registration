function meanovl=evaluateOnTrainingSet(path, A_cell, b_cell)

% Load all the meshes
n = 20;

% Averate RMS distance between meshes for both ROIs
meanovl = 0;

% Array of segmentations
S = cell(n,1);

% Sampling grids for interpolation
px = cell(n,3);

% Subgrid of S
sub = cell(n,1);

% Read the segmentations
for i = 1:n

    % Read the mesh
    file=sprintf('%s/sub%03d_seg.nii', path, i);
    S{i} = myReadNifti(file) > 0;

    % Get the extents of the segmentation
    [sx sy sz] = ind2sub(size(S{i}), find(S{i}));
    xl = min([sx sy sz]);
    xu = max([sx sy sz]);

    % Pad the extents
    xl = max([xl - 5; 0 0 0]);
    xu = min([xu + 5; size(S{i})]);

    % Get the sampling grid for this image
    [px{i,1}, px{i,2}, px{i,3}] = ndgrid(xl(1):xu(1), xl(2):xu(2), xl(3):xu(3));

    % Get the chunk of S
    sub{i} = S{i}(xl(1):xu(1), xl(2):xu(2), xl(3):xu(3));
end

% Compare all pairs of meshes
jac = zeros(n,n);
for i = 1:n
    for j = 1:n
        if i ~= j

            % Bring segmentation of image j into the space of image i
            Ai = A_cell{i}; bi = b_cell{i};
            Aj = A_cell{j}; bj = b_cell{j};

            % This is the transform from i to j
            Q = Aj / Ai; p = bj - Aj * (Ai \ bi);

            % Get the set of coordinates at which to sample the image
            % (want this to run fast, so don't use whole image volume)
            qx = Q(1,1) * px{i,1}(:) + Q(1,2) * px{i,2}(:) + Q(1,3) * px{i,3}(:) + p(1);
            qy = Q(2,1) * px{i,1}(:) + Q(2,2) * px{i,2}(:) + Q(2,3) * px{i,3}(:) + p(2);
            qz = Q(3,1) * px{i,1}(:) + Q(3,2) * px{i,2}(:) + Q(3,3) * px{i,3}(:) + p(3);

            % This is the warped image
            W = interpn(S{j}, qx, qy, qz, 'nearest', 0);

            % This is the target
            T = sub{i}(:);

            % Compute Jaccard index
            jac(i,j) = sum(sum(sum(W & T))) / sum(sum(sum(W | T)));

            % Average Jaccard index
            meanovl = meanovl + jac(i,j) / (n^2 - n);

            fprintf('.');
        end
    end
    fprintf('\n');
end

% Plot the histogram
clf('reset');
hist(jac(find(ones(n)-eye(n))), 0:0.05:1);