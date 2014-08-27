function expCreate(projectName, stepNames, codePath, dataPath)
% expCreate create an expCode project
%	expCreate(projectName, stepNames, codePath, dataPath)
%	- projectName: name of the project
%	- stepNames: cell array of strings defining the names
%	 of the different processing steps
%	- codePath: path for code storage
%	- dataPath: path for data storage
%
%	Default values and other settings can be set in your configuration file
% 	located in your home in the .expCode directory. This file serves
%	as the initial config file for your expCode projects

%	Copyright (c) 2014 Mathieu Lagrange (mathieu.lagrange@cnrs.fr)
%	See licence.txt for more information.

% TODO remove expPath

expCodePath = fileparts(mfilename('fullpath'));
addpath(genpath(expCodePath));

if ~exist('projectName', 'var')
    projectName = 'helloProject';
elseif ~ischar(projectName)
    error('The projectName must be a string');
end
if ~exist('stepNames', 'var'), stepNames = 'process'; end

if ~iscell(stepNames), stepNames = {stepNames}; end

shortProjectName = names2shortNames(projectName);
shortProjectName = shortProjectName{1};

% load default config

[userDefaultConfigFileName, userDir] = expUserDefaultConfig(expCodePath);

configFile=fopen(userDefaultConfigFileName);
configCell=textscan(configFile,'%s%s', 'CommentStyle', '%', 'delimiter', '=');
fclose(configFile);
names = strtrim(configCell{1});
values = strtrim(configCell{2});

for k=1:length(names)
    if k <= length(values)
        values{k} = strrep(values{k}, '<>', projectName);
        values{k} = strrep(values{k}, '<projectName>', projectName);
        values{k} = strrep(values{k}, '<projectPath>', projectName);
    else
        values{k} = '';
    end
end

config = cell2struct(values, names);
config.projectName = projectName;
config.shortProjectName = shortProjectName;
config.userName = getUserName();
if isempty(config.completeName)
    config.completeName = config.userName;
end
if ~exist('stepNames', 'var')
    stepNames = {};
end
% config.stepName = cell2string(stepNames);

if exist('codePath', 'var')
    if ~isempty(codePath)
        config.codePath = codePath;
    end
end
% TODO pick the first if several by default
if exist('dataPath', 'var')
    if ~isempty(dataPath)
        config.dataPath = dataPath;
    end
end

% config.dataPath = strrep(config.dataPath, '<projectName>', projectName);
% config.codePath = strrep(config.codePath, '<projectName>', projectName);

if isempty(config.dataPath)
    config.dataPath = fullfile(pwd());
