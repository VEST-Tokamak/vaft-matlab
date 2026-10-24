classdef (TestTags = {'IntegrationIMAS'}) TestIntegrationIMAS < matlab.unittest.TestCase
%TESTINTEGRATIONIMAS vaft.open / vaft.DataEntry against real IMAS-MATLAB.
%   Writes a small HDF5 Data Entry with the upstream IMAS-MATLAB API in a
%   temporary folder, then reads it back through vaft. The tests are
%   skipped when compiled IMAS-MATLAB is not on the MATLAB path.
%
%   Fixture contents:
%       summary     occurrence 0: time = [0.1 0.2 0.3],
%                   global_quantities.ip.value = [1.1e6 1.2e6 1.3e6]
%       equilibrium occurrence 0: time = [0.01 0.02], comment "occurrence 0"
%       equilibrium occurrence 1: time = 0.05,        comment "occurrence 1"

    properties
        URI string
    end

    methods (TestClassSetup)
        % A single setup method, because TestClassSetup methods run in an
        % unspecified order and each step needs the previous one.
        function writeFixture(testCase)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.applyFixture(PathFixture(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.assumeTrue(vaft.internal.isMexAvailable("ids_put") && ...
                vaft.internal.isMexAvailable("ids_get"), ...
                "Compiled IMAS-MATLAB is not on the MATLAB path.");

            folder = testCase.applyFixture(TemporaryFolderFixture).Folder;
            testCase.URI = "imas:hdf5?path=" + string(folder);

            ctx = imas_open(char(testCase.URI), 43);  % FORCE_CREATE_PULSE
            testCase.assertGreaterThanOrEqual(ctx, 0, "Could not create the HDF5 fixture.");
            closer = onCleanup(@() imas_close(ctx));

            summary = ids_init('summary');
            summary.ids_properties.homogeneous_time = 1;
            summary.ids_properties.comment = 'vaft-matlab integration fixture';
            summary.time = [0.1, 0.2, 0.3];
            summary.global_quantities.ip.value = [1.1e6, 1.2e6, 1.3e6];
            ids_put(ctx, 'summary', summary);

            testCase.putEquilibrium(ctx, 0, [0.01, 0.02]);
            testCase.putEquilibrium(ctx, 1, 0.05);
            clear closer
        end
    end

    methods (Static)
        function putEquilibrium(ctx, occurrence, time)
            eq = ids_init('equilibrium');
            eq.ids_properties.homogeneous_time = 1;
            eq.ids_properties.comment = sprintf('occurrence %d', occurrence);
            eq.time = time;
            ids_put(ctx, 'equilibrium', occurrence, eq);
        end
    end

    methods (Test)
        function readsKnownSummaryValues(testCase)
            entry = vaft.open(testCase.URI);
            summary = entry.get("summary");
            entry.close();

            testCase.verifySize(summary.time(:), [3, 1]);
            testCase.verifyEqual(summary.time(:)', [0.1, 0.2, 0.3], AbsTol=1e-12);
            testCase.verifyEqual(summary.global_quantities.ip.value(:)', ...
                [1.1e6, 1.2e6, 1.3e6], RelTol=1e-12);
            testCase.verifyEqual(summary.ids_properties.homogeneous_time, int32(1));
        end

        function selectsOccurrence(testCase)
            entry = vaft.open(testCase.URI, Mode="read");
            eq0 = entry.get("equilibrium", Occurrence=0);
            eq1 = entry.get("equilibrium", Occurrence=1);
            entry.close();

            testCase.verifyEqual(string(eq0.ids_properties.comment), "occurrence 0");
            testCase.verifyEqual(string(eq1.ids_properties.comment), "occurrence 1");
            testCase.verifyEqual(eq0.time(:)', [0.01, 0.02], AbsTol=1e-12);
            testCase.verifyEqual(eq1.time, 0.05, AbsTol=1e-12);
        end

        function defaultOccurrenceIsZero(testCase)
            entry = vaft.open(testCase.URI);
            eq = entry.get("equilibrium");
            testCase.verifyEqual(string(eq.ids_properties.comment), "occurrence 0");
        end

        function closeIsSafeAndFinal(testCase)
            entry = vaft.open(testCase.URI);
            entry.close();
            entry.close();
            testCase.verifyFalse(entry.IsOpen);
            testCase.verifyError(@() entry.get("summary"), "vaft:DataEntry:closed");
        end

        function repeatedOpenCloseCycles(testCase)
            for k = 1:5
                entry = vaft.open(testCase.URI);
                entry.get("summary");
                delete(entry);
            end
            entry = vaft.open(testCase.URI);
            testCase.verifyTrue(entry.IsOpen);
        end

        function missingEntryFailsToOpen(testCase)
            missing = "imas:hdf5?path=" + string(fullfile(tempdir, "vaft_missing_" + matlab.lang.internal.uuid()));
            testCase.verifyError(@() vaft.open(missing), "vaft:DataEntry:openFailed");
        end

        function doctorReportsImasOk(testCase)
            report = vaft.doctor();
            imas = report([report.Name] == "IMAS-MATLAB");
            core = report([report.Name] == "IMAS-Core");
            testCase.verifyNotEqual(imas.Status, "FAIL");
            testCase.verifyEqual(core.Status, "OK");
            testCase.verifySubstring(core.Detail, "dd_version=");
        end
    end
end
