function value=myRMSOverROI(image,seg,label)

idx = (seg == label);
n = sum(idx(:));

value=sqrt(sum(image(idx).^2) / n);