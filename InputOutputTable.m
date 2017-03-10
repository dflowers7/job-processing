function tab = InputOutputTable(direc, inputArgNames, outputArgNames, skippedInputArgs, skippedOutputArgs, inputArgFilter, inputargtable, JobFilesOutputs)
% Input arguments
%   skippedInputArgs [ cell vector of strings ]
%   skippedOutputArgs [ cell vector of strings ]
%   inputArgFilter [ struct ]
%       .('argname')
%           Sets the possible values for the input argument argname.
%   JobFilesOutputs
%       Cell array containing the output from the JobFiles function for
%       this directory. If not provided, this function will call JobFiles()
%       itself. If this function is called many times in succession for the
%       same directory, it is faster to provide the JobFile outputs.

if nargin < 8
    JobFilesOutputs = [];
    if nargin < 7
        inputargtable = [];
        if nargin < 6
            inputArgFilter = [];
            if nargin < 5
                skippedOutputArgs = [];
                if nargin < 4
                    skippedInputArgs = [];
                end
            end
        end
    end
end

fprintf('Loading data from %s...\n', direc)

if isempty(JobFilesOutputs)
    [outfiles, outfiles_jis, infiles, infiles_jis, cmdfiles, cmdfiles_jis] = JobFiles(direc);
else
    [outfiles, outfiles_jis, infiles, infiles_jis, cmdfiles, cmdfiles_jis] = deal(JobFilesOutputs{1:6});
end

% Don't use the input argument table if none was provided
inputArgTableProvided = ~isempty(inputargtable);
if inputArgTableProvided
    inputargtable_files = {inputargtable.inputfile}';
    inputargtable_inputs = vertcat(inputargtable.input); % ninfiles-by-nargs cell array
end

infiles_jis_sort = sort(infiles_jis);
tab = repmat(struct, numel(infiles), 1);
jobmatches = true(numel(infiles),1);
for ji = infiles_jis_sort(:)'
    outfile = outfiles{outfiles_jis == ji};
    infile = infiles{infiles_jis == ji};
    cmdfile = cmdfiles{cmdfiles_jis == ji};
    
    % Inputs
    if inputArgTableProvided
        infile_data = inputargtable_inputs(strcmp(inputargtable_files,infile),:);
    else
        infile_data = load(infile);
        infile_data = infile_data.input;
    end
    
    % Check that the number of inputs stored is the same as the number of
    % provided input argument names
    assert(numel(infile_data) == numel(inputArgNames), 'InputOutputTable:InputArgNamesLength', ...
        'The loaded input file stores %g inputs, but %g input argument names were provided.', ...
        numel(infile_data), numel(inputArgNames))
    
    % Check that the input argument values match one of the sets of requested
    % values in inputArgFilter
    ismatch = true;
    if ~isempty(inputArgFilter)
        inputArgFilterNames = fieldnames(inputArgFilter);
        for fili = 1:numel(inputArgFilterNames)
            name_fili = inputArgFilterNames{fili};
            value_fili = {inputArgFilter.(name_fili)};
            [~,inarg_i] = ismember(name_fili, inputArgNames);
            assert(inarg_i > 0, 'InputOutputTable:MissingInputArg', 'Could not find input argument %s specified in inputArgFilter.', name_fili)
            ismatch = ismatch && any(cellfun(@isequal, repmat(infile_data(inarg_i),size(value_fili)), value_fili));
        end
    end
    if ~ismatch
        % If the input arguments don't match, skip to the next job
        jobmatches(ji) = false;
        continue
    end
    
    % Only print the job entry if the job matches, to avoid printing as
    % much to the command window
    fprintf('\tJob %g...\n', ji)
    
    for ini = 1:numel(inputArgNames)
        if ~any(strcmp(inputArgNames{ini},skippedInputArgs))
            tab(ji).(inputArgNames{ini}) = infile_data{ini};
        end
    end
    
    % Outputs
    if ~isempty(outfile)
        outfile_data = load(outfile);
        for outi = 1:numel(outputArgNames)
            if ~any(strcmp(outputArgNames{outi},skippedOutputArgs))
                tab(ji).(outputArgNames{outi}) = outfile_data.out{outi};
            end
        end
    end
    
    tab(ji).cmdfile = cmdfile;
    tab(ji).jobindex = ji;
    tab(ji).directory = direc;
end

tab = tab(jobmatches);

end