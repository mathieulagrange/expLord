function config=exposeBar(config, data, p)

config = expDisplay(config, p);
if strcmpi(p.orientation(1), 'v')
    barCommand = 'bar';
else
    barCommand = 'barh';
end
if ~isempty(p.add)
    feval(barCommand, data.meanData, p.add{:});
else
    feval(barCommand, data.meanData);
end

expSetAxes(config, data, p)