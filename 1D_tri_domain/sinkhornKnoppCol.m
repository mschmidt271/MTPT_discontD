% This function has been modified by Michael Schmidt to normalize the
% columns last, meaning that the matrix will be closer to a left stochastic
% matrix than a right one. Minor alterations were also made to keep the
% matrix sparse, with the goal of speedup.

function [A, r, c] = sinkhornKnoppCol(A, varargin)
%SINKHORNKNOPP normalises a matrix to be doubly stochastic
%   M = SINKHORNKNOPP(A) takes a nonnegative NxN matrix A and normalises it
%   so that the sum of each row and the sum of each column is unity. M is
%   equal to DAE where D and E are diagonal matrices with positive values
%   on the diagonal.
% 
%   M = SINKHORNKNOPP(A, NAME1, VALUE1, ...) allows other parameters to be
%   set. These are:
% 
%       'Tolerance' - a positive scalar, default EPS(N). The value is the
%       maximum error in the column sums of M; the row sums will be correct
%       to within rounding error.
% 
%       'MaxIter' - a positive integer, default Inf. The maximum number of
%       iterations to carry out.
% 
%   [M, R, C] = SINKHORNKNOPP(...) also returns normalising vectors R and C
%   such that M = diag(R) * A * diag(C) to within a small tolerance.
% 
%   Example
%   -------
% 
%       a = toeplitz(1:6);
%       m = sinkhornKnopp(a);
%       disp('a'); disp(a);
%       disp('m'); disp(m);
%       disp('Row and column sums'); disp(sum(m,1)); disp(sum(m,2));
% 
%   Convergence
%   -----------
% 
%   The algorithm will converge for positive matrices, but may not converge
%   if there are too many zeros in A, depending on their distribution. In
%   such cases it may be necessary to set 'MaxIter' and to check the column
%   sums of M. For some applications adding a small constant to A is
%   recommended.
%
%   Algorithm
%   ---------
% 
%   The Sinkhorn-Knopp algorithm, also known as the RAS method and
%   Bregman's balancing method, is used. The code is modified from Knight
%   (2008), avoiding the matrix transpose.
%
%   Reference
%   ---------
%
%   Philip A. Knight (2008) The Sinkhorn�Knopp Algorithm: Convergence and
%   Applications. SIAM Journal on Matrix Analysis and Applications 30(1),
%   261-275. doi: 10.1137/060659624

% Copyright David Young 2015

% Input parameter parsing and checking
validateattributes(A, {'numeric'}, {'nonnegative' 'square'});
N = size(A, 1);

inp = inputParser;
inp.addParameter('Tolerance', eps(N), ...
    @(x) validateattributes(x, {'numeric'}, {'positive' 'scalar'}));
inp.addParameter('MaxIter', Inf, @(x) ...
    checkattributes(x, {'numeric'}, {'positive' 'integer' 'scalar'}) ...
    || (isinf(x) && isscalar(x) && x > 0));
inp.parse(varargin{:});
tol = inp.Results.Tolerance;
maxiter = inp.Results.MaxIter;

% first iteration - no test
iter = 1;
% c = 1./sum(A);
% r = 1./(A * c.');

r = 1 ./ sum(A, 2);
c = 1 ./ (r.' * A);

% subsequent iterations include test
while iter < maxiter
    iter = iter + 1;
    
%     cinv = r.' * A;
    rinv = A * c.';
    % test whether the tolerance was achieved on the last iteration
    if  max(abs(rinv' .* c - 1)) <= tol
        break
    end
%     c = 1./cinv;
%     r = 1./(A * c.');
    r = 1 ./ rinv;
    c = 1 ./ (r.' * A);
end
% A = A .* (r * c);

% This way maintains sparseness
A = A .* r;
A = A .* c;


end
