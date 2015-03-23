function filtered = myMeanLPF(image, radius)

% Compute the kernel
w = 2 * radius + 1;
K = ones(w,w,w) / w^3;

% Compute the result
filtered = imfilter3d(image, K);
