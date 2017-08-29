function [outfiles,outfiles_jis,infiles,infiles_jis,cmdfiles,cmdfiles_jis,inputargtablefile] = JobFiles(direc)
% [outfiles,outfiles_jis,infiles,infiles_jis,cmdfiles,cmdfiles_jis] = JobFiles(direc)

% Get input file names
ninfiles = numel(dir(fullfile(direc, 'input*.mat')));
infiles_nopath = arrayfun(@(i){sprintf('input%g.mat',i)}, (1:ninfiles)');
infiles = fullfile(direc, infiles_nopath);
infiles_jis = (1:ninfiles).'; % Job indices are in increasing order because I constructed them that way

% Get all possible output file names
outfiles_nopath = regexprep(infiles_nopath, 'in', 'out');
outfiles = fullfile(direc, outfiles_nopath);
outfiles_jis = infiles_jis;

% Filter down to output files that exist
outfileexists = cellfun(@(f)exist(f, 'file')>0, outfiles);
outfiles = outfiles(outfileexists);
noutfiles = numel(outfiles);
outfiles_jis = outfiles_jis(outfileexists);

% Get existing command line output files
jobname = regexp(direc, '(?<=\d+\.\d+\.\d+-\d+\.\d+\_)[^\.]+', 'match');
jobname = jobname{1};
filepattern_else = [jobname '.o*'];
cmdfiles = dir(fullfile(direc, filepattern_else));
if isempty(cmdfiles)
    filepattern_c3ddb = 'out_*.out';
    cmdfiles = dir(fullfile(direc, filepattern_c3ddb));
    isc3ddb = true;
else
    isc3ddb = false;
end
cmdfiles = fullfile(direc,{cmdfiles.name}');

% Get job array indices corresponding to command line output files, at
% least for those jobs that reached the stage where the job array ID was
% printed
cmdfiles_jis = nan(numel(cmdfiles),1);
for i = 1:numel(cmdfiles)
    txt = fileread(cmdfiles{i});
    cmdoutfiles_ji = regexp(txt, 'Running job (\d+) in array', 'tokens');
    if isempty(cmdoutfiles_ji)
        continue
    end
    cmdoutfiles_ji = cmdoutfiles_ji{1}{1};
    cmdfiles_jis(i) = str2double(cmdoutfiles_ji);
end

% Sort command line output files by their job indices
temp = sortrows(table(cmdfiles,cmdfiles_jis),'cmdfiles_jis');
cmdfiles = temp{:,1};
cmdfiles_jis = temp{:,2};

% Search for an input argument table
inputargtablefile = inputargtablefilename(direc);
if ~(exist(inputargtablefile, 'file') > 0)
    inputargtablefile = '';
end

end