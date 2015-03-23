function myViewInSNAP(image,spacing)

% Generate temporary filename
fn=sprintf('%s.nii', tempname());

% Save image to temp image
myWriteNifti(fn, double(image), spacing);

% SNAP command
snapcmd='/Applications/ITK-SNAP.app/Contents/MacOS/InsightSNAP';

% Command to execute
cmd=sprintf('%s -g %s&', snapcmd, fn);

% Run command
system(cmd);
