function aaa___test_all
%call all testers in headless mode
if ~exist('OCTAVE_VERSION','builtin') && 7>str2double(subsref(version,struct('type','()','subs',{{1:2}})))
    %suppress this warning on ML6.5
    warning off MATLAB:m_warning_end_without_block
end
aaa___test___WBM(true);clc
old_folder=cd('tester');
try
    Failed=false;
    last='getUTC';
    aaa___test___getUTC(true);clc
    last='readfile';
    aaa___test___readfile(true);clc
    last='isnetavl';
    aaa___test___isnetavl(true);clc
catch
    Failed=true;
end
cd(old_folder);
if Failed,error(['tester for dependency failed (' last ')']),end
disp('composite test finished successfully')
end