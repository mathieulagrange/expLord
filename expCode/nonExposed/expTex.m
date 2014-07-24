function config = expTex(config, command)

if ~exist('command', 'var'), command= 'cv'; end

latexPath = [config.reportPath 'tex/'];
if ~exist(latexPath, 'dir')
    mkdir(latexPath);
end

reportName = '';
slides= 0 ;
if ~isempty(config.reportName)
    reportName = [upper(config.reportName(1)), config.reportName(2:end)];
    
    if strfind(lower(config.reportName), 'slides')
        config.latexDocumentClass = 'beamer';
    end
end

config.latexFileName = [latexPath config.projectName reportName]; % '.tex'

% for k=1:length(config.stepName)
%     copyfile([config.codePath config.shortProjectName num2str(k) config.stepName{k} '.m'], [config.reportPath 'tex/' config.shortProjectName num2str(k) config.stepName{k} '.m']);
% end
% copyfile([config.codePath config.shortProjectName 'Init.m'], [config.reportPath 'tex/' config.shortProjectName 'Init.m']);
% copyfile([config.codePath config.shortProjectName 'Report.m'], [config.reportPath 'tex/' config.shortProjectName 'Report.m']);

if ~exist([config.reportPath config.projectName reportName '.tex'], 'file')
    config.latex = LatexCreator([config.reportPath filesep config.projectName reportName '.tex'], 0, config.completeName, [config.projectName ' version ' num2str(config.versionName) '\\ ' config.message], config.projectName, 1, 1, config.latexDocumentClass);
    copyfile([fileparts(mfilename('fullpath')) filesep 'utils/mcode.sty'], config.reportPath);
%     copyfile([fileparts(mfilename('fullpath')) filesep 'utils/tufte-handout.cls'], config.reportPath);
end

% copy any tex related files
files = [dir([config.reportPath, '*tex']); dir([config.reportPath, '*bib']); dir([config.reportPath, '*sty']); dir([config.reportPath, '*cls'])   ];
for k=1:length(files)
    if ~files(k).isdir
        copyfile([config.reportPath files(k).name], [config.reportPath 'tex/']);
    end
end

% copyfile([config.reportPath config.projectName reportName '.tex'], [config.latexFileName '.tex']);
% copyfile([fileparts(mfilename('fullpath')) filesep 'utils/mcode.sty'], [config.reportPath 'tex/']);

config.pdfFileName = [config.reportPath 'reports/' config.projectName '_' reportName '_v' num2str(config.versionName) '_' config.userName  '_' date '_' strrep(config.message, ' ', '-') '.pdf'];

config.latex = LatexCreator([config.latexFileName '.tex'], 1, config.completeName, [config.projectName ' version ' num2str(config.versionName) '\\ ' config.message], config.projectName, 1, 0, config.latexDocumentClass);
config.latex.addLine(''); % mandatory

if config.showFactorsInReport
    pdfFileName = [config.reportPath 'figures/factors.pdf'];
    a=dir(pdfFileName);
    b=dir([config.codePath config.shortProjectName 'Factors.txt']);
    for k=1:length(config.stepName)
        c = dir([config.codePath config.shortProjectName num2str(k) config.stepName{k} '.m']);
        if c.datenum > b.datenum
            b=c;
        end
    end
    if ~exist(pdfFileName, 'file')  || a.datenum < b.datenum
        expFactorDisplay(config, config.showFactorsInReport, config.factorDisplayStyle, ~(abs(config.report)-1), 0);
    end
    
    if slides
        config.latex.addLine('\begin{frame}\frametitle{Factors flow graph}');
    end
    
    config.latex.addLine('\begin{center}');
    config.latex.addLine('\begin{figure}');
    config.latex.addLine(['\includegraphics[width=\textwidth,height=0.8\textheight,keepaspectratio]{../figures/factors.pdf}']);
    config.latex.addLine('\label{factorFlowGraph}');
    if~slides
        config.latex.addLine('\caption{Factors flow graph for the experiment.}');
    end
    config.latex.addLine('\end{figure}');
    config.latex.addLine('\end{center}');
    if slides, config.latex.addLine('\end{frame}');end
end

t=1;
l=1;
for k=config.displayData.style
    if k
        % add table
        config.latex.addTable(config.displayData.table(t).table, 'caption', config.displayData.table(t).caption, 'multipage', config.displayData.table(t).multipage, 'landscape', config.displayData.table(t).landscape, 'label', config.displayData.table(t).label, 'fontSize', config.displayData.table(t).fontSize, 'nbFactors', config.displayData.table(t).nbFactors);
        if ~mod(t, 10)
            config.latex.addLine('\clearpage');
        end
        t=t+1;
    else
        % add figure
        % for k=1:length(config.displayData.figure)
        if config.displayData.figure(l).taken && config.displayData.figure(l).report
            config.latex.addFigure(config.displayData.figure(l).handle, 'caption', config.displayData.figure(l).caption, 'label', config.displayData.figure(l).label);
            if ~mod(l, 10)
                config.latex.addLine('\clearpage');
            end
        end
        l=l+1;
    end
end



data = config.displayData; %#ok<NASGU>
save(strrep(config.pdfFileName, '.pdf', '.mat'), 'data');

for k=1:length(command)
    switch command(k)
        case 'c'
            oldFolder = cd(latexPath);
            disp('generating latex report. Press x enter if locked for too long (use report with ''d'' option for debug info)');
            if strfind(config.report, 'd')
                silent = 0;
            else
                silent = 1;
            end
            res = config.latex.createPDF(silent);
            cd(oldFolder);
            if ~res
                copyfile([config.latexFileName '.pdf'], config.pdfFileName);
                disp(['report available: ', config.pdfFileName])
            else
                return
            end
        case 'v'
            expShowPdf(config, config.pdfFileName);
    end
end

if config.deleteTexDirectory
    warning off
    rmdir(latexPath, 's');
    mkdir(latexPath);
    warning on
end


