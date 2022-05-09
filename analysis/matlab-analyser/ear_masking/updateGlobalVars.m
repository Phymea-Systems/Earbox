function gvars = updateGlobalVars(val)
global globalvars
globalvars.(inputname(1)) = val;
gvars = getGlobalVars;
    
