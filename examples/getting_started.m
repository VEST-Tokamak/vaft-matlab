%% Getting started with vaft-matlab
% Open an IMAS Data Entry, read IDSs as native MATLAB structures, and
% close it again. Requires IMAS-MATLAB on the MATLAB path; see
% docs/installation.md.
%
% Set the variable "uri" before running this script to use your own Data
% Entry, for example:
%
%   uri = "imas:hdf5?path=/data/imas/vest/45000";
%   run("examples/getting_started.m")

%% 1. Check dependencies
vaft.doctor();

%% 2. Open the Data Entry
if ~exist("uri", "var")
    uri = "imas:hdf5?path=./test_db";
end
entry = vaft.open(uri, Mode="read");
fprintf("Opened %s\n", entry.URI);

%% 3. Read an IDS
% get returns the structure produced by IMAS-MATLAB's ids_get. Occurrence
% selects the IDS occurrence (default 0).
eq = entry.get("equilibrium", Occurrence=0);
fprintf("equilibrium: %d time slice(s), comment: ""%s""\n", ...
    numel(eq.time), eq.ids_properties.comment);

%% 4. Close
% close is safe to call more than once. The entry is also closed when the
% variable is cleared.
entry.close();
