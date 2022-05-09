function createOptionFile(path)
	filename = fullfile(strcat(path,'\','options.session'));
    fid = fopen(filename,'w');
    fprintf(fid,'%s\n','UseTempDirectory = 0');
	fclose(fid);
end