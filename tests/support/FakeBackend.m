classdef FakeBackend < handle
%FAKEBACKEND Test double for the IMAS-MATLAB Data Entry API.
%   Records every call so tests can check how vaft.DataEntry drives
%   imas_open, ids_get and imas_close, without IMAS installed.

    properties
        OpenResult = 7          % value returned by open (negative = failure)
        OpenError = []          % MException thrown by open, if set
        CloseError = []         % MException thrown by close, if set
        Calls = strings(0, 1)   % "open", "get", "close" in call order
        LastURI = ""
        LastMode = []
        LastContext = []
        LastIdsName = ""
        LastOccurrence = []
    end

    methods
        function s = asBackend(obj)
            s = struct( ...
                "open",  @(uri, mode) obj.open(uri, mode), ...
                "close", @(ctx) obj.close(ctx), ...
                "get",   @(ctx, name, occ) obj.get(ctx, name, occ), ...
                "requiresIMAS", false);
        end

        function ctx = open(obj, uri, mode)
            obj.Calls(end+1, 1) = "open";
            obj.LastURI = uri;
            obj.LastMode = mode;
            if ~isempty(obj.OpenError)
                throw(obj.OpenError);
            end
            ctx = obj.OpenResult;
        end

        function ids = get(obj, ctx, name, occurrence)
            obj.Calls(end+1, 1) = "get";
            obj.LastContext = ctx;
            obj.LastIdsName = name;
            obj.LastOccurrence = occurrence;
            ids = struct("ids_properties", struct("comment", name + "/" + occurrence));
        end

        function close(obj, ctx)
            obj.Calls(end+1, 1) = "close";
            obj.LastContext = ctx;
            if ~isempty(obj.CloseError)
                throw(obj.CloseError);
            end
        end

        function n = count(obj, name)
            n = sum(obj.Calls == name);
        end
    end
end
