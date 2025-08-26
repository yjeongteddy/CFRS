function tagMap = generateTags(dirNames)
    % Input: cell array of folder names (e.g., {'2.03', '2.03-10', ...})
    % Output: containers.Map of folder names to tags (e.g., '2.03' -> 'I0T0')

    baseVals = regexp(dirNames, '^[\d.]+', 'match', 'once');
    uniqueBases = unique(baseVals);
    
    sortedBases = sort(str2double(uniqueBases));
    intensityTags = cell(size(sortedBases));
    
    basePrefixes = ["I0", "Ip"];  % Extendable
    for i = 1:min(length(sortedBases), length(basePrefixes))
        intensityTags{i} = basePrefixes(i);
    end
    
    tagMap = containers.Map();

    for i = 1:length(sortedBases)
        base = num2str(sortedBases(i), '%.2f');
        basePattern = ['^' regexptranslate('escape', base)];
        
        matchingDirs = dirNames(~cellfun('isempty', regexp(dirNames, basePattern)));

        for j = 1:length(matchingDirs)
            dname = matchingDirs{j};
            suffix = "T0";
            if contains(dname, '-10')
                suffix = "Tm";
            elseif contains(dname, '+10')
                suffix = "Tp";
            end
            tag = intensityTags{i} + suffix;
            tagMap(dname) = tag;
        end
    end
end
