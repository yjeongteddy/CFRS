function fnames = mapFoldersToFields(folderNames, codes, prefix)
% mapFoldersToFields  Generate valid MATLAB fieldnames from folder names
%
%   fnames = mapFoldersToFields(folderNames, codes, prefix)
%
%   Inputs:
%     folderNames : cell‑array of strings, e.g. {'2.03','2.03+10','2.03-10', ...}
%     codes       : cell‑array of chars, one per unique base value,
%                   e.g. {'H','P'} if your two bases are coded H and P.
%     prefix      : (optional) char, default 'M'
%
%   Output:
%     fnames      : cell‑array of generated field names, same size as folderNames
%
%   Example:
%     folders  = {'2.03','2.03+10','2.03-10','2.62','2.62+10','2.62-10'};
%     codes    = {'H','P'};
%     fnames   = mapFoldersToFields(folders,codes);
%     % fnames = {'MH0','MHP','MHN','MP0','MPP','MPN'}
    
if nargin < 2 || isempty(codes),  codes = {'H', 'P'}; end
if nargin < 3 || isempty(prefix), prefix = 'M'; end

% 1) Extract the numeric “base” (everything up to but not including +10 or -10)
n = numel(folderNames);
baseVals = zeros(n,1);
for i = 1:n
    % match leading number with optional decimal
    tok = regexp(folderNames{i}, '^([0-9]+(?:\.[0-9]+)?)', 'tokens', 'once');
    if isempty(tok)
        error('Cannot parse base numeric value from "%s".', folderNames{i});
    end
    baseVals(i) = str2double(tok{1});
end

% 2) Identify unique bases (sorted ascending)
[uniqBases, ~, idxBase] = unique(baseVals);
nBases = numel(uniqBases);
if nBases ~= numel(codes)
    error('You supplied %d codes but there are %d unique bases.', numel(codes), nBases);
end

% 3) Build the field names
fnames = cell(size(folderNames));
for i = 1:n
    % pick your code letter for this base
    codeLetter = codes{ idxBase(i) };
    % decide the suffix
    if contains(folderNames{i}, '+10')
        suffix = 'P';
    elseif contains(folderNames{i}, '-10')
        suffix = 'N';
    else
        suffix = '0';
    end
    fnames{i} = [ prefix codeLetter suffix ];
end
end
