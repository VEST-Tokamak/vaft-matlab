function report = doctor()
%DOCTOR Check vaft-matlab dependencies and report their status.
%   VAFT.DOCTOR() prints whether MATLAB, IMAS-MATLAB, IMAS-Core and the
%   IMAS Data Dictionary are available and compatible, with a hint for
%   each problem found. Python VAFT is reported for information only.
%
%   REPORT = VAFT.DOCTOR() also returns the checks as a struct array with
%   fields Name, Status ("OK", "WARN", "FAIL" or "INFO"), Detail and Hint,
%   and does not print anything.
%
%   VAFT.DOCTOR never installs software or changes the MATLAB path or the
%   environment.
%
%   See also VAFT.OPEN, VAFT.VERSION.

checks = [ ...
    checkVaft()
    checkMatlab()
    checkImasFunctions()
    checkImasVersions()
    checkDataDictionary()
    checkHdf5Locking()
    checkPython()];

if nargout > 0
    report = checks;
else
    printReport(checks);
end
end

function c = makeCheck(name, status, detail, hint)
arguments
    name (1,1) string
    status (1,1) string {mustBeMember(status, ["OK", "WARN", "FAIL", "INFO"])}
    detail (1,1) string
    hint (1,1) string = ""
end
c = struct("Name", name, "Status", status, "Detail", detail, "Hint", hint);
end

function c = checkVaft()
c = makeCheck("vaft-matlab", "OK", "version " + vaft.version() + ...
    " at " + string(fileparts(fileparts(mfilename("fullpath")))));
end

function c = checkMatlab()
minimum = "R2024b";
release = "R" + string(version("-release"));
if isMATLABReleaseOlderThan(minimum)
    c = makeCheck("MATLAB", "FAIL", release + " is older than " + minimum, ...
        "Use MATLAB " + minimum + " or newer.");
else
    c = makeCheck("MATLAB", "OK", release + " (" + string(computer("arch")) + ")");
end
end

function c = checkImasFunctions()
required = ["imas_open", "imas_close", "ids_get", "imas_versions"];
optional = ["ids_get_slice", "ids_get_sample", "imas_partial_get", ...
    "imas_list_all_occurrences", "ids_validate", "ids_put"];
isMex = @(names) arrayfun(@vaft.internal.isMexAvailable, names);

missingRequired = required(~isMex(required));
missingOptional = optional(~isMex(optional));
stubOnly = missingRequired(arrayfun(@(n) exist(n, "file") == 2, missingRequired));

if isempty(missingRequired)
    location = string(fileparts(which("ids_get")));
    if isempty(missingOptional)
        c = makeCheck("IMAS-MATLAB", "OK", "MEX functions found in " + location);
    else
        c = makeCheck("IMAS-MATLAB", "WARN", "found in " + location + ...
            "; missing optional: " + strjoin(missingOptional, ", "), ...
            "Rebuild or reinstall IMAS-MATLAB to get the full API.");
    end
elseif ~isempty(stubOnly)
    c = makeCheck("IMAS-MATLAB", "FAIL", ...
        "only help-text .m files found for: " + strjoin(stubOnly, ", "), ...
        "The IMAS-MATLAB source folder is on the path but not its compiled " + ...
        "toolbox. Add <install_dir>/toolbox (or source al_env.sh) instead.");
else
    c = makeCheck("IMAS-MATLAB", "FAIL", ...
        "not found: " + strjoin(missingRequired, ", "), ...
        "Install IMAS-MATLAB and source <install_dir>/bin/al_env.sh before " + ...
        "starting MATLAB. See docs/installation.md.");
end
end

function c = checkImasVersions()
if ~vaft.internal.isMexAvailable("imas_versions")
    c = makeCheck("IMAS-Core", "FAIL", "imas_versions unavailable", ...
        "Resolve the IMAS-MATLAB check above first.");
    return
