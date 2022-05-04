function dpath = createWorkingDirectory()
    dpath = tempname;
    mkdir(dpath);
end