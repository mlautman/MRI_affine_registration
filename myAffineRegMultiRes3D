function [A,b] = myAffineRegMultiRes3D(I,J,iter,sigma)
    %Number of levels
    level = length(iter);
    
    %Initialize A and b
    A = zeros(3,3);
    b = zeros(3,1);
    
    for i = 1:level
        %adjust [A,b] for next level
%         A = 
%         b = 
        p = [reshape(A,9,1);b];
        %skip levels with 0 iterations
        if iter(i)>0
            %gaussian LPF
            coeff = 2^(level-i);
            smoothedI = myGaussianLPF(I,coeff*sigma);
            smoothedJ = myGaussianLPF(J,coeff*sigma);

            %subsample images by 2
            subsampI = smoothedI(1:2:end,1:2:end,1:2:end);
            subsampJ = smoothedJ(1:2:end,1:2:end,1:2:end);

            % Set options for optimization
            options = optimset('GradObj','on','Display','iter','MaxIter',iter(i));

            % Run optimization
            [p,fval] = fminunc(@(x)(myAffineObjective3D(x, subsampI, subsampJ)), p, options);
            
            A = [p(1:3) p(4:6) p(7:9)];
            b = p(10:12);
        end
    end
end
