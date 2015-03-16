function samples = my_interp3(I, p)

samples = reshape(p.S * I(:), p.dim);