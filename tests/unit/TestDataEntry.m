classdef TestDataEntry < matlab.unittest.TestCase
%TESTDATAENTRY Lifecycle and input validation of vaft.DataEntry.
%   Uses FakeBackend, so IMAS-MATLAB is not required.

    properties
        Fake
    end

    methods (TestClassSetup)
        function addPaths(testCase)
            import matlab.unittest.fixtures.PathFixture
            testsFolder = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(PathFixture(fileparts(testsFolder)));
            testCase.applyFixture(PathFixture(fullfile(testsFolder, "support")));
        end
    end

    methods (TestMethodSetup)
        function createFake(testCase)
            testCase.Fake = FakeBackend();
        end
    end

    methods
        function entry = openFake(testCase, varargin)
            entry = vaft.DataEntry("imas:hdf5?path=/tmp/db", varargin{:}, ...
                Backend=testCase.Fake.asBackend());
        end
    end

    methods (Test)
        function openPassesUriAndReadMode(testCase)
            entry = testCase.openFake();
            testCase.verifyTrue(entry.IsOpen);
            testCase.verifyEqual(entry.URI, "imas:hdf5?path=/tmp/db");
            testCase.verifyEqual(entry.Mode, "read");
            testCase.verifyEqual(testCase.Fake.LastURI, "imas:hdf5?path=/tmp/db");
            testCase.verifyEqual(testCase.Fake.LastMode, 40);
        end

        function getForwardsContextNameAndDefaultOccurrence(testCase)
            entry = testCase.openFake();
            ids = entry.get("equilibrium");
            testCase.verifyEqual(testCase.Fake.LastContext, 7);
            testCase.verifyEqual(testCase.Fake.LastIdsName, "equilibrium");
            testCase.verifyEqual(testCase.Fake.LastOccurrence, 0);
            testCase.verifyEqual(ids.ids_properties.comment, "equilibrium/0");
        end

        function getForwardsExplicitOccurrence(testCase)
            entry = testCase.openFake();
            entry.get("magnetics", Occurrence=2);
            testCase.verifyEqual(testCase.Fake.LastOccurrence, 2);
        end

        function getAcceptsCharName(testCase)
            entry = testCase.openFake();
            entry.get('summary');
            testCase.verifyEqual(testCase.Fake.LastIdsName, "summary");
        end

        function closeReleasesContext(testCase)
            entry = testCase.openFake();
            entry.close();
            testCase.verifyFalse(entry.IsOpen);
            testCase.verifyEqual(testCase.Fake.Calls, ["open"; "close"]);
            testCase.verifyEqual(testCase.Fake.LastContext, 7);
        end

        function closeIsIdempotent(testCase)
            entry = testCase.openFake();
            entry.close();
            entry.close();
            testCase.verifyEqual(testCase.Fake.count("close"), 1);
        end

        function getAfterCloseErrors(testCase)
            entry = testCase.openFake();
            entry.close();
            testCase.verifyError(@() entry.get("equilibrium"), "vaft:DataEntry:closed");
            testCase.verifyEqual(testCase.Fake.count("get"), 0);
        end

        function deleteClosesOpenEntry(testCase)
            entry = testCase.openFake();
            delete(entry);
            testCase.verifyEqual(testCase.Fake.count("close"), 1);
        end

        function clearingVariableCloses(testCase)
            entry = testCase.openFake(); %#ok<NASGU>
            clear entry
            testCase.verifyEqual(testCase.Fake.count("close"), 1);
        end

        function deleteAfterCloseDoesNotCloseAgain(testCase)
            entry = testCase.openFake();
            entry.close();
            delete(entry);
            testCase.verifyEqual(testCase.Fake.count("close"), 1);
        end

        function deleteWarnsInsteadOfThrowing(testCase)
            testCase.Fake.CloseError = MException("fake:close", "boom");
            entry = testCase.openFake();
            testCase.verifyWarning(@() delete(entry), "vaft:DataEntry:closeFailed");
        end

        function negativeContextIsOpenFailure(testCase)
            testCase.Fake.OpenResult = -1;
            testCase.verifyError(@() testCase.openFake(), "vaft:DataEntry:openFailed");
            testCase.verifyEqual(testCase.Fake.count("close"), 0);
        end

        function backendErrorIsWrappedAsCause(testCase)
            testCase.Fake.OpenError = MException("imas:open", "no such entry");
            try
                testCase.openFake();
                testCase.verifyFail("Expected an error.");
            catch err
                testCase.verifyEqual(string(err.identifier), "vaft:DataEntry:openFailed");
                testCase.verifyEqual(string(err.cause{1}.identifier), "imas:open");
            end
        end

        function unsupportedModeErrors(testCase)
            testCase.verifyError(@() testCase.openFake(Mode="write"), ...
                "vaft:DataEntry:unsupportedMode");
            testCase.verifyEqual(testCase.Fake.count("open"), 0);
        end

        function modeIsCaseInsensitive(testCase)
            entry = testCase.openFake(Mode="READ");
            testCase.verifyEqual(entry.Mode, "read");
        end

        function emptyUriErrors(testCase)
            testCase.verifyError(@() vaft.DataEntry("", Backend=testCase.Fake.asBackend()), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end

        function invalidOccurrenceErrors(testCase)
            entry = testCase.openFake();
            testCase.verifyError(@() entry.get("equilibrium", Occurrence=-1), ...
                "MATLAB:validators:mustBeNonnegative");
            testCase.verifyError(@() entry.get("equilibrium", Occurrence=1.5), ...
                "MATLAB:validators:mustBeInteger");
        end

        function emptyIdsNameErrors(testCase)
            entry = testCase.openFake();
            testCase.verifyError(@() entry.get(""), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end
    end
end
