function tf = isMexAvailable(name)
%ISMEXAVAILABLE True if NAME resolves to a MEX file on the MATLAB path.
%   This function is internal and may change without notice.

arguments
    name (1,1) string
end

tf = exist(name, "file") == 3;
end
