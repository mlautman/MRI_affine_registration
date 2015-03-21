
function matched_image = myHistMatch(I,J)

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

% add epsilon to all elements of histograms to make cdf monotically
% increasing
hist_I = hist_I + eps(sum(hist_I));
hist_J = hist_J + eps(sum(hist_J));

% compute cdf of fixed and moving image
cdf_I = cumsum(hist_I)/sum(hist_I);
cdf_J = cumsum(hist_J)/sum(hist_J);

% compute inverse cdf of moving image to create lookup table
invcdf_J = interp1(cdf_I,0:1:1024,cdf_J,'linear',0);

% create matched image volume
matched_image = zeros(size(J));

% update pixel values
for i = 0:1024
    matched_image(J>=i & J<i+1) = invcdf_J(i+1);
end

end