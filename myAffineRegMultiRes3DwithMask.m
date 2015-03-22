
function [A,b] = myAffineRegMultiRes3DwithMask(I,J,seg,iter,sigma)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Objective function for Multi-resolution Affine Registration  %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - I,J,iter,sigma                                               %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%% seg - segmetation of fixed image                                      %%
%% iter - row matrix specifying iterations at each level                 %%
%% sigma - standard deviation of the Gaussian filter                     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - A,b                                                         %%
%% A - 3 x 3 rotation, scaling and shearing matrix                       %%
%% b - 3 x 1 translation matrix                                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of levels
level = length(iter);

% Initialize A and b
A = eye(3);
b = zeros(3,1);

p = [reshape(A,9,1);b];

% Create a struct object for storing gradient of moving image
g_struct = struct('dy',{},'dx',{},'dz',{});

for i = 1:level
    % skip levels with 0 iterations
    if iter(i)>0
        % Gaussian LPF
        coeff = 2^(level-i);
        smoothedI = myGaussianLPF(I,coeff*sigma);
        smoothedJ = myGaussianLPF(J,coeff*sigma);
                
        % subsample images by 2^(level - i)
        subsampI = smoothedI(1:coeff:end,1:coeff:end,1:coeff:end);
        subsampJ = smoothedJ(1:coeff:end,1:coeff:end,1:coeff:end);
        subsampseg = seg(1:coeff:end,1:coeff:end,1:coeff:end);
        
        % compute gradient of moving image
        [g_struct(1).dy, g_struct(1).dx, g_struct(1).dz] = gradient(subsampJ);
        
        % Set options for optimization
        options = optimset('GradObj','on','Hessian','on','Display','iter','MaxIter',iter(i));
        
        % Run optimization
        [p,fval] = fminunc(@(x)(myAffineObjective3DwithMask(x, subsampI, subsampJ, subsampseg)), p, options);
    end
    
    A = [p(1:3) p(4:6) p(7:9)];
    b = p(10:12);
    
    % Update p for next iteration
    p = [reshape(A,9,1);2*b];
end
end
