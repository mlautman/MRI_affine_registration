function p = my_interp3_precompute(sz, x, y, z)

% This function is used to precompute values for fast 3D interpolation


% This is the index of values where interpolation is inside the target
i = x(:) > 1 & x(:) < sz(1) & ...
    y(:) > 1 & y(:) < sz(2) & ...
    z(:) > 1 & z(:) < sz(3);

% The interpolation factors
fx = floor(x(i));
fy = floor(y(i));
fz = floor(z(i));

dx = x(i) - fx;
dy = y(i) - fy;
dz = z(i) - fz;

% Sparse matrix entries
sj = zeros(sum(i), 8);
sval = zeros(sum(i), 8);

off = [ 0 0 0;
        0 0 1;
        0 1 0;
        1 0 0;
        0 1 1;
        1 0 1;
        1 1 0;
        1 1 1 ];
dsc = (off - 0.5) * 2;
dsh = 1-off;

stride = off * [1; sz(1); sz(1) * sz(2)];

idx = sub2ind(sz,fx, fy, fz);


for j = 1:8

    sj(:,j) = idx + stride(j);

    sval(:,j) = (dx * dsc(j,1) + dsh(j,1)) .* ...
                (dy * dsc(j,2) + dsh(j,2)) .* ...
                (dz * dsc(j,3) + dsh(j,3));

end

siall = 1:length(x(:));
si = repmat(siall(i),1,8);
p.S = sparse(si(:), sj(:), sval(:), length(x(:)), sz(1)*sz(2)*sz(3));
p.dim = size(x);