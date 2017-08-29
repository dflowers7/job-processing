function taski_per_job = taskjobsplit(ntasks, njobs)

base_ntasksperjob = floor(ntasks/njobs);
ntasksperjob = repmat(base_ntasksperjob, njobs, 1);
ntasksleft = ntasks - sum(ntasksperjob);
ntasksperjob(1:ntasksleft) = ntasksperjob(1:ntasksleft) + 1;
taski_per_job = mat2cell((1:ntasks).', ntasksperjob, 1);

end