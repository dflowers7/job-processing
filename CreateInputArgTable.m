function inputargtable = CreateInputArgTable(direc)
% Creates a struct containing the names of the input files and the input
% values themselves, then saves the table in the directory.
% inputargtable
%   .inputfile
%       String containing the name of the input file
%   .input
%       Cell array containing the inputs to the job's function (i.e., the
%       contents of the input file)

[~, ~, infiles, infiles_jis] = JobFiles(direc);
infiles_jis_sort = sort(infiles_jis);
inputargtable = repmat(struct, numel(infiles), 1);
for ji = infiles_jis_sort(:)'

    infile = infiles{infiles_jis == ji};
    
    % Load inputs
    infile_data = load(infile);
    infile_data = infile_data.input;
    
    % Store inputs in struct
    inputargtable(ji).inputfile = infile;
    inputargtable(ji).input = infile_data;
end

filename = inputargtablefilename(direc);
save(filename, 'inputargtable')

end