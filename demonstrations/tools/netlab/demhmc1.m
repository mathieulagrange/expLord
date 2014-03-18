%DEMHMC1 Demonstrate Hybrid Monte Carlo sampling on mixture of two Gaussians.
%
%	Description
%	The problem consists of generating data from a mixture of two
%	Gaussians in two dimensions using a hybrid Monte Carlo algorithm with
%	persistence. A mixture settingl is then fitted to the sample to compare
%	it with the  true underlying generator.
%
%	See also
%	DEMHMC3, HMC, DEMPOT, DEMGPOT
%

%	Copyright (c) Ian T Nabney (1996-2001)


dim = 2;            	% Data dimension
ncentres = 2;		% Number of centres in mixture settingl

seed = 42;              % Seed for random weight initialization.
randn('state', seed);
rand('state', seed);

clc
disp('This demonstration illustrates the use of the hybrid Monte Carlo')
disp('algorithm to sample from a mixture of two Gaussians.')
disp('The means of the two components are [0 0] and [2 2].')
disp(' ')
disp('First we set up the parameters of the mixture settingl we are sampling')
disp('from.')
disp(' ')
disp('Press any key to continue.')
pause

% Set up mixture settingl to sample from
mix = gmm(dim, ncentres, 'spherical');
mix.centres(1, :) = [0 0];
mix.centres(2, :) = [2 2];
x = [0 1];  % Start vector

% Set up vector of options for hybrid Monte Carlo.

nsamples = 160;		% Number of retained samples.

options = foptions;     % Default options vector.
options(1) = 1;		% Switch on diagnostics.
options(5) = 1;		% Use persistence
options(7) = 50;	% Number of steps in trajectory.
options(14) = nsamples;	% Number of Monte Carlo samples returned. 
options(15) = 30;	% Number of samples omitted at start of chain.
options(18) = 0.02;

clc
disp(['Next we take ', num2str(nsamples),' samples from the distribution.'...
    , 'The first ', num2str(options(15))])
disp('samples at the start of the chain are omitted.  As persistence')
disp('is used, the momentum has a small random component added at each step.')
disp([num2str(options(7)), ...
    ' iterations are used at each step and the step size is ',...
    num2str(options(18))])
disp('Sampling starts at the point [0 1].')
disp('The new state is accepted if the threshold value is greater than')
disp('a random number between 0 and 1.')
disp(' ')
disp('Negative step numbers indicate samples discarded from the start of the')
disp('chain.')
disp(' ')
disp('Press any key to continue.')
pause

[samples, energies] = hmc('dempot', x, options, 'demgpot', mix);

disp(' ')
disp('Press any key to continue.')
pause
clc
disp('The plot shows the samples generated by the HMC function.')
disp('The different colours are used to show how the samples move from')
disp('one component to the other over time.')
disp(' ')
disp('Press any key to continue.')
pause
probs = exp(-energies);
fh1 = figure;
% Plot data in 4 groups
ngroups = 4;
g1end = floor(nsamples/ngroups);
g2end = floor(2*nsamples/ngroups);
g3end = floor(3*nsamples/ngroups);
p1 = plot(samples(1:g1end,1), samples(1:g1end,2), 'k.', 'MarkerSize', 12);
hold on
lstrings = char(['Samples 1-' int2str(g1end)], ...
  ['Samples ' int2str(g1end+1) '-' int2str(g2end)], ...
  ['Samples ' int2str(g2end+1) '-' int2str(g3end)], ...
  ['Samples ' int2str(g3end+1) '-' int2str(nsamples)]);
p2 = plot(samples(g1end+1:g2end,1), samples(g1end+1:g2end,2), ...
  'r.', 'MarkerSize', 12);
p3 = plot(samples(g2end+1:g3end,1), samples(g2end+1:g3end,2), ...
  'g.', 'MarkerSize', 12);
p4 = plot(samples(g3end+1:nsamples,1), samples(g3end+1:nsamples,2), ...
  'b.', 'MarkerSize', 12);
legend([p1 p2 p3 p4], lstrings, 2);

clc
disp('We now fit a Gaussian mixture settingl to the sampled data.')
disp('The settingl has spherical covariance structure and the correct')
disp('number of components.')
disp(' ')
disp('Press any key to continue.')
pause
% Fit a mixture settingl to the sample
newmix = gmm(dim, ncentres, 'spherical');
options = foptions;
options(1) = -1;	% Switch off all diagnostics
options(14) = 5;	% Just use 5 iterations of k-means in initialisation
% Initialise the settingl parameters from the samples
newmix = gmminit(newmix, samples, options);

% Set up vector of options for EM trainer
options = zeros(1, 18);
options(1)  = 1;		% Prints out error values.
options(14) = 15;		% Max. Number of iterations.

disp('We now train the settingl using the EM algorithm for 15 iterations')
disp(' ')
disp('Press any key to continue')
pause
[newmix, options, errlog] = gmmem(newmix, samples, options);

% Print out settingl
disp(' ')
disp('The trained settingl has parameters ')
disp('    Priors        Centres         Variances')
disp([newmix.priors' newmix.centres newmix.covars'])
disp('Note the close correspondence between these parameters and those')
disp('of the distribution used to generate the data')
disp(' ')
disp('    Priors        Centres         Variances')
disp([mix.priors' mix.centres mix.covars'])
disp(' ')
disp('Press any key to exit')
pause

close(fh1);
clear all;

