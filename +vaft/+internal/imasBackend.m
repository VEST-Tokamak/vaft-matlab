function backend = imasBackend()
%IMASBACKEND Function handles to the IMAS-MATLAB Data Entry API.
%   BACKEND = VAFT.INTERNAL.IMASBACKEND() returns a struct with fields
%   open, close and get that forward to imas_open, imas_close and ids_get.
%   VAFT.DATAENTRY uses it by default; tests substitute a test double with
%   the same fields.
%
%   This function is internal and may change without notice.

backend = struct( ...
    "open",  @(uri, mode) imas_open(char(uri), mode), ...
    "close", @(ctx) imas_close(ctx), ...
    "get",   @(ctx, idsName, occurrence) ids_get(ctx, char(idsName), occurrence), ...
    "requiresIMAS", true);
end
