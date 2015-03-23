%% Load some data

% Load images
[Ib sp] = myReadNifti('baseline.nii');
[If sp] = myReadNifti('followup.nii');
[Is sp] = myReadNifti('seg.nii');

% Load the matrix
M = load('-ascii','f2b.txt');
A = M(1:3,1:3);
b = M(1:3,4);

%% Display the baseline image
myView(Ib, sp, [56 100 64]);

%% Test 3D view
myView3D(Ib, sp, [],[],'jet');

%% Experiment with difference images

% Apply some kernel
Gb = myGaussianLPF(Ib, 3);
Gf = myGaussianLPF(If, 3);

% Compute difference image
Diff = Gb - myTransformImage(Gb, Gf, A, b, 'linear');

myView(Diff,sp,[56 100 64],[-50 50],'jet');

print -depsc ../figures/diff_image.eps

%% Plot integrated difference image against sigma of Gaussian kernel

sigma=0.0:0.5:5.0;
for i = 1:length(sigma)
    
    if sigma(i) > 0
        Gb = myGaussianLPF(Ib, sigma(i));
        Gf = myGaussianLPF(If, sigma(i));
    else
        Gb = Ib; Gf = If;
    end

    Diff = Gb - myTransformImage(Ib, Gf, A, b, 'linear*');
    d(i) = myRMSOverROI(Diff, Is, 3);
    fprintf('%f %f\n', sigma(i), d(i));
     
end

plot(sigma,d);
    
    

    

