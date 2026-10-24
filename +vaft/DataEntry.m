classdef DataEntry < handle
%DATAENTRY Handle to an open IMAS Data Entry.
%   ENTRY = VAFT.DATAENTRY(URI) opens the existing IMAS Data Entry at URI
%   through IMAS-MATLAB (imas_open). Prefer VAFT.OPEN, which calls this
%   constructor.
%
%   ENTRY = VAFT.DATAENTRY(URI, Mode="read") selects the access mode. Only
%   "read" is supported in this release; writing is planned.
%
%   DataEntry is a thin adapter: IDS data are returned exactly as
%   IMAS-MATLAB's ids_get produces them, as native MATLAB structures.
%
%   DataEntry properties (read-only):
%       URI    - IMAS URI of the Data Entry
%       Mode   - Access mode ("read")
%       IsOpen - True until close is called
%
%   DataEntry methods:
%       get    - Read an IDS
%       close  - Close the Data Entry (safe to call more than once)
%
%   The Data Entry is also closed when the handle is deleted or goes out
%   of scope.
%
%   Example:
%       entry = vaft.open("imas:hdf5?path=./test_db");
%       eq = entry.get("equilibrium", Occurrence=0);
%       entry.close();
%
%   See also VAFT.OPEN, VAFT.DOCTOR, IMAS_OPEN, IDS_GET.

    properties (SetAccess = private)
        URI (1,1) string
        Mode (1,1) string
        IsOpen (1,1) logical = false
    end

    properties (Access = private)
        Context = []
        Backend struct
    end

    properties (Constant, Access = private)
        % IMAS-MATLAB access mode codes accepted by imas_open.
        ModeCodes = dictionary("read", 40)
    end

    methods
        function obj = DataEntry(uri, opts)
            arguments
                uri (1,1) string {mustBeNonzeroLengthText}
                opts.Mode (1,1) string = "read"
                opts.Backend struct {mustBeScalarOrEmpty} = struct.empty
            end

            mode = lower(opts.Mode);
            if ~isKey(vaft.DataEntry.ModeCodes, mode)
                error("vaft:DataEntry:unsupportedMode", ...
                    "Mode ""%s"" is not supported. Supported modes: %s. " + ...
                    "Writing Data Entries is planned for a later release.", ...
                    opts.Mode, strjoin(keys(vaft.DataEntry.ModeCodes), ", "));
            end

            backend = opts.Backend;
            if isempty(backend)
                backend = vaft.internal.imasBackend();
            end
            if backend.requiresIMAS
                vaft.internal.validateIMAS();
            end

            try
                ctx = backend.open(uri, vaft.DataEntry.ModeCodes(mode));
            catch cause
                err = MException("vaft:DataEntry:openFailed", ...
                    "Could not open IMAS Data Entry ""%s"".", uri);
                throw(addCause(err, cause));
            end
            if ~isnumeric(ctx) || ~isscalar(ctx) || ctx < 0
                error("vaft:DataEntry:openFailed", ...
                    "Could not open IMAS Data Entry ""%s"" (imas_open returned %s). " + ...
                    "Check that the URI is correct and the entry exists.", ...
                    uri, mat2str(ctx));
            end

            obj.URI = uri;
            obj.Mode = mode;
            obj.Backend = backend;
            obj.Context = ctx;
            obj.IsOpen = true;
        end

        function ids = get(obj, idsName, opts)
            %GET Read an IDS from the Data Entry.
            %   IDS = GET(ENTRY, IDSNAME) reads occurrence 0 of the IDS
            %   named IDSNAME (for example "equilibrium") with ids_get.
            %
            %   IDS = GET(ENTRY, IDSNAME, Occurrence=N) reads occurrence N.
            arguments
                obj (1,1) vaft.DataEntry
                idsName (1,1) string {mustBeNonzeroLengthText}
                opts.Occurrence (1,1) double {mustBeInteger, mustBeNonnegative} = 0
            end

            obj.assertOpen();
            ids = obj.Backend.get(obj.Context, idsName, opts.Occurrence);
        end

        function close(obj)
            %CLOSE Close the Data Entry.
            %   CLOSE(ENTRY) releases the IMAS context with imas_close.
            %   Calling it again has no effect.
            if ~obj.IsOpen
                return
            end
            ctx = obj.Context;
            obj.IsOpen = false;
            obj.Context = [];
            obj.Backend.close(ctx);
        end

        function delete(obj)
            % Destructors must not throw; closing errors are reported only.
            try
                obj.close();
            catch err
                warning("vaft:DataEntry:closeFailed", ...
                    "Error while closing IMAS Data Entry ""%s"": %s", ...
                    obj.URI, err.message);
            end
        end
    end

    methods (Access = private)
        function assertOpen(obj)
            if ~obj.IsOpen
                error("vaft:DataEntry:closed", ...
                    "The IMAS Data Entry ""%s"" is closed.", obj.URI);
            end
        end
    end
end
