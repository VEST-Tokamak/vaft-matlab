function plan = buildfile
%BUILDFILE Build tasks for vaft-matlab.
%   buildtool check        - Static code analysis
%   buildtool test         - Unit tests (no IMAS required)
%   buildtool integration  - Integration tests (needs IMAS-MATLAB on the path)

import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

plan = buildplan(localfunctions);

plan("check") = CodeIssuesTask(["+vaft", "tests", "examples"], ...
    WarningThreshold=0);

plan("test") = TestTask("tests/unit", ...
    SourceFiles="+vaft", ...
    TestResults="results/unit.xml", ...
    CodeCoverageResults="results/coverage.xml");
plan("test").Description = "Run unit tests (no IMAS required)";

plan("integration") = TestTask("tests/integration", ...
    TestResults="results/integration.xml");
plan("integration").Description = "Run IMAS-MATLAB integration tests";

plan.DefaultTasks = ["check", "test"];
end
