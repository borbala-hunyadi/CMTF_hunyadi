function results = spm_tests(varargin)
% Unit Testing Framework
% FORMAT results = spm_tests(name,value,...)
% name,value  - pairs of optional parameter names and values:
%     verbose:  verbosity level of test run progress report [default: 2]
%     display:  display test results [default: false]
%     coverage: display code coverage [default: false]
%     tag:      test tag selector [default: '', ie all tests]
%     tap:      save a Test Anything Protocol (TAP) file [default: false]
%     test:     name of function to test [default: '', ie all tests]
% 
% results     - TestResult array containing information describing the
%               result of running the test suite.
%__________________________________________________________________________
% Copyright (C) 2015 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin
% $Id: spm_tests.m 6492 2015-06-26 14:27:40Z guillaume $


if spm_check_version('matlab','8.3') < 0
    error('Unit Tests require MATLAB R2014a or above.');
end

SVNid = '$Rev: 6492 $';
SPMid = spm('FnBanner',mfilename,SVNid);

%-Input parameters
%--------------------------------------------------------------------------
options = struct('verbose',2, 'display',false, 'coverage',false, ...
                 'tag', '', 'tap',false, 'test','');
if nargin
    if isstruct(varargin{1})
        fn = fieldnames(varargin{1});
        for i=1:numel(fn)
            options.(fn{i}) = varargin{1}.(fn{i});
        end
    else
        for i=1:2:numel(varargin)
            options.(varargin{i}) = varargin{i+1};
        end
    end
end

%-Unit tests
%==========================================================================

%-Create a TestSuite
%--------------------------------------------------------------------------
import matlab.unittest.TestSuite;
import matlab.unittest.selectors.*;
tests = fullfile(spm('Dir'),'tests');
if isempty(options.test)
    suite = TestSuite.fromFolder(tests, 'IncludingSubfolders', true);
else
    mtest = fullfile(tests,['test_' spm_file(options.test,'ext','.m')]);
    if ~spm_existfile(mtest)
        warning('SPM:tests:fileNotFound','No tests found for %s',options.test);
        return;
    end
    suite = TestSuite.fromFile(mtest);
end
if ~isempty(options.tag)
    suite = suite.selectIf(~HasTag | HasTag(options.tag));
end

%-Create a TestRunner
%--------------------------------------------------------------------------
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.*
if ~options.verbose
    runner = TestRunner.withNoPlugins;
else
    runner = TestRunner.withTextOutput('Verbosity',options.verbose);
end

if options.coverage
    plugin = CodeCoveragePlugin.forFolder(spm('Dir'));
    runner.addPlugin(plugin);
end

if options.tap
    d = getenv('WORKSPACE');
    if isempty(d), d = spm('Dir'); end
    tapFile = fullfile(d,'spm_tests.tap');
    plugin = TAPPlugin.producingOriginalFormat(ToFile(tapFile));
    runner.addPlugin(plugin);
end

%-Run tests
%--------------------------------------------------------------------------
results = runner.run(suite);

%-Display test results
%--------------------------------------------------------------------------
if options.display
    fprintf(['Totals (%d tests):\n\t%d Passed, %d Failed, %d Incomplete.\n' ...
        '\t%f seconds testing time.\n\n'],numel(results),nnz([results.Passed]),...
        nnz([results.Failed]),nnz([results.Incomplete]),sum([results.Duration]));
    
    disp(table(results));
end
