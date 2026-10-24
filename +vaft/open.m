function entry = open(uri, opts)
%OPEN Open an existing IMAS Data Entry.
%   ENTRY = VAFT.OPEN(URI) opens the IMAS Data Entry at URI through
%   IMAS-MATLAB and returns a VAFT.DATAENTRY handle.
%
%   ENTRY = VAFT.OPEN(URI, Mode="read") selects the access mode. Only
%   "read" is supported in this release.
%
%   Example:
%       entry = vaft.open("imas:hdf5?path=./test_db");
%       eq = entry.get("equilibrium", Occurrence=0);
%       entry.close();
%
%   See also VAFT.DATAENTRY, VAFT.DOCTOR.

arguments
    uri (1,1) string {mustBeNonzeroLengthText}
    opts.Mode (1,1) string = "read"
end

entry = vaft.DataEntry(uri, Mode=opts.Mode);
end
