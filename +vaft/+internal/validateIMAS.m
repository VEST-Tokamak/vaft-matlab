function validateIMAS(functionNames)
%VALIDATEIMAS Error if required IMAS-MATLAB functions are unavailable.
%   VAFT.INTERNAL.VALIDATEIMAS() checks that the compiled IMAS-MATLAB
%   Data Entry functions are on the MATLAB path and throws
%   vaft:imas:notFound listing any that are missing.
%
%   VAFT.INTERNAL.VALIDATEIMAS(FUNCTIONNAMES) checks the given names.
%
%   A function only counts as available when it resolves to a MEX file.
%   IMAS-MATLAB ships plain .m files with the same names that only hold
%   help text, so finding those means the library was not built or its
%   toolbox folder is not on the path.
%
%   This function is internal and may change without notice.

arguments
    functionNames (1,:) string = ["imas_open", "imas_close", "ids_get"]
end

missing = strings(1, 0);
for name = functionNames
    if ~vaft.internal.isMexAvailable(name)
        missing(end+1) = name; %#ok<AGROW>
    end
end

if ~isempty(missing)
    error("vaft:imas:notFound", ...
        "IMAS-MATLAB is not available: %s not found as compiled MEX files. " + ...
        "Add the IMAS-MATLAB toolbox folder to the MATLAB path (for example " + ...
        "by sourcing <install_dir>/bin/al_env.sh before starting MATLAB) " + ...
        "and run vaft.doctor for details. See docs/installation.md.", ...
        strjoin(missing, ", "));
end
end