elseif ~any(strcmp(config.dataPath(1), {'~', '/', '\'}))
    config.dataPath = fullfile(pwd(), config.dataPath);
end

if ~any(strcmp(config.codePath(1), {'~', '/', '\'}))
    config.codePath = fullfile(pwd(), config.codePath);
end

config.dependencies = [config.dependencies(1:end-1) ' ''' expCodePath '''}']; % TODO zhy (1:find(expCodePath=='/',1,'last'))

% prompt
fprintf('You are about to create an experiment called %s with short name %s and steps: ', projectName, shortProjectName);
disp(stepNames);
fprintf('Path to code %s\nData path: %s\nObservations path: %s\n', config.codePath, config.dataPath, config.obsPath);
disp(['Note: you can set the default values to all configuration parameters in your config file: ' userDir '/' '.expCode' '/' 'defaultConfig.txt']);

if ~inputQuestion(), fprintf(' Bailing out ...\n'); return; end

% create code repository
if exist(config.codePath, 'dir'),
    if ~inputQuestion('Warning: you are about to reinitialize an existing project.\n');
        fprintf('Bailing out \n');
        return;
    else
        rmdir(config.codePath, 's');
    end
end
mkdir(config.codePath);

configPath = [config.codePath '/' 'config' '/'];
mkdir(configPath);

config = orderfields(config);
n = fieldnames(config);
p = find(~cellfun(@isempty, strfind(n, 'Path')));
p = [p; find(~cellfun(@isempty, strfind(n, 'Name')))];
p = [p; setdiff(1:length(n), p)'];
config = orderfields(config, p);

% create config file
fid = fopen([configPath '/' config.shortProjectName 'ConfigDefault.txt'], 'w');
fprintf(fid, '%% Config file for the %s project\n%% Adapt at your convenience\n\n', config.shortProjectName);
configFields = fieldnames(config);
for k=1:length(configFields)
    fprintf(fid, '%s = %s\n', configFields{k}, char(config.(configFields{k})));
end
fclose(fid);

expConfigMerge([configPath '/' config.shortProjectName 'ConfigDefault.txt'], [expCodePath '/expCodeConfig.txt'], 2, 0);
movefile([configPath '/' config.shortProjectName 'ConfigDefault.txt'], [configPath '/' config.shortProjectName 'Config' [upper(config.userName(1)) config.userName(2:end)] '.txt']);

% create factors file
fid = fopen([config.codePath '/' config.shortProjectName 'Factors.txt'], 'w');
fprintf(fid, 'method =1== {''methodOne'', ''methodTwo'', ''methodThree''} % method will be defined for step 1 only \nthreshold =s1:=1/[1 3]= [0:10] % threshold is defined for step 1 and the remaining steps, will be sequenced and valid for the 1st and 3rd value of the 1st factor (methodOne and methodThree) \n\n%% Settings file for the %s project\n%% Adapt at your convenience\n', config.shortProjectName);
fclose(fid);

%create root file
expCreateRootFile(config, projectName, shortProjectName, expCodePath);


%config.latex = LatexCreator([config.codePath '/' config.projectName '.tex'], 0, config.completeName, [config.projectName ' version ' num2str(config.versionName) '\\ ' config.message], projectName, 1, 1);

% create project functions
% TODO add some comments
for k=1:length(stepNames)
    functionName = [shortProjectName num2str(k) stepNames{k}];
    functionString = char({...
        ['function [config, store, obs] = ' functionName '(config, setting, data)'];
        ['% ' functionName ' ' upper(stepNames{k}) ' step of the expCode project ' projectName];
        ['%    [config, store, obs] = ' functionName '(config, setting, data)'];
        '%      - config : expCode configuration state';
        '%      - setting   : set of factors to be evaluated';
        '%      - data   : processing data stored during the previous step';
        '%      -- store  : processing data to be saved for the other steps ';
        '%      -- obs    : observations to be saved for analysis';
        '';
        ['% Copyright: ' config.completeName];
        ['% Date: ' date()];
        '';
        '% Set behavior for debug mode';
        ['if nargin==0, ' , projectName '(''do'', ' num2str(k) ', ''mask'', {}); return; else store=[]; obs=[]; end'];
        });
    dlmwrite([config.codePath '/' functionName '.m'], functionString,'delimiter','');
end


functionName = [shortProjectName 'Init'];
functionString = char({...
    ['function [config, store] = ' shortProjectName 'Init(config)'];
    ['% ' shortProjectName 'Init INITIALIZATION of the expCode project ' projectName];
    ['%    [config, store] = ' functionName '(config)'];
    '%      - config : expCode configuration state';
    '%      -- store  : processing data to be saved for the other steps ';
    '';
    ['% Copyright: ' config.completeName];
    ['% Date: ' date()];
    '';
    ['if nargin==0, ' , projectName '(); return; else store=[];  end'];
    });
dlmwrite([config.codePath '/' functionName '.m'], functionString,'delimiter','');

functionString = char({...
    ['function config = ' shortProjectName 'Report(config)'];
    ['% ' shortProjectName 'Report REPORTING of the expCode project ' projectName];
    ['%    config = ' functionName 'Report(config)'];
    '%       config : expCode configuration state';
    '';
    ['% Copyright: ' config.completeName];
    ['% Date: ' date()];
    '';
    ['if nargin==0, ' , projectName '(''report'', ''r''); return; end'];
    });
dlmwrite([config.codePath '/' shortProjectName 'Report.m'], functionString,'delimiter','');

% create readme file
readmeString = char({['% This is the README for the experiment ' config.projectName]; ''; ['% Created on ' date() ' by ' config.userName]; ''; '% Purpose: '; ''; '% Reference: '; ''; '% Licence: '; ''; ''});
dlmwrite([config.codePath '/README.txt'], readmeString, 'delimiter', '')
% append remaining of the file
dlmwrite([config.codePath '/README.txt'], fileread([expCodePath '/nonExposed/README.txt']), '-append', 'delimiter', '')

runId=1; %#ok<NASGU>
save([configPath config.shortProjectName], 'runId');

% copy depencies if necessary
if str2double(config.localDependencies) >= 1
    config.dependencies = eval(config.dependencies);
    keep =   config.localDependencies;
    config.localDependencies = 2;
    expDependencies(config);
    config.localDependencies = keep;
end

fprintf('Done.\nMoving to project directory.\n')
cd(config.codePath);
