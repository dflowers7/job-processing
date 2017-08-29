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
                    if nargin < 3
                        outputArgNames = [];
                        if nargin < 2
                            inputArgNames = [];
                        end
                    end
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
    
    isoutfile = outfiles_jis == ji;
    assert(sum(isoutfile)==0||sum(isoutfile)==1, 'InputOutputTable:MultipleMatchingOutputFiles',...
        'Job %g has %g matching output files. There should be zero or one matching output files.', ji, sum(isoutfile))
    
    isinfile = infiles_jis == ji;
    assert(sum(isinfile)==1, 'InputOutputTable:IncorrectNumberOfInputFiles', ...
        'Job %g has %g matching input files. There should be one matching input file.', ji, sum(isinfile))
    
    iscmdfile = cmdfiles_jis == ji;
    assert(sum(iscmdfile)==0||sum(iscmdfile)==1, 'InputOutputTable:IncorrectNumberOfCommandLineOutputFiles', ...
        'Job %g has %g matching command line output files. There should be zero or one matching command line output files.', ...
        ji, sum(iscmdfile)) 
    
    if any(isoutfile)
        outfile = outfiles{isoutfile};
    else
        outfile = '';
    end
    infile = infiles{infiles_jis == ji};
    if any(iscmdfile)
        cmdfile = cmdfiles{cmdfiles_jis == ji};
    else
        cmdfile = '';
    end
    
    % Inputs
    if inputArgTableProvided
        infile_data = inputargtable_inputs(strcmp(inputargtable_files,infile),:);
    else
        infile_data = load(infile);
        infile_data = infile_data.input;
    end
    
    if isempty(inputArgNames)
        inputArgNames = arrayfun(@(i){sprintf('in%d',i)}, 1:numel(infile_data));
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
        try
            outfile_data = load(outfile);
        catch ME
            fprintf(getReport(ME))
            fprintf('Failed to load file. Skipping this file...\n')
            continue
        end
        outfile_data = outfile_data.out;
        
        if isempty(outputArgNames)
            outputArgNames = arrayfun(@(i){sprintf('out%d',i)}, 1:numel(outfile_data));
        end
        
        for outi = 1:numel(outputArgNames)
            if ~any(strcmp(outputArgNames{outi},skippedOutputArgs))
                tab(ji).(outputArgNames{outi}) = outfile_data{outi};
            end
        end
    end
    
    tab(ji).cmdfile = cmdfile;
    tab(ji).jobindex = ji;
    tab(ji).directory = direc;
end

tab = tab(jobmatches);

end