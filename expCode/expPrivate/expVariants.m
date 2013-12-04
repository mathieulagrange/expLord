function taskVariant = expVariants(vSpec, mask, currentTask)

vSet = expVariantSet(vSpec, mask, currentTask);

variants = expVariantBuild(vSpec, vSet);

sequence = expVariantSequence(vSpec, vSet);

e=[];
for k=1:size(vSet, 1)
    for m=1:size(vSet, 2)
        if vSet(k, m)
            list{k, m} = vSpec.stringValues{k}{vSet(k, m)};
        else
            list{k, m} = '';
        end
    end
    if ~all(cellfun(@isempty,list(k, :)))
        e(end+1) = k;
    end
    values{k} = unique(list(k, :));
    values{k}(cellfun(@isempty,values{k}))=[];
end

parameters.list = list(e, :)';
parameters.names = vSpec.names(e);
parameters.values = values(e);

taskVariant.variants = variants;
taskVariant.sequence = sequence;
taskVariant.parameters = parameters;
taskVariant.set = vSet;
taskVariant.id = currentTask;