end
try
    info = imas_versions();
    c = makeCheck("IMAS-Core", "OK", formatVersions(info));
catch err
    c = makeCheck("IMAS-Core", "FAIL", "imas_versions failed: " + err.message, ...
        "IMAS-MATLAB MEX files did not load. Check that libal is on the " + ...
        "library path and that IMAS-MATLAB was built for this MATLAB release.");
end
end

function c = checkDataDictionary()
idsdef = string(getenv("IDSDEF_PATH"));
imasVersion = string(getenv("IMAS_VERSION"));
if idsdef == "" && imasVersion == ""
    c = makeCheck("Data Dictionary", "WARN", "IDSDEF_PATH and IMAS_VERSION are not set", ...
        "Source <install_dir>/bin/al_env.sh so tools can find the Data Dictionary.");
elseif idsdef ~= "" && ~isfile(idsdef)
    c = makeCheck("Data Dictionary", "FAIL", "IDSDEF_PATH points to a missing file: " + idsdef, ...
        "Set IDSDEF_PATH to <install_dir>/include/IDSDef.xml.");
else
    detail = "IMAS_VERSION=" + imasVersion;
    if idsdef ~= ""
        detail = detail + ", IDSDEF_PATH=" + idsdef;
    end
    c = makeCheck("Data Dictionary", "OK", detail);
end
end

function c = checkHdf5Locking()
value = string(getenv("HDF5_USE_FILE_LOCKING"));
if upper(value) == "FALSE"
    c = makeCheck("HDF5 file locking", "OK", "HDF5_USE_FILE_LOCKING=FALSE");
else
    c = makeCheck("HDF5 file locking", "INFO", "HDF5_USE_FILE_LOCKING is not FALSE", ...
        "On shared or network filesystems set HDF5_USE_FILE_LOCKING=FALSE.");
end
end

function c = checkPython()
try
    pe = pyenv;
catch
    c = makeCheck("Python VAFT (optional)", "INFO", "Python interface unavailable");
    return
end
if pe.Version == ""
    c = makeCheck("Python VAFT (optional)", "INFO", "no Python configured (pyenv)", ...
        "Not needed for IMAS data access.");
    return
end
detail = "Python " + pe.Version;
try
    spec = py.importlib.util.find_spec("vaft");
    if isa(spec, "py.NoneType")
        detail = detail + "; vaft package not installed";
    else
        detail = detail + "; vaft package found";
    end
catch err
    detail = detail + "; could not query vaft (" + err.message + ")";
end
c = makeCheck("Python VAFT (optional)", "INFO", detail);
end

function s = formatVersions(info)
if isstring(info) || ischar(info)
    s = strjoin(strtrim(string(info)), "; ");
elseif isstruct(info)
    % imas_versions returns e.g. al_version, hli_version, dd_version as
    % text plus *_array numeric duplicates, which are skipped.
    names = string(fieldnames(info));
    names = names(~endsWith(names, "_array"));
    parts = strings(size(names));
    for k = 1:numel(names)
        value = info.(names(k));
        if ischar(value) || isstring(value)
            value = string(value);
        else
            value = strjoin(string(value(:)'), ".");
        end
        parts(k) = names(k) + "=" + value;
    end
    s = strjoin(parts', "; ");
else
    s = strtrim(formattedDisplayText(info));
end
end

function printReport(checks)
fprintf("vaft.doctor\n");
width = max(strlength([checks.Name]));
for c = checks'
    fprintf("  [%-4s] %-*s  %s\n", c.Status, width, c.Name, c.Detail);
    if c.Hint ~= "" && c.Status ~= "OK"
        fprintf("  %*s  -> %s\n", width + 7, "", c.Hint);
    end
end
nFail = sum([checks.Status] == "FAIL");
if nFail == 0
    fprintf("No blocking problems found.\n");
else
    fprintf("%d blocking problem(s) found.\n", nFail);
end
end
