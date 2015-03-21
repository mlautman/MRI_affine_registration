
function matched_image = myHistMatch2(I,J)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function for histogram matching  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - I,J                                                          %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - matched_image                                               %%
%% matched_image - moving image matched to fixed image                   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% histogram of fixed and moving image
hist_I = hist(I(:),0:1:1024);
hist_J = hist(J(:),0:1:1024);

% compute cdf of fixed and moving image
cdf_I = cumsum(hist_I)/sum(hist_I);
cdf_J = cumsum(hist_J)/sum(hist_J);

% compute inverse cdf of moving image to create lookup table
curr_idx = 1;
invcdf_J = zeros(size(cdf_J));

for i=1:1:1025
    if i > 2
        invcdf_J(i) = invcdf_J(i-1);
    end
    while cdf_I(curr_idx) < cdf_J(i)
        curr_idx = curr_idx + 1;
        if (cdf_I(curr_idx) - cdf_J(i)) < (cdf_J(i) - cdf_I(curr_idx - 1))
            invcdf_J(i) = curr_idx;
        else
            invcdf_J(i) = curr_idx - 1;
        end
    end
end

% create matched image volume
matched_image = zeros(size(J));

% update pixel values
for i = 0:1024
    matched_image(J>=i & J<i+1) = invcdf_J(i+1);
end

end