function expDisplayFactors(config, silent, show)

if ~exist('silent', 'var'), silent=1; end
if ~exist('show', 'var'), show=0; end

p = fileparts(mfilename('fullpath'));

latexPath = [config.reportPath 'tex/'];
if ~exist(latexPath, 'dir')
    mkdir(latexPath);
end

texFileName = [latexPath config.shortProjectName 'Factors.tex'];
pdfFileName = [config.reportPath 'figures/' config.shortProjectName 'Factors.pdf'];

copyfile([p '/nonExposed/utils/headerFactorDisplay.tex'], texFileName);

% all steps
allIndex = cellfun(@isempty, config.factors.step);
allfactorIndex = config.factors.names(allIndex);

functionCell = displayNode(config, allIndex);

% steps
for k=1:length(config.stepName)
    stepIndex = allIndex == 0;
    mask = cell(1, size(config.factors.values, 2));
    mask(:) = {0};
    mask = expSettingStep(config.factors, mask, k);
    stepIndex([mask{:}]==-1) = 0;
    stepCell = displayNode(config, stepIndex, k) ;
    functionCell = [functionCell; stepCell];
end
% arrows
for k=1:length(config.stepName)-1
    functionCell{end+1} = ['\draw[stepArrow] (' num2str(k) '.east) -- (' num2str(k+1) '.west);'];
end

% footer
functionCell = [functionCell;...
    '\end{tikzpicture}'; ...
    '\end{center}'; ...
    '\end{document}]'; ...
    ];

silentString = '';
if silent
    silentString = ' >/dev/null';
end

functionString = char(functionCell);

dlmwrite(texFileName, functionString,'delimiter','', '-append');

oldFolder = cd(latexPath);
disp('generating latex figure. Press x enter if locked for too long');
res = system(['pdflatex ' texFileName silentString]); % 
cd(oldFolder);
if ~res
    copyfile([texFileName(1:end-4) '.pdf'], pdfFileName);
    disp(['figure available: ', pdfFileName])
else
    return
end
if show
if ~isempty(config.pdfViewer)
    cmd=[config.pdfViewer ' ', pdfFileName, ' &'];
else
    if ismac
        cmd=['open -a Preview ', pdfFileName, ' &'];
    else
        open(pdfFileName);
        return;
    end
end
system(cmd);
end

function functionCell = displayNode(config, factorIndex, stepId)

if ~exist('stepId', 'var')
    stepId = 0;
    location = '';
    stepName = 'All steps';
else
    location = [', right=of ' num2str(stepId-1)];
    stepName = config.stepName{stepId};
end

functionCell={...
    ['\node (' num2str(stepId) ') [stepBlock' location ']'];...
    ['{\textbf{' stepName '}'];...
    '\nodepart{two}\tabular{@{}l}  ', ...
    };

for k=1:length(factorIndex)
    if factorIndex(k) && length(config.factors.values{k}) > 1
        if strcmp(config.factors.sequentialFactor, config.factors.names{k})
            seq = '(s)';
        else
            seq = '';
        end
            
        functionCell{end+1} = ['\texttt{' config.factors.names{k} '} ' seq '\\'];
    end
end
functionCell{end+1} = '\endtabular';
functionCell{end+1} = ' ';
functionCell{end+1} = '\nodepart{three}\tabular{@{}l}  ';
for k=1:length(factorIndex)
    if factorIndex(k) && length(config.factors.values{k}) == 1
        functionCell{end+1} = ['\texttt{' config.factors.names{k} '} = ' config.factors.stringValues{k}{1} '\\'];
    end
end
functionCell{end+1} = '\endtabular};';

