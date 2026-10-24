classdef TestEnvironment < matlab.unittest.TestCase
%TESTENVIRONMENT Package visibility and dependency checks.
%   Runs without IMAS-MATLAB installed.

    methods (TestClassSetup)
        function addRepositoryRoot(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
        end
    end

    methods (Test)
        function publicFunctionsAreVisible(testCase)
            for name = ["vaft.open", "vaft.doctor", "vaft.version", "vaft.DataEntry"]
                testCase.verifyNotEmpty(which(name), name + " is not on the path");
            end
        end

        function versionIsSemVer(testCase)
            v = vaft.version();
            testCase.verifyClass(v, "string");
            testCase.verifyTrue(isscalar(v));
            testCase.verifyMatches(v, "^\d+\.\d+\.\d+$");
        end

        function doctorReturnsReport(testCase)
            report = vaft.doctor();
            testCase.verifyClass(report, "struct");
            testCase.verifyEqual(sort(string(fieldnames(report)))', ...
                ["Detail", "Hint", "Name", "Status"]);
            testCase.verifyTrue(all(ismember([report.Status], ["OK", "WARN", "FAIL", "INFO"])));
            testCase.verifyTrue(any([report.Name] == "IMAS-MATLAB"));
        end

        function doctorPrintsWithoutError(testCase)
            output = evalc("vaft.doctor()");
            testCase.verifySubstring(output, "vaft.doctor");
            testCase.verifySubstring(output, "IMAS-MATLAB");
        end

        function doctorReportsMissingImasAsFail(testCase)
            testCase.assumeFalse(vaft.internal.isMexAvailable("ids_get"), ...
                "IMAS-MATLAB is installed here.");
            report = vaft.doctor();
            imas = report([report.Name] == "IMAS-MATLAB");
            testCase.verifyEqual(imas.Status, "FAIL");
            testCase.verifyNotEqual(imas.Hint, "");
        end

        function validateIMASNamesMissingFunctions(testCase)
            missingName = "vaft_test_function_that_does_not_exist";
            try
                vaft.internal.validateIMAS(["imas_open", missingName]);
                testCase.verifyFail("Expected vaft:imas:notFound.");
            catch err
                testCase.verifyEqual(string(err.identifier), "vaft:imas:notFound");
                testCase.verifySubstring(err.message, missingName);
            end
        end

        function openWithoutImasGivesClearError(testCase)
            testCase.assumeFalse(vaft.internal.isMexAvailable("imas_open"), ...
                "IMAS-MATLAB is installed here.");
            testCase.verifyError(@() vaft.open("imas:hdf5?path=/tmp/none"), ...
                "vaft:imas:notFound");
        end
    end
end
