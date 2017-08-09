function seed(new_seed)
% SEED Set new seed for function RANDOM0
% Function SEED sets a new seed for function RANDOM0. The new seek should
% be a positive integer.
% Define variables:
% ISEED             --Random number seed(gloable)
% new_seed          --New seed

% Declare global values
global ISEED  % seed for random number generator
% Check for a legal number of input arguments
msg = nargchk(1,1,nargin);
error(msg);
new_seek = round(new_seed);
ISEED = abs(new_seed);