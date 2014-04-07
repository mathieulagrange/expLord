function config = exposeLinePlot(config, data, p)

config = expDisplay(config, p);
set(gca, 'ColorOrder', varycolor(size(data.meanData, 1)));
hold on
if ~isempty(p.add)
    plot(data.meanData','linewidth', 1.1, p.add{:}); % TODO xAxis,  
else
    plot(data.meanData','linewidth', 1.1); % TODO xAxis,
end
set(gca,'xtick', 1:length(p.legendNames));
set(gca, 'xticklabel', p.legendNames);
set(gca, 'fontsize', config.displayFontSize);
if p.legend ~= 0
    if ischar(p.legend)
        legend(p.labels(data.selector), 'Location', p.legend);
    else
        legend(p.labels(data.selector));
    end
end
% title(p.title);
xlabel(p.xName);
ylabel(p.methodLabel);
axis tight