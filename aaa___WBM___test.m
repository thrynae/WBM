function pass_part_fail=aaa___WBM___test(varargin)
%This function is a test kit for WBM
% This function will trigger some errors in WBM and will test a few syntaxes. This has the dual
% purpose of being able to test the function, and to have an easy method of testing the performance
% as well, without internet connectivity being an unpredictable factor.
%
% Each call to an internet function contains a pause, change the value of websavepause to affect
% this length.
%
%Pass:    passes all tests
%Partial: some tests are skipped, actual usage may work
%Fail:    fails any test
pass_part_fail = 'pass';

checkpoint('write_only_to_file_on_read')
checkpoint_pre = checkpoint('read');

if nargin==0,RunTestHeadless = false;else,RunTestHeadless = true;end

global pausetime %#ok<GVMIS>
websavepause = 0.1;
S = prepare_files(websavepause);
if ~RunTestHeadless,clc,end
starttime = now; %#ok<TNOW1>

% Run actual tests.
ThrowError = false;
test_names = {@test01,@test02,@test03,@test04,@test05,@test06,@test07,@test08,@test09,@test10,...
    @test11,@test12};
for n=1:numel(test_names),test_names{n} = func2str(test_names{n});end
for n_test=1:numel(test_names)
    try ME=[]; %#ok<NASGU>
        [success,ME,skipped] = eval(test_names{n_test});
    catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
        success = false;
    end
    
    if success && skipped
        pass_part_fail = 'partial: some test(s) were skipped';
    elseif success
        fprintf('test %d succeeded\n',n_test)
    else
        id = ME.identifier;
        fprintf('test %d failed\n(id: %s)\n',n_test,id)
        ThrowError = true;
    end
end

% Display timing results.
toc_t = (now-starttime)*60*60*24; %#ok<TNOW1>
checkpoint_post = checkpoint('read');
checkpoint_time_this_run = checkpoint_post.time-checkpoint_pre.time;
fprintf('Total time elapsed: %.1f seconds (including %.0fms for checkpoints)\n',...
    toc_t,checkpoint_time_this_run)
fprintf('Useful time: %.1f seconds\n',toc_t-pausetime-checkpoint_time_this_run/1e3)

% Delete test files and console output file.
if exist(S.file01,'file'),delete(S.file01);end
if exist(S.file02,'file'),delete(S.file02);end
if exist(S.file03,'file'),delete(S.file03);end
try fclose(S.fid);catch,end
if exist(S.tmpfilename,'file'),delete(S.tmpfilename);end

SelfTestFailMessage = '';
% Run the self-validator function(s).
SelfTestFailMessage = [SelfTestFailMessage SelfTest__bsxfun_plus];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__error_];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__findND];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__PatternReplace];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__regexp_outkeys];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__stringtrim];
SelfTestFailMessage = [SelfTestFailMessage SelfTest__warning_];
checkpoint('read');

% Rethow on test fail.
if ~isempty(SelfTestFailMessage) || ThrowError
    if nargout>0
        pass_part_fail='fail';
    else
        if ~isempty(SelfTestFailMessage)
            error('Self-validator functions returned these error(s):\n%s',SelfTestFailMessage)
        else
            checkpoint('aaa___WBM___test','char2cellstr','get_trace')
            trace = char2cellstr(get_trace(0,ME.stack));
            error('Test failed with error message:%s',...
                sprintf('\n    %s',ME.message,trace{:}))
        end
    end
end
disp(['tester function ' mfilename ' finished '])
if nargout==0,clearvars,end
end
function S=prepare_files(set_websavepause_value)
persistent persistent_S
if nargin==0
    S = persistent_S;return
end

global trigger_websave_error websavepause pausetime HJW___test_suit___debug_hook_data %#ok<GVMIS>
HJW___test_suit___debug_hook_data = [];
trigger_websave_error = []; % Use a global to force websave to trigger a specific error sometimes.
websavepause = set_websavepause_value;
pausetime = 0; % Keep track of total pause time.

url = 'protocol://example.com';
date = '20170715213747';

% Generate test files with random names.
current_folder = [fileparts(which(mfilename)) filesep];
file01 = [current_folder 'aaa___test_file_WBM_01_' strrep(tempname,tempdir,'') '.txt'];
file02 = [current_folder 'aaa___test_file_WBM_02_' strrep(tempname,tempdir,'') '.txt'];
file03 = [current_folder 'aaa___test_file_WBM_03_' strrep(tempname,tempdir,'') '.txt'];

fid = fopen(file01,'wt');
fprintf(fid,'%s%s%s','/web/',date,'/');
fclose(fid);
fid = fopen(file02,'wt');
fprintf(fid,'%s\n','<td class="u" colspan="2">');
fprintf(fid,'%s%s%s\n','<input type="hidden" name="date" value="',date,'/');
fclose(fid);
fid = fopen(file03,'wt');
fprintf(fid,'%s','no date in this file');
fclose(fid);

checkpoint('aaa___WBM___test','tmpname')
S.tmpfilename = tmpname('WBM_tester_console_capture','.txt');
S.fid = fopen(S.tmpfilename,'w');

[ S.url,S.date,S.current_folder,S.file01,S.file02,S.file03] = deal(...
    url,  date,  current_folder,  file01,  file02,  file03);
S.pausetime=pausetime;
persistent_S=S;
end
function file=websave(file,varargin)
% Shadow the websave function to test WBM.
global trigger_websave_error websavepause pausetime %#ok<GVMIS>
pause(websavepause),pausetime=pausetime+websavepause;
if numel(trigger_websave_error)~=0
    tmp = trigger_websave_error(1);
    trigger_websave_error(1) = [];
    error(tmp.identifier,tmp.message)
end
end
function out=webread(url,varargin)
% Shadow the webread function to test WBM.
%
% This will always return a success code.
pattern = '&timestamp=';
out.archived_snapshots.closest.timestamp = url( (strfind(url,pattern)+numel(pattern)) : end );
out.archived_snapshots.closest.status = '200';
end
function file=urlwrite(url,file,varargin)
% Shadow the urlwrite function to test WBM.
global trigger_websave_error websavepause pausetime %#ok<GVMIS>
if ~isempty(strfind(url,'http://archive.org/wayback/available?url=')) %#ok<STREMP>
    % Create a response struct in JSON, similar to webread.
    pattern = '&timestamp=';
    timestamp = url( (strfind(url,pattern)+numel(pattern)) : end );
    fid = fopen(file,'w');
    fprintf(fid,['{"archived_snapshots": {"closest": {"timestamp": "%s", "available": true, ',...
        '"status": "200", "url": "http://web.archive.org/web/%s"}}, "url": "%s"}'],...
        timestamp,url,url);
    fclose(fid);
else
    % Shadow similar to websave.
    pause(websavepause),pausetime=pausetime+websavepause;
    if numel(trigger_websave_error)~=0
        tmp = trigger_websave_error(1);
        trigger_websave_error(1) = [];
        error(tmp.identifier,tmp.message)
    end
end
end
function a=weboptions(a,varargin)
% Shadow internal function to avoid errors.
end
function [success,ME,skipped]=test01
% Trigger a compile of the UTC retriever.
success = true;skipped = false;
try ME = [];
    checkpoint('aaa___WBM___test','WBM')
    WBM('in1','http://in2','m_date_r','error','flag','id')
    success = false;
catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
    if ~strcmp(ME.identifier,'HJW:WBM:IncompatibleInputs')
        % Compile failed and no internet available for the web fallback method (or the UTC offset
        % is larger than 14 hours, which shouldn't be possible).
        success = false;
    end
end
end
function [success,ME,skipped]=test02
% Test nargout.
success = true;skipped = false;
try ME = [];
    checkpoint('aaa___WBM___test','WBM')
    [out1,out2,out3] = WBM('in1','in2'); %#ok<ASGLU>
catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
    if ~(   strcmp(ME.identifier,'MATLAB:TooManyOutputs') || ...
            strcmp(ME.identifier,'HJW:WBM:nargout') || ...
            strcmp(ME.identifier,'Octave:invalid-fun-call'))
        success = false;
    end
end
end
function [success,ME,skipped]=test03
% Test incompatible combination of flag and missing date response.
success = true;skipped = false;
S = prepare_files;
options = struct;options.m_date_r='error';options.flag='id';
options.print_to_fid = S.fid;
try ME = [];
    checkpoint('aaa___WBM___test','WBM')
    WBM(S.file01,S.url,options)
catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
    if ~strcmp(ME.identifier,'HJW:WBM:IncompatibleInputs')
        success = false;
    end
end
end
function [success,ME,skipped]=test04
% Trigger 429 error.
success = true;skipped = false;
S = prepare_files;
global trigger_websave_error websavepause pausetime %#ok<GVMIS>

id_FormatSpec = 'MATLAB:webservices:HTTP%dStatusCodeError';
ME = struct;ME.message = 'foo';
ME.identifier = sprintf(id_FormatSpec,429);
trigger_websave_error = ME;
options = struct('err429',struct('CountsAsTry',true,'TimeToWait',min(pausetime,0.5),...
    'PrintAtVerbosityLevel',3),'print_to_fid',S.fid);

then = now; %#ok<TNOW1>
checkpoint('aaa___WBM___test','WBM')
WBM(S.file01,S.url,options)
time_elapsed = (now-then)*60*60*24; %#ok<TNOW1>
pausetime_this_call = 2*websavepause+options.err429.TimeToWait;
pausetime = pausetime+pausetime_this_call; % Track the running total.
if time_elapsed<pausetime_this_call
    try ME = [];
        ME.identifier = 'WBM:test:Error429TestFailed';
        ME.message = sprintf('test failed (%.1f<%.1f=%.5f)',...
            time_elapsed,pausetime,(time_elapsed-pausetime));
        error(ME)
    catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
        success = false;
    end
end
end
function [success,ME,skipped]=test05
% Trigger empty file with silent exit.
success = true;skipped = false;
S = prepare_files;
global trigger_websave_error %#ok<GVMIS>

% Trigger the save option with a 403, then an exit with 2 more 403s.
% This should result in the file not being downloaded, but no obvious error or warning being
% generated.
id_FormatSpec = 'MATLAB:webservices:HTTP%dStatusCodeError';
ME = struct;
ME(1).message = 'foo';ME(1).identifier = 'this ID results in a NaN';
ME(2).message = 'foo';ME(2).identifier = sprintf(id_FormatSpec,403);
ME(3).message = 'foo';ME(3).identifier = sprintf(id_FormatSpec,403);
ME(4).message = 'foo';ME(4).identifier = sprintf(id_FormatSpec,403);
trigger_websave_error = ME;
% Set a lastwarn so a warning can be detected and rethrown as error when it shouldn't have
% occurred.
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
checkpoint('aaa___WBM___test','WBM')
out = WBM([S.current_folder 'doesnt_exist.txt'],S.url,...
    'print_to_fid',S.fid);
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isempty(out) || strcmp(ME.identifier,'HJW:tester:BlankWarning')
    success = false;
end
end
function [success,ME,skipped]=test06
% Successful read from date - autodetect websave/urlwrite.
success = true;skipped = false;
S = prepare_files;
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
out = WBM(S.file02,S.url,struct('date_part',S.date(1:8),...
    'print_to_fid',S.fid));
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isequal(out,S.file02) || ~strcmp(ME.identifier,'HJW:tester:BlankWarning')
    success = false;
end
end
function [success,ME,skipped]=test07
% Successful read from date - use urlwrite.
success = true;skipped = false;
S = prepare_files;
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
out = WBM(S.file02,S.url,...
    struct('date_part',S.date(1:8),'UseURLwrite',true,...
    'print_to_fid',S.fid));
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isequal(out,S.file02) || ~strcmp(ME.identifier,'HJW:tester:BlankWarning')
    success = false;
end
end
function [success,ME,skipped]=test08
% Trigger date error - the file should be deleted.
success = true;skipped = false;
S = prepare_files;
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
checkpoint('aaa___WBM___test','WBM')
out = WBM(S.file01,S.url,'date_part','2000',...
    'print_to_fid',S.fid);
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isempty(out) || exist(S.file01,'file') || ~strcmp(ME.identifier,'HJW:tester:BlankWarning')
    success = false;
end
end
function [success,ME,skipped]=test09
% Trigger missing date.
success = true;skipped = false;
S = prepare_files;
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
out = WBM(S.file03,S.url,'date_part','2000',...
    'print_to_fid',S.fid);
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isequal(out,S.file03) || ~strcmp(ME.identifier,'HJW:WBM:MissingDateWarning')
    success = false;
end
end
function [success,ME,skipped]=test10
% Test offline behavior (trigger a 404 and then simulate isnetavl returning false).
success = true;skipped = false;
S = prepare_files;
global HJW___test_suit___debug_hook_data trigger_websave_error %#ok<GVMIS>
id_FormatSpec = 'MATLAB:webservices:HTTP%dStatusCodeError';
ME = struct;
ME(1).message = 'foo';ME(1).identifier = sprintf(id_FormatSpec,404);
trigger_websave_error = ME;
HJW___test_suit___debug_hook_data = struct('action',{'return','return'},'data',{{true},{true}});
lastwarn('NoWarningOccured','HJW:tester:BlankWarning');
checkpoint('aaa___WBM___test','WBM')
out = WBM(S.file02,S.url,struct('date_part',S.date(1:8),...
    'print_to_fid',S.fid));
ME = struct;[ME.message,ME.identifier] = lastwarn;
if ~isequal(out,S.file02) || ~isempty(ME.identifier)
    success = false;
end
end
function [success,ME,skipped]=test11
% Implement a custom response parameter.
success = true;skipped = false;
response = {'tx',0,'exit'};
S = prepare_files;
try ME = [];
    checkpoint('aaa___WBM___test','WBM')
    WBM(S.file02,S.url,'response',response);
catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
    success = false;
end
end
function [success,ME,skipped]=test12
% Test the request counter file.
success = true;skipped = false;
try ME = [];
    checkpoint('aaa___WBM___test','WBM')
    count = WBM([],[],'WBMRequestCounterFile','read');
    if isnan(count),error('the counter file is corrupted');end
catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
    success = false;
end
end
function out=bsxfun_plus(in1,in2)
% Implicit expansion for plus(), but without any input validation.
persistent type
if isempty(type)
    checkpoint('bsxfun_plus','hasFeature')
    type = ...
        double(hasFeature('ImplicitExpansion')) + ...
        double(hasFeature('bsxfun'));
end
if type==2
    % Implicit expansion is available.
    out = in1+in2;
elseif type==1
    % Implicit expansion is only available with bsxfun.
    out = bsxfun(@plus,in1,in2);
else
    % No implicit expansion, expand explicitly.
    % Determine size and find non-singleton dimensions.
    sz1 = ones(1,max(ndims(in1),ndims(in2)));
    sz2 = sz1;
    sz1(1:ndims(in1)) = size(in1);
    sz2(1:ndims(in2)) = size(in2);
    L = sz1~=1 & sz2~=1;
    if ~isequal(sz1(L),sz2(L))
        error('HJW:bsxfun_plus:arrayDimensionsMustMatch',...
            'Non-singleton dimensions of the two input arrays must match each other.')
    end
    if min([sz1 sz2])==0
        % Construct an empty array of the correct size.
        sz1(sz1==0) = inf;sz2(sz2==0) = inf;
        sz = max(sz1,sz2);
        sz(isinf(sz)) = 0;
        % Create an array and cast it to the correct type.
        out = feval(str2func(class(in1)),zeros(sz));
        return
    end
    in1 = repmat(in1,max(1,sz2./sz1));
    in2 = repmat(in2,max(1,sz1./sz2));
    out = in1+in2;
end
end
function c=char2cellstr(str,LineEnding)
% Split char or uint32 vector to cell (1 cell element per line). Default splits are for CRLF/CR/LF.
% The input data type is preserved.
%
% Since the largest valid Unicode codepoint is 0x10FFFF (i.e. 21 bits), all values will fit in an
% int32 as well. This is used internally to deal with different newline conventions.
%
% The second input is a cellstr containing patterns that will be considered as newline encodings.
% This will not be checked for any overlap and will be processed sequentially.

returnChar = isa(str,'char');
str = int32(str); % Convert to signed, this should not crop any valid Unicode codepoints.

if nargin<2
    % Replace CRLF, CR, and LF with -10 (in that order). That makes sure that all valid encodings
    % of newlines are replaced with the same value. This should even handle most cases of files
    % that mix the different styles, even though such mixing should never occur in a properly
    % encoded file. This considers LFCR as two line endings.
    if any(str==13)
        checkpoint('char2cellstr','PatternReplace')
        str = PatternReplace(str,int32([13 10]),int32(-10));
        str(str==13) = -10;
    end
    str(str==10) = -10;
else
    for n=1:numel(LineEnding)
        checkpoint('char2cellstr','PatternReplace')
        str = PatternReplace(str,int32(LineEnding{n}),int32(-10));
    end
end

% Split over newlines.
newlineidx = [0 find(str==-10) numel(str)+1];
c=cell(numel(newlineidx)-1,1);
for n=1:numel(c)
    s1 = (newlineidx(n  )+1);
    s2 = (newlineidx(n+1)-1);
    c{n} = str(s1:s2);
end

% Return to the original data type.
if returnChar
    for n=1:numel(c),c{n} =   char(c{n});end
else
    for n=1:numel(c),c{n} = uint32(c{n});end
end
end
function tf=CharIsUTF8
% This provides a single place to determine if the runtime uses UTF-8 or UTF-16 to encode chars.
% The advantage is that there is only 1 function that needs to change if and when Octave switches
% to UTF-16. This is unlikely, but not impossible.
persistent persistent_tf
if isempty(persistent_tf)
    checkpoint('CharIsUTF8','ifversion')
    if ifversion('<',0,'Octave','>',0)
        % Test if Octave has switched to UTF-16 by looking if the Euro symbol is losslessly encoded
        % with char.
        % Because we will immediately reset it, setting the state for all warnings to off is fine.
        w = struct('w',warning('off','all'));[w.msg,w.ID] = lastwarn;
        persistent_tf = ~isequal(8364,double(char(8364)));
        warning(w.w);lastwarn(w.msg,w.ID); % Reset warning state.
    else
        persistent_tf = false;
    end
end
tf = persistent_tf;
end
function date_correct=check_date(outfilename,opts,SaveAttempt)
%Check if the date of the downloaded file matches the requested date.
%
% There are two strategies. Strategy 1 is guaranteed to be correct, but isn't always possible.
% Strategy 2 could give an incorrect answer, but is possible in more situations. In the case of
% non-web page files (like e.g. an image), both will fail. This will trigger a missing date error,
% for which you need to input a missing date response (m_date_r).
%
% Strategy 1:
% Rely on the html for the header to provide the date of the currently viewed capture.
% Strategy 2:
% Try a much less clean version: don't rely on the top bar, but look for links that indicate a link
% to the same date in the Wayback Machine. The most common occurring date will be compared with
% date_part.

if ~exist(outfilename,'file')
    date_correct = false;return
    % If the file doesn't exist (not even as a 0 byte file), evidently something went wrong, so
    % retrying or alerting the user is warranted.
end
[m_date_r,date_bounds,print_to] = deal(opts.m_date_r,opts.date_bounds,opts.print_to);
% Loading an unsaved page may result in a capture of the live page (but no save in the WBM). If
% this happens the time in the file will be very close to the current time if this is the case. If
% the save was actually triggered this is valid, but if this is the result of a load attempt, it is
% unlikely this is correct, in which case it is best to trigger the response to an incorrect date:
% attempt an explicit save. Save the time here so any time taken up by file reading and processing
% doesn't bias the estimation of whether or not this is too recent.
if ~SaveAttempt
    checkpoint('check_date','WBM_getUTC_local')
    currentTime = WBM_getUTC_local;
end

% Strategy 1:
% Rely on the html for the header to provide the date of the currently viewed capture.
StringToMatch = '<input type="hidden" name="date" value="';
checkpoint('check_date','readfile')
data = readfile(outfilename);
% A call to ismember would be faster, but it can result in a memory error in ML6.5. The
% undocumented ismembc function only allows numeric, logical, or char inputs (and Octave lacks it),
% so we can't use that on our cellstr either. That is why we need the while loop here.
pos = 0;
checkpoint('check_date','stringtrim')
while pos<=numel(data) && (pos==0 || ~strcmp(stringtrim(data{pos}),'<td class="u" colspan="2">'))
    % This is equivalent to pos=find(ismember(data,'<td class="u" colspan="2">'));
    pos = pos+1;
end
if numel(data)>=(pos+1)
    line = data{pos+1};
    idx = strfind(line,StringToMatch);
    idx = idx+length(StringToMatch)-1;
    date_as_double = str2double(line(idx+(1:14)));
    date_correct = date_bounds.double(1)<=date_as_double && date_as_double<=date_bounds.double(2);
    return
end
% Strategy 2:
% Try a much less clean version: don't rely on the top bar, but look for links that indicate a link
% to the same date in the Wayback Machine. The most common occurring date will be compared with
% date_part.
% The file was already loaded with data=readfile(outfilename);
data = data(:)';data = cell2mat(data);
% The data variable is now a single long string.
idx = strfind(data,'/web/');
if numel(idx)==0
    if m_date_r==0     % Ignore.
        date_correct = true;
        return
    elseif m_date_r==1 % Warning.
        checkpoint('check_date','warning_')
        warning_(print_to,'HJW:WBM:MissingDateWarning',...
            'No date found in file, unable to check date, assuming it is correct.')
        date_correct = true;
        return
    elseif m_date_r==2 % Error.
        checkpoint('check_date','error_')
        error_(print_to,'HJW:WBM:MissingDateError',...
            ['Could not find date. This can mean there is an ',...
            'error in the save. Try saving manually.'])
    end
end
datelist = zeros(size(idx));
data = [data 'abcdefghijklmnopqrstuvwxyz']; % Avoid error in the loop below.
if exist('isstrprop','builtin')
    for n=1:length(idx)
        for m=1:14
            if ~isstrprop(data(idx(n)+4+m),'digit')
                break
            end
        end
        datelist(n) = str2double(data(idx(n)+4+(1:m)));
    end
else
    for n=1:length(idx)
        for m=1:14
            if ~any(double(data(idx(n)+4+m))==(48:57))
                break
            end
        end
        datelist(n) = str2double(data(idx(n)+4+(1:m)));
    end
end
[a,ignore_output,c] = unique(datelist);%#ok<ASGLU> ~
% In some future release, histc might not be supported anymore.
try
    [ignore_output,c2] = max(histc(c,1:max(c)));%#ok<HISTC,ASGLU>
catch
    [ignore_output,c2] = max(accumarray(c,1)); %#ok<ASGLU>
end
date_as_double=a(c2);
date_correct = date_bounds.double(1)<=date_as_double && date_as_double<=date_bounds.double(2);

if ~SaveAttempt
    % Check if the time in the file is too close to the current time to be an actual loaded
    % capture. Setting this too high will result in too many save triggers, but setting it too low
    % will lead to captures being missed on slower systems/networks. 15 seconds seems a reasonable
    % middle ground.
    % One extreme situation to be aware of: it is possible for a save to be triggered, the request
    % arrives successfully and the page is saved, but the response from the server is wrong or
    % missing, triggering an HTTP error. This may then lead to a load attempt. Now we have the
    % situation where there is a save of only several seconds old, but the the SaveAttempt flag is
    % false. The time chosen here must be short enough to account for this situation.
    % Barring such extreme circumstances, page ages below a minute are suspect.
    
    if date_as_double<1e4 % Something is wrong.
        % Trigger missing date response. This shouldn't happen, so offer a graceful exit.
        if m_date_r==0     % Ignore.
            date_correct = true;
            return
        elseif m_date_r==1 % Warning.
            checkpoint('check_date','warning_')
            warning_(print_to,'HJW:WBM:MissingDateWarning',...
                'No date found in file, unable to check date, assuming it is correct.')
            date_correct = true;
            return
        elseif m_date_r==2 % Error.
            checkpoint('check_date','error_')
            error_(print_to,'HJW:WBM:MissingDateError',...
                ['Could not find date. This can mean there is an error in the save.',...
                char(10),'Try saving manually.']) %#ok<CHARTEN>
        end
    end
    
    % Convert the date found to a format that the ML6.5 datenum supports.
    line = sprintf('%014d',date_as_double);
    line = {...
        line(1:4 ),line( 5:6 ),line( 7:8 ),...  %date
        line(9:10),line(11:12),line(13:14)};    %time
    line = str2double(line);
    timediff = (currentTime-datenum(line))*24*60*60; %#ok<DATNM>
    if timediff<10 % This is in seconds.
        date_correct = false;
    elseif timediff<60% This is in seconds.
        checkpoint('check_date','warning_')
        warning_(print_to,'HJW:WBM:LivePageStored',...
            ['The live page might have been saved instead of a capture.',char(10),...
            'Check on the WBM if a capture exists.']) %#ok<CHARTEN>
    end
end
end
function outfilename=check_filename(filename,outfilename)
% It can sometimes happen that the outfilename provided by urlwrite is incorrect. Therefore, we
% need to check if either the outfilename file exists, or the same file, but inside the current
% directory. It is unclear when this would happen, but it might be that this only happens when the
% filename provided only contains a name, and not a full or relative path.
outfilename2 = [pwd filesep filename];
if ~strcmp(outfilename,outfilename2) && ~exist(outfilename,'file') && exist(outfilename2,'file')
    outfilename = outfilename2;
end
end
function [tf,ME]=CheckMexCompilerExistence
% Returns true if a mex compiler is expected to be installed.
% The method used for R2008a and later is fairly slow, so the flag is stored in a file. Run
% ClearMexCompilerExistenceFlag() to reset this test.
%
% This function may result in false positives (e.g. by detecting an installed compiler that doesn't
% work, or if a compiler is required for a specific language).
% False negatives should be rare.
%
% Based on: http://web.archive.org/web/2/http://www.mathworks.com/matlabcentral/answers/99389
% (this link will redirect to the URL with the full title)
%
% The actual test will be performed in a separate function. That way the same persistent can be
% used for different functions containing this check as a subfunction.

persistent tf_ ME_
if isempty(tf_)
    % In some release-runtime combinations addpath has a permanent effect, in others it doesn't. By
    % putting this code in this block, we are trying to keep these queries to a minimum.
    checkpoint('CheckMexCompilerExistence','CreatePathFolder__CheckMexCompilerExistence_persistent')
    [p,ME] = CreatePathFolder__CheckMexCompilerExistence_persistent;
    if ~isempty(ME),tf = false;return,end
    
    fn = fullfile(p,'ClearMexCompilerExistenceFlag.m');
    txt = {...
        'function ClearMexCompilerExistenceFlag',...
        'fn = create_fn;',...
        'if exist(fn,''file''),delete(fn),end',...
        'end',...
        'function fn = create_fn',...
        'v = version;v = v(regexp(v,''[a-zA-Z0-9()\.]''));',...
        'if ~exist(''OCTAVE_VERSION'', ''builtin'')',...
        '    runtime = ''MATLAB'';',...
        '    type = computer;',...
        'else',...
        '    runtime = ''OCTAVE'';',...
        '    arch = computer;arch = arch(1:(min(strfind(arch,''-''))-1));',...
        '    if ispc',...
        '        if strcmp(arch,''x86_64'')  ,type =  ''win_64'';',...
        '        elseif strcmp(arch,''i686''),type =  ''win_i686'';',...
        '        elseif strcmp(arch,''x86'') ,type =  ''win_x86'';',...
        '        else                      ,type = [''win_'' arch];',...
        '        end',...
        '    elseif isunix && ~ismac % Essentially this is islinux',...
        '        if strcmp(arch,''i686'')      ,type =  ''lnx_i686'';',...
        '        elseif strcmp(arch,''x86_64''),type =  ''lnx_64'';',...
        '        else                        ,type = [''lnx_'' arch];',...
        '        end',...
        '    elseif ismac',...
        '        if strcmp(arch,''x86_64''),type =  ''mac_64'';',...
        '        else                    ,type = [''mac_'' arch];',...
        '        end',...
        '    end',...
        'end',...
        'type = strrep(strrep(type,''.'',''''),''-'','''');',...
        'flag = [''flag_'' runtime ''_'' v ''_'' type ''.txt''];',...
        'fn = fullfile(fileparts(mfilename(''fullpath'')),flag);',...
        'end',...
        ''};
    fid = fopen(fn,'wt');fprintf(fid,'%s\n',txt{:});fclose(fid);
    
    checkpoint('CheckMexCompilerExistence','CheckMexCompilerExistence_persistent')
    [tf_,ME_] = CheckMexCompilerExistence_persistent(p);
end
tf = tf_;ME = ME_;
end
function [tf,ME]=CheckMexCompilerExistence_persistent(p)
% Returns true if a mex compiler is expected to be installed.
% The method used for R2008a and later is fairly slow, so the flag is stored in a file. Run
% ClearMexCompilerExistenceFlag() to reset this test.
%
% This function may result in false positives (e.g. by detecting an installed compiler that doesn't
% work, or if a compiler is required for a specific language). False negatives should be rare.
%
% Based on: http://web.archive.org/web/2/http://www.mathworks.com/matlabcentral/answers/99389
% (this link will redirect to the URL with the full title)

persistent tf_ ME_
if isempty(tf_)
    ME_ = create_ME;
    fn  = create_fn(p);
    if exist(fn,'file')
        str = fileread(fn);
        tf_ = strcmp(str,'compiler found');
    else
        % Use evalc to suppress anything printed to the command window.
        [txt,tf_] = evalc(func2str(@get_tf)); %#ok<ASGLU>
        fid = fopen(fn,'w');
        if tf_,fprintf(fid,'compiler found');
        else , fprintf(fid,'compiler not found');end
        fclose(fid);
    end
    
end
tf = tf_;ME = ME_;
end
function fn=create_fn(p)
v = version;v = v(regexp(v,'[a-zA-Z0-9()\.]'));
if ~exist('OCTAVE_VERSION', 'builtin')
    runtime = 'MATLAB';
    type = computer;
else
    runtime = 'OCTAVE';
    arch = computer;arch = arch(1:(min(strfind(arch,'-'))-1));
    if ispc
        if strcmp(arch,'x86_64')  ,type =  'win_64';
        elseif strcmp(arch,'i686'),type =  'win_i686';
        elseif strcmp(arch,'x86') ,type =  'win_x86';
        else                      ,type = ['win_' arch];
        end
    elseif isunix && ~ismac % Essentially this is islinux.
        if strcmp(arch,'i686')      ,type =  'lnx_i686';
        elseif strcmp(arch,'x86_64'),type =  'lnx_64';
        else                        ,type = ['lnx_' arch];
        end
    elseif ismac
        if strcmp(arch,'x86_64'),type =  'mac_64';
        else                    ,type = ['mac_' arch];
        end
    end
end
type = strrep(strrep(type,'.',''),'-','');
flag = ['flag_' runtime '_' v '_' type '.txt'];
fn = fullfile(p,flag);
end
function ME_=create_ME
msg = {...
    'No selected compiler was found.',...
    'Please make sure a supported compiler is installed and set up.',...
    'Run mex(''-setup'') for version-specific documentation.',...
    '',...
    'Run ClearMexCompilerExistenceFlag() to reset this test.'};
msg = sprintf('\n%s',msg{:});msg = msg(2:end);
ME_ = struct(...
    'identifier','HJW:CheckMexCompilerExistence:NoCompiler',...
    'message',msg);
end
function tf=get_tf
[isOctave,v_num] = ver_info;
if isOctave
    % Octave normally comes with a compiler out of the box, but for some methods of installation an
    % additional package may be required.
    tf = ~isempty(try_file_compile);
elseif v_num>=706 % ifversion('>=','R2008a')
    % Just try to compile a MWE. Getting the configuration is very slow. On Windows this is a bad
    % idea, as it starts an interactive prompt. Because this function is called with evalc, that
    % means this function will hang.
    if ispc, TryNormalCheck  = true;
    else,[cc,TryNormalCheck] = try_file_compile;
    end
    if TryNormalCheck
        % Something strange happened, so try the normal check anyway.
        try cc = mex.getCompilerConfigurations;catch,cc=[];end
    end
    tf = ~isempty(cc);
else
    if ispc,ext = '.bat';else,ext = '.sh';end
    tf = exist(fullfile(prefdir,['mexopts' ext]),'file');
end
end
function [isOctave,v_num]=ver_info
% This is a compact and feature-poor equivalent of ifversion.
% To save space this can be used as an alternative.
% Example: R2018a is 9.4, so v_num will be 904.
isOctave = exist('OCTAVE_VERSION', 'builtin');
v_num = version;
ii = strfind(v_num,'.');if numel(ii)~=1,v_num(ii(2):end) = '';ii = ii(1);end
v_num = [str2double(v_num(1:(ii-1))) str2double(v_num((ii+1):end))];
v_num = v_num(1)+v_num(2)/100;v_num = round(100*v_num);
end
function [cc,TryNormalCheck]=try_file_compile
TryNormalCheck = false;
try
    [p,n] = fileparts(tempname);e='.c';
    n = n(regexp(n,'[a-zA-Z0-9_]')); % Keep only valid characters.
    n = ['test_fun__' n(1:min(15,end))];
    fid = fopen(fullfile(p,[n e]),'w');
    fprintf(fid,'%s\n',...
        '#include "mex.h"',...
        'void mexFunction(int nlhs, mxArray *plhs[],',...
        '  int nrhs, const mxArray *prhs[]) {',...
        '    plhs[0]=mxCreateString("compiler works");',...
        '    return;',...
        '}');
    fclose(fid);
catch
    % If there is a write error in the temp dir, something is wrong.
    % Just try the normal check.
    cc = [];TryNormalCheck = true;return
end
try
    current = cd(p);
catch
    % If the cd fails, something is wrong here. Just try the normal check.
    cc = [];TryNormalCheck = true;return
end
try
    mex([n e]);
    cc = feval(str2func(n));
    clear(n); % Clear to remove file lock.
    cd(current);
catch
    % Either the mex or the feval failed. That means we can safely assume no working compiler is
    % present. The normal check should not be required.
    cd(current);
    cc = [];TryNormalCheck = false;return
end
end
function [p,ME]=CreatePathFolder__CheckMexCompilerExistence_persistent
% Try creating a folder in either the tempdir or a persistent folder and try adding it to the path
% (if it is not already in there). If the folder is not writable, the current folder will be used.
try
    ME = [];
    checkpoint('CreatePathFolder__CheckMexCompilerExistence_persistent','GetWritableFolder')
    p = fullfile(GetWritableFolder,'FileExchange','CheckMexCompilerExistence');
    if isempty(strfind([path ';'],[p ';'])) %#ok<STREMP>
        % This means f is not on the path.
        checkpoint('CreatePathFolder__CheckMexCompilerExistence_persistent','makedir')
        if ~exist(p,'dir'),makedir(p);end
        addpath(p,'-end');
    end
catch
    ME = struct('identifier','HJW:CheckMexCompilerExistence:PathFolderFail',...
        'message','Creating a folder on the path to store the compiled function and flag failed.');
end
end
function varargout=debug_hook(varargin)
% This function can be used to return several outputs (including warnings and errors), determined
% by the global variable HJW___test_suit___debug_hook_data.
%
% Every iteration the first element is removed from HJW___test_suit___debug_hook_data.
%
% When HJW___test_suit___debug_hook_data is empty or when returning a warning this functions
% returns the input unchanged.
global HJW___test_suit___debug_hook_data %#ok<GVMIS>
if isempty(HJW___test_suit___debug_hook_data)
    varargout = varargin;return
end

element = HJW___test_suit___debug_hook_data(1);
HJW___test_suit___debug_hook_data(1) = [];

switch element.action
    case 'return'
        varargout = element.data;
    case 'warning'
        varargout = varargin;
        warning(element.data{:})
    case 'error'
        error(element.data{:})
    case 'warning_'
        varargout = varargin;
        checkpoint('debug_hook','warning_')
        warning_(element.data{:})
    case 'error_'
        checkpoint('debug_hook','error_')
        error_(element.data{:})
end
end
function error_(options,varargin)
%Print an error to the command window, a file and/or the String property of an object.
% The error will first be written to the file and object before being actually thrown.
%
% Apart from controlling the way an error is written, you can also run a specific function. The
% 'fcn' field of the options must be a struct (scalar or array) with two fields: 'h' with a
% function handle, and 'data' with arbitrary data passed as third input. These functions will be
% run with 'error' as first input. The second input is a struct with identifier, message, and stack
% as fields. This function will be run with feval (meaning the function handles can be replaced
% with inline functions or anonymous functions).
%
% The intention is to allow replacement of every error(___) call with error_(options,___).
%
% NB: the function trace that is written to a file or object may differ from the trace displayed by
% calling the builtin error/warning functions (especially when evaluating code sections). The
% calling code will not be included in the constructed trace.
%
% There are two ways to specify the input options. The shorthand struct described below can be used
% for fast repeated calls, while the input described below allows an input that is easier to read.
% Shorthand struct:
%  options.boolean.IsValidated: if true, validation is skipped
%  options.params:              optional parameters for error_ and warning_, as explained below
%  options.boolean.con:         only relevant for warning_, ignored
%  options.fid:                 file identifier for fprintf (array input will be indexed)
%  options.boolean.fid:         if true print error to file
%  options.obj:                 handle to object with String property (array input will be indexed)
%  options.boolean.obj:         if true print error to object (options.obj)
%  options.fcn                  struct (array input will be indexed)
%  options.fcn.h:               handle of function to be run
%  options.fcn.data:            data passed as third input to function to be run (optional)
%  options.boolean.fnc:         if true the function(s) will be run
%
% Full input description:
%   print_to_con:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A logical that controls whether warnings and other output will be printed to the command
%      window. Errors can't be turned off. [default=true;]
%      Specifying print_to_fid, print_to_obj, or print_to_fcn will change the default to false,
%      unless parsing of any of the other exception redirection options results in an error.
%   print_to_fid:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The file identifier where console output will be printed. Errors and warnings will be
%      printed including the call stack. You can provide the fid for the command window (fid=1) to
%      print warnings as text. Errors will be printed to the specified file before being actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_obj:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The handle to an object with a String property, e.g. an edit field in a GUI where console
%      output will be printed. Messages with newline characters (ignoring trailing newlines) will
%      be returned as a cell array. This includes warnings and errors, which will be printed
%      without the call stack. Errors will be written to the object before the error is actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_fcn:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A struct with a function handle, anonymous function or inline function in the 'h' field and
%      optionally additional data in the 'data' field. The function should accept three inputs: a
%      char array (either 'warning' or 'error'), a struct with the message, id, and stack, and the
%      optional additional data. The function(s) will be run before the error is actually thrown.
%      [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_params:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      This struct contains the optional parameters for the error_ and warning_ functions.
%      Each field can also be specified as ['print_to_option_' parameter_name]. This can be used to
%      avoid nested struct definitions.
%      ShowTraceInMessage:
%        [default=false] Show the function trace in the message section. Unlike the normal results
%        of rethrow/warning, this will not result in clickable links.
%      WipeTraceForBuiltin:
%        [default=false] Wipe the trace so the rethrow/warning only shows the error/warning message
%        itself. Note that the wiped trace contains the calling line of code (along with the
%        function name and line number), while the generated trace does not.
%
% Syntax:
%   error_(options,msg)
%   error_(options,msg,A1,...,An)
%   error_(options,id,msg)
%   error_(options,id,msg,A1,...,An)
%   error_(options,ME)               %equivalent to rethrow(ME)
%
% Examples options struct:
%   % Write to a log file:
%   opts = struct;opts.fid = fopen('log.txt','wt');
%   % Display to a status window and bypass the command window:
%   opts = struct;opts.boolean.con = false;opts.obj = uicontrol_object_handle;
%   % Write to 2 log files:
%   opts = struct;opts.fid = [fopen('log2.txt','wt') fopen('log.txt','wt')];

persistent this_fun
if isempty(this_fun),this_fun = func2str(@error_);end

% Parse options struct, allowing an empty input to revert to default.
if isempty(options),options = struct;end
checkpoint('error_','parse_warning_error_redirect_options')
options                    = parse_warning_error_redirect_options(  options  );
checkpoint('error_','parse_warning_error_redirect_inputs')
[id,msg,stack,trace,no_op] = parse_warning_error_redirect_inputs( varargin{:});
if no_op,return,end
forced_trace = trace;
if options.params.ShowTraceInMessage
    msg = sprintf('%s\n%s',msg,trace);
end
ME = struct('identifier',id,'message',msg,'stack',stack);
if options.params.WipeTraceForBuiltin
    ME.stack = stack('name','','file','','line',[]);
end

% Print to object.
if options.boolean.obj
    msg_ = msg;while msg_(end)==10,msg_(end) = '';end % Crop trailing newline.
    if any(msg_==10)  % Parse to cellstr and prepend 'Error: '.
        checkpoint('error_','char2cellstr')
        msg_ = char2cellstr(['Error: ' msg_]);
    else              % Only prepend 'Error: '.
        msg_ = ['Error: ' msg_];
    end
    for OBJ=reshape(options.obj,1,[])
        try set(OBJ,'String',msg_);catch,end
    end
end

% Print to file.
if options.boolean.fid
    T = datestr(now,31); %#ok<DATST,TNOW1> Print the time of the error to the log as well.
    for FID=reshape(options.fid,1,[])
        try fprintf(FID,'[%s] Error: %s\n%s',T,msg,trace);catch,end
    end
end

% Run function.
if options.boolean.fcn
    if ismember(this_fun,{stack.name})
        % To prevent an infinite loop, trigger an error.
        error('prevent recursion')
    end
    ME_ = ME;ME_.trace = forced_trace;
    for FCN=reshape(options.fcn,1,[])
        if isfield(FCN,'data')
            try feval(FCN.h,'error',ME_,FCN.data);catch,end
        else
            try feval(FCN.h,'error',ME_);catch,end
        end
    end
end

% Actually throw the error.
rethrow(ME)
end
function [valid,filename]=filename_is_valid(filename)
% Check if the file name and path are valid (non-empty char or scalar string).
valid=true;
persistent forbidden_names
if isempty(forbidden_names)
    forbidden_names = {'CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7',...
        'COM8','COM9','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9'};
end
if isa(filename,'string') && numel(filename)==1
    % Convert a scalar string to a char array.
    filename = char(filename);
end
if ~isa(filename,'char') || numel(filename)==0
    valid = false;return
else
    % File name is indeed a char. Do a check if there are characters that can't exist in a normal
    % file name. The method used here is not fool-proof, but should cover most use cases and
    % operating systems.
    [fullpath,fn,ext] = fileparts(filename); %#ok<ASGLU>
    fn = [fn,ext];
    if      any(ismember([char(0:31) '<>:"/\|?*'],fn)) || ...
            any(ismember(forbidden_names,upper(fn))) || ... % (ismember is case sensitive)
            any(fn(end)=='. ')
        valid = false;return
    end
end
end
function varargout=findND(v000,varargin),if~(isnumeric(v000)||islogical(v000))||numel(v000)==0,...
error('HJW:findND:FirstInput',...
'Expected first input (X) to be a non-empty numeric or logical array.'),end,switch nargin,case ...
1,v001='first';v002=inf;case 2,v001='first';v002=varargin{1};
if~(isnumeric(v002)||islogical(v002))||numel(v002)~=1||any(v002<0),...
error('HJW:findND:SecondInput',...
'Expected second input (K) to be a positive numeric or logical scalar.'),end,case 3,v002=...
varargin{1};if~(isnumeric(v002)||islogical(v002))||numel(v002)~=1||any(v002<0),...
error('HJW:findND:SecondInput',...
'Expected second input (K) to be a positive numeric or logical scalar.'),end,v001=varargin{2};
if isa(v001,'string')&&numel(v001)==1,v001=char(v001);end,if~isa(v001,'char')||~(strcmpi(v001,...
'first')||strcmpi(v001,'last')),error('HJW:findND:ThirdInput',...
'Third input must be either ''first'' or ''last''.'),end,v001=lower(v001);otherwise,...
error('HJW:findND:InputNumber','Incorrect number of inputs.'),end,if ...
nargout>1&&nargout<ndims(v000),error('HJW:findND:Output',...
'Incorrect number of output arguments.'),end,persistent v003,if isempty(v003),v003=...
findND_f00('<',7,'Octave','<',3);end,varargout=cell(max(1,nargout),1);if v003,if ...
nargout>ndims(v000),[v004,v005,v006]=find(v000(:));if length(v004)>v002,if strcmp(v001,'first'),...
v004=v004(1:v002);v006=v006(1:v002);else,v004=v004((end-v002+1):end);v006=...
v006((end-v002+1):end);end,end,[varargout{1:(end-1)}]=ind2sub(size(v000),v004);varargout{end}=...
v006;else,v004=find(v000);if numel(v004)>v002,if strcmp(v001,'first'),v004=v004(1:v002);else,...
v004=v004((end-v002+1):end);end,end,[varargout{:}]=ind2sub(size(v000),v004);end,else,if ...
nargout>ndims(v000),[v004,v005,v006]=find(v000(:),v002,v001);[varargout{1:(end-1)}]=...
ind2sub(size(v000),v004);varargout{end}=v006;else,v004=find(v000,v002,v001);[varargout{:}]=...
ind2sub(size(v000),v004);end,end,end
function v000=findND_f00(v001,v002,v003,v004,v005),persistent v006 v007 v008,if isempty(v006),...
v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);v007={'R13' 605;
'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;'R2006a' 702;
'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;'R2009b' 709;
'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;'R2013a' 801;
'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;'R2016b' 901;
'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;'R2020a' 908;
'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913};end,if v008,if nargin==2,...
warning('HJW:ifversion:NoOctaveTest',['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);else,[v001,v009]=deal(v004,v005);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);end,else,if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=...
v006 < v009;case'<=',v000=v006 <=v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end

function [str,stack]=get_trace(skip_layers,stack)
if nargin==0,skip_layers = 1;end
if nargin<2, stack = dbstack;end
stack(1:skip_layers) = [];

% Parse the ML6.5 style of dbstack (the name field includes full file location).
if ~isfield(stack,'file')
    for n=1:numel(stack)
        tmp = stack(n).name;
        if strcmp(tmp(end),')')
            % Internal function.
            ind = strfind(tmp,'(');
            name = tmp( (ind(end)+1):(end-1) );
            file = tmp(1:(ind(end)-2));
        else
            file = tmp;
            [ignore,name] = fileparts(tmp); %#ok<ASGLU>
        end
        [ignore,stack(n).file] = fileparts(file); %#ok<ASGLU>
        stack(n).name = name;
    end
end

% Parse Octave style of dbstack (the file field includes full file location).
checkpoint('get_trace','ifversion')
persistent isOctave,if isempty(isOctave),isOctave=ifversion('<',0,'Octave','>',0);end
if isOctave
    for n=1:numel(stack)
        [ignore,stack(n).file] = fileparts(stack(n).file); %#ok<ASGLU>
    end
end

% Create the char array with a (potentially) modified stack.
s = stack;
c1 = '>';
str = cell(1,numel(s)-1);
for n=1:numel(s)
    [ignore_path,s(n).file,ignore_ext] = fileparts(s(n).file); %#ok<ASGLU>
    if n==numel(s),s(n).file = '';end
    if strcmp(s(n).file,s(n).name),s(n).file = '';end
    if ~isempty(s(n).file),s(n).file = [s(n).file '>'];end
    str{n} = sprintf('%c In %s%s (line %d)\n',c1,s(n).file,s(n).name,s(n).line);
    c1 = ' ';
end
str = horzcat(str{:});
end
function v000=getUTC(v001),if nargin==0,v002=getUTC_f02;if isempty(v002),v002=getUTC_f03;end,if ...
isempty(v002),v002=getUTC_f13;end,if isempty(v002),error('HJW:getUTC:TimeReadFailed',...
['All methods of retrieving the UTC timestamp failed.\nEnsure you ',...
'have write access to the current folder and check your internet connection.']),end,else,switch ...
v001,case 1,v002=getUTC_f03(false);case 2,v002=getUTC_f13;case 3,v002=getUTC_f02;otherwise,if ...
isa(v001,'char'),v002=getUTC_f02(v001);else,error('non-implemented override'),end,end,end,v003=...
v002/(24*60*60);v000=v003+datenum(1970,1,1);end
function[v004,v003]=getUTC_f00,persistent v000 v001,if isempty(v000),[v002,v003]=getUTC_f36;
if~isempty(v003),v004=false;return,end,v005=fullfile(v002,'ClearMexCompilerExistenceFlag.m');
v006={'function ClearMexCompilerExistenceFlag','fn = create_fn;',...
'if exist(fn,''file''),delete(fn),end','end','function fn = create_fn',...
'v = version;v = v(regexp(v,''[a-zA-Z0-9()\.]''));',...
'if ~exist(''OCTAVE_VERSION'', ''builtin'')','    runtime = ''MATLAB'';','    type = computer;',...
'else','    runtime = ''OCTAVE'';',...
'    arch = computer;arch = arch(1:(min(strfind(arch,''-''))-1));','    if ispc',...
'        if strcmp(arch,''x86_64'')  ,type =  ''win_64'';',...
'        elseif strcmp(arch,''i686''),type =  ''win_i686'';',...
'        elseif strcmp(arch,''x86'') ,type =  ''win_x86'';',...
'        else                      ,type = [''win_'' arch];','        end',...
'    elseif isunix && ~ismac % Essentially this is islinux',...
'        if strcmp(arch,''i686'')      ,type =  ''lnx_i686'';',...
'        elseif strcmp(arch,''x86_64''),type =  ''lnx_64'';',...
'        else                        ,type = [''lnx_'' arch];','        end','    elseif ismac',...
'        if strcmp(arch,''x86_64''),type =  ''mac_64'';',...
'        else                    ,type = [''mac_'' arch];','        end','    end','end',...
'type = strrep(strrep(type,''.'',''''),''-'','''');',...
'flag = [''flag_'' runtime ''_'' v ''_'' type ''.txt''];',...
'fn = fullfile(fileparts(mfilename(''fullpath'')),flag);','end',''};v007=fopen(v005,'wt');
fprintf(v007,'%s\n',v006{:});fclose(v007);[v000,v001]=getUTC_f01(v002);end,v004=v000;v003=v001;
end
function[v000,v001]=getUTC_f01(v002),persistent v003 v004,if isempty(v003),v004=getUTC_f20;v005=...
getUTC_f07(v002);if exist(v005,'file'),v006=fileread(v005);v003=strcmp(v006,'compiler found');
else,[v007,v003]=evalc(func2str(@getUTC_f18));v008=fopen(v005,'w');if v003,fprintf(v008,...
'compiler found');else,fprintf(v008,'compiler not found');end,fclose(v008);end,end,v000=v003;
v001=v004;end
function[v000,v001]=getUTC_f02(v002,v003),if nargin==2,v001=v003;else,if nargin>=...
1&&~isempty(v002),v004=v002;else,v004=getUTC_f23;end,try v001=getUTC_f22;try if v004,v001=...
v001.online;else,error('trigger offline version'),end,catch,v001=v001.offline;end,catch,...
warning('determination of call type failed'),v000=[];return,end,end,if nargout==2,try v001=...
getUTC_f22;catch,warning('determination of call type failed'),end,v000=[];return,end,try switch ...
v001,case'Unix',v000=getUTC_f09;case'NTP_win',v000=getUTC_f10;case'WMIC_sys',v000=getUTC_f11;
case'WMIC_bat',v000=getUTC_f16;case'PS_get_date',v000=getUTC_f08;otherwise,...
error('call type not implemented'),end,catch,v000=[];end,end
function v000=getUTC_f03(v001),if nargin==0,v001=true;end,persistent v002 v003 v004 v005 v006 ...
v007,if isempty(v002),v003=fullfile(getUTC_f15,'FileExchange','getUTC');try if ...
isempty(strfind([path ';'],[v003 ';'])),if~exist(v003,'dir'),getUTC_f27(v003);end,addpath(v003,...
'-end');end,catch,end,v004='utc_time';[v007,v004]=getUTC_f28(v004);try v005=str2func(v004);
catch,end,v006=5;v002={'#include "mex.h"';'#include "time.h"';'';
'/* Abraham Cohn,  3/17/2005 */';'/* Philips Medical Systems */';'';
'void mexFunction(int nlhs, mxArray *plhs[], int nrhs,';
'                 const mxArray *prhs[])';'{';'  time_t utc;';'  ';'  if (nlhs > 1) {';
'    mexErrMsgTxt("Too many output arguments");';'  }';'  ';
'  /* Here is a nice ref: www.cplusplus.com/ref/ctime/time.html */';'  time(&utc);';
'  /* mexPrintf("UTC time in local zone: %s",ctime(&utc)); */';
'  /* mexPrintf("UTC time in GMT: %s",asctime(gmtime(&utc))); */';'  ';
'  /* Create matrix for the return argument. */';
'  plhs[0] = mxCreateDoubleScalar((double)utc);';'   ';'}'};end,try v000=feval(v005);catch,if ...
exist(v007,'file'),if v001,v008=lasterror;rethrow(v008);else,v000=[];return,end,end,...
if~getUTC_f00,v006=0;v000=[];return,end,v006=v006-1;if v006<0,v000=[];return,end,if ...
getUTC_f35(v003),v009=v003;else,v009=pwd;end,v010=cd(v009);try if~exist(fullfile(v009,[v004 ...
'.c']),'file'),v011=fopen(fullfile(v009,[v004 '.c']),'w');for v012=1:numel(v002),fprintf(v011,...
'%s\n',v002{v012});end,fclose(v011);end,try v013=evalc(['mex([ ''' v004 '.c'']);']);catch,end,...
for v014={'c','o'},v015=fullfile(v009,[v004 '.' v014{1}]);if exist(v015,'file'),delete(v015),...
end,end,catch,end,cd(v010);if exist(v007,'file'),v005=str2func(v004);v000=getUTC_f03(v001);else,...
v000=[];end,end,end
function v000=getUTC_f04(v001,v002,v003,v004,v005),if nargin<2||nargout>1,...
error('incorrect number of input/output arguments'),end,persistent v006 v007 v008,if ...
isempty(v006),v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);
v007={'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;
'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;
'R2009b' 709;'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;
'R2016b' 901;'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;
'R2020a' 908;'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913;'R2023a' 914;
'R2023b' 2302};end,if v008,if nargin==2,warning('HJW:ifversion:NoOctaveTest',...
['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*getUTC_f21(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if ...
sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=0.1*v009+0.9*getUTC_f21(v009);v009=...
round(100*v009);else,[v001,v009]=deal(v004,v005);v009=0.1*v009+0.9*getUTC_f21(v009);v009=...
round(100*v009);end,else,if isnumeric(v002),v009=getUTC_f21(v002*100);if mod(v009,10)==0,v009=...
getUTC_f21(v002)*100+mod(v002,1)*10;end,else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=...
v006 < v009;case'<=',v000=v006 <=v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end
function v001=getUTC_f05,persistent v000,if~ispc,v001=[];return,end,if isempty(v000),try [v002,...
v003]=system('ver');v004={'[^0-9]*(\d*).*','$1','tokenize'};if getUTC_f04('>=',7,'Octave','<',...
0),v004(end)=[];end,v000=str2double(regexprep(v003,v004{:}));catch,try [v002,v003]=...
system('systeminfo');v005=1+strfind(v003,':');v005=v005(3);v006=-1+strfind(v003,'.');
v006(v006<v005)=[];v000=str2double(v003(v005:v006(1)));catch,v000=[];end,end,end,v001=v000;end
function v000=getUTC_f06(v001,v002),if nargin<1,v001='';end,if~isempty(v001),v001=[v001 '_'];
end,if nargin<2,v002='';else,if~strcmp(v002(1),'.'),v002=['.' v002];end,end,v000=tempname;[v003,...
v004]=fileparts(v000);v000=fullfile(v003,[v001 v004 v002]);end
function v000=getUTC_f07(v001),v002=version;v002=v002(regexp(v002,'[a-zA-Z0-9()\.]'));
if~exist('OCTAVE_VERSION','builtin'),v003='MATLAB';v004=computer;else,v003='OCTAVE';v005=...
computer;v005=v005(1:(min(strfind(v005,'-'))-1));if ispc,if strcmp(v005,'x86_64'),v004='win_64';
elseif strcmp(v005,'i686'),v004='win_i686';elseif strcmp(v005,'x86'),v004='win_x86';else,v004=...
['win_' v005];end,elseif isunix&&~ismac,if strcmp(v005,'i686'),v004='lnx_i686';elseif ...
strcmp(v005,'x86_64'),v004='lnx_64';else,v004=['lnx_' v005];end,elseif ismac,if strcmp(v005,...
'x86_64'),v004='mac_64';else,v004=['mac_' v005];end,end,end,v004=strrep(strrep(v004,'.',''),'-',...
'');v006=['flag_' v003 '_' v002 '_' v004 '.txt'];v000=fullfile(v001,v006);end
function v003=getUTC_f08,[v000,v001]=system(['powershell $a=get-date;',...
'$a.ToUniversalTime().ToString(''yyyyMMddHHmmss'')']);v001(v001<48|v001>57)='';v002=...
mat2cell(v001,1,[4 2 2,2 2 2]);v002=num2cell(str2double(v002));v003=...
(datenum(v002{:})-datenum(1970,1,1))*24*60*60;end
function v002=getUTC_f09,[v000,v001]=system('date +%s');v002=str2double(v001);end
function v005=getUTC_f10,persistent v000,if isempty(v000),v000=(datenum(1601,1,1)-datenum(1970,...
1,1))*(24*60*60);end,[v001,v002]=...
system('w32tm /stripchart /computer:time.google.com /dataonly /samples:1 /rdtsc');v003=...
getUTC_f32(v002,',\s?([0-9]+)','tokens');v004=str2double(v003{end});v005=v000+v004/1e7;end
function v002=getUTC_f11,[v000,v001]=system('wmic os get LocalDateTime /value');v002=...
getUTC_f12(v001);end
function v000=getUTC_f12(v001),v001=v001(v001>=43&v001<=57);v002=mat2cell(v001(1:21),1,[4 2 2,2 ...
2 2+1+6]);v002=str2double(v002);v002(5)=v002(5)-str2double(v001(22:end));v002=num2cell(v002);
v000=(datenum(v002{:})-datenum(1970,1,1))*24*60*60;end
function v001=getUTC_f13,persistent v000,if isempty(v000),try v000=~isempty(which(func2str(...
@webread)));catch,v000=false;end,end,if~getUTC_f23,v001=[];return,end,for v002=1:3,try if v000,...
v003=webread('http://www.utctime.net/utc-timestamp');else,v003=...
urlread('http://www.utctime.net/utc-timestamp');end,break,catch,end,end,try v003(v003==' ')='';
v004='vartimestamp=';v005=strfind(v003,v004)+numel(v004);v006=strfind(v003,';')-1;
v006(v006<v005)=[];v001=str2double(v003(v005:v006(1)));catch,v001=[];end,end
function[v000,v001,v002]=getUTC_f14(varargin),v000=false;v002=struct('identifier','','message',...
'');persistent v003,if isempty(v003),v003.ForceStatus=false;v003.ErrorOnNotFound=false;
v003.root_folder_list={getUTC_f17;fullfile(tempdir,'MATLAB');''};end,if nargin==2,v001=v003;
v000=true;return,end,[v001,v004]=getUTC_f29(v003,varargin{:});for v005=1:numel(v004),v006=...
v004{v005};v007=v001.(v006);v002.identifier=['HJW:GetWritableFolder:incorrect_input_opt_' ...
lower(v006)];switch v006,case'ForceStatus',try if~isa(v003.root_folder_list{v007},'char'),...
error('the indexing must have failed, trigger error'),end,catch,v002.message=...
sprintf('Invalid input: expected a scalar integer between 1 and %d.',...
numel(v003.root_folder_list));return,end,case'ErrorOnNotFound',[v008,v001.ErrorOnNotFound]=...
getUTC_f33(v007);if~v008,v002.message='ErrorOnNotFound should be either true or false.';return,...
end,otherwise,v002.message=sprintf('Name,Value pair not recognized: %s.',v006);v002.identifier=...
'HJW:GetWritableFolder:incorrect_input_NameValue';return,end,end,v000=true;v002=[];end
function[v000,v001]=getUTC_f15(varargin),[v002,v003,v004]=getUTC_f14(varargin{:});if~v002,...
rethrow(v004),else,[v005,v006,v007]=deal(v003.ForceStatus,v003.ErrorOnNotFound,...
v003.root_folder_list);end,v007{end}=pwd;if v005,v001=v005;v000=fullfile(v007{v001},...
'PersistentFolder');try if~exist(v000,'dir'),getUTC_f27(v000);end,catch,end,return,end,v001=1;
v000=v007{v001};try if~exist(v000,'dir'),getUTC_f27(v000);end,catch,end,if~getUTC_f35(v000),...
v001=2;v000=v007{v001};try if~exist(v000,'dir'),getUTC_f27(v000);end,catch,end,...
if~getUTC_f35(v000),v001=3;v000=v007{v001};end,end,v000=fullfile(v000,'PersistentFolder');try ...
if~exist(v000,'dir'),getUTC_f27(v000);end,catch,end,if~getUTC_f35(v000),if v006,...
error('HJW:GetWritableFolder:NoWritableFolder',...
'This function was unable to find a folder with write permissions.'),else,v001=0;v000='';end,...
end,end
function v006=getUTC_f16,v000=1;v001=[tempname,'.bat'];v002=[tempname,'.txt'];v003=fopen(v001,...
'w');fprintf(v003,...
'%%systemroot%%\\system32\\wbem\\wmic os get LocalDateTime /value > "%s"\r\nexit',v002);
fclose(v003);system(['start /min "" cmd /c "' v001 '"']);v004=now;pause(v000),v005=...
fileread(v002);try delete(v001);catch,end,try delete(v002);catch,end,v006=...
getUTC_f12(v005)+(now-v004)*24*60*60;end
function v002=getUTC_f17,if ispc,[v000,v001]=system('echo %APPDATA%');v001(v001<14)='';v002=...
fullfile(v001,'MathWorks','MATLAB Add-Ons');else,[v000,v003]=system('echo $HOME');v003(v003<14)=...
'';v002=fullfile(v003,'Documents','MATLAB','Add-Ons');end,end
function v002=getUTC_f18,[v000,v001]=getUTC_f19;if v000,v002=~isempty(getUTC_f34);elseif v001>=...
706,if ispc,v003=true;else,[v004,v003]=getUTC_f34;end,if v003,try v004=...
mex.getCompilerConfigurations;catch,v004=[];end,end,v002=~isempty(v004);else,if ispc,v005=...
'.bat';else,v005='.sh';end,v002=exist(fullfile(prefdir,['mexopts' v005]),'file');end,end
function[v000,v001]=getUTC_f19,v000=exist('OCTAVE_VERSION','builtin');v001=version;v002=...
strfind(v001,'.');if numel(v002)~=1,v001(v002(2):end)='';v002=v002(1);end,v001=...
[str2double(v001(1:(v002-1))) str2double(v001((v002+1):end))];v001=v001(1)+v001(2)/100;v001=...
round(100*v001);end
function v001=getUTC_f20,v000={'No selected compiler was found.',...
'Please make sure a supported compiler is installed and set up.',...
'Run mex(''-setup'') for version-specific documentation.','',...
'Run ClearMexCompilerExistenceFlag() to reset this test.'};v000=sprintf('\n%s',v000{:});v000=...
v000(2:end);v001=struct('identifier','HJW:CheckMexCompilerExistence:NoCompiler','message',v000);
end
function v000=getUTC_f21(v000),v000=fix(v000+eps*1e3);end
function v003=getUTC_f22,persistent v000,if isempty(v000),if~ispc,v000=struct('offline','Unix',...
'online','Unix');else,if getUTC_f05<=5,v000='WMIC_bat';elseif getUTC_f05>=10,[v001,v002]=...
system('wmic /?');if v001,v000='PS_get_date';else,v000='WMIC_sys';end,else,v000='WMIC_sys';end,...
v000=struct('offline',v000,'online','NTP_win');end,end,v003=v000;end
function[v000,v001]=getUTC_f23(v002),if nargin==0,v003=false;else,[v004,v005]=getUTC_f33(v002);
v003=v004&&v005;end,if v003,[v000,v001]=getUTC_f26;return,end,v003=getUTC_f25;if isempty(v003),...
v000=0;v001=0;else,if v003,[v000,v001]=getUTC_f26;else,[v000,v001]=getUTC_f24;end,end,end
function[v003,v006]=getUTC_f24,if ispc,try [v000,v001]=system('ping -n 1 8.8.8.8');v002=...
v001(strfind(v001,' = ')+3);v002=v002(1:3);if~strcmp(v002,'110'),error('trigger error'),else,...
v003=1;[v004,v005]=regexp(v001,' [0-9]+ms');v006=v001((v004(1)+1):(v005(1)-2));v006=...
str2double(v006);end,catch,v003=0;v006=0;end,elseif isunix,try [v000,v001]=...
system('ping -c 1 8.8.8.8');v007=regexp(v001,', [01] ');if v001(v007+2)~='1',...
error('trigger error'),else,v003=1;[v004,v005]=regexp(v001,'=[0-9.]+ ms');v006=...
v001((v004(1)+1):(v005(1)-2));v006=str2double(v006);end,catch,v003=0;v006=0;end,else,...
error('How did you even get Matlab to work?'),end,end
function[v001,v002,v003]=getUTC_f25,persistent v000,if~isempty(v000),v001=v000;return,end,[v002,...
v003]=getUTC_f24;if v002,v000=false;v001=false;return,end,[v002,v003]=getUTC_f26;if v002,v000=...
true;v001=true;return,end,v001=[];end
function[v004,v005]=getUTC_f26,persistent v000,if isempty(v000),try v001=...
isempty(which(func2str(@webread)));catch,v001=true;end,v000=~v001;end,try v002=now;if v000,v003=...
webread('http://google.com');else,v003=urlread('http://google.com');end,v004=1;v005=...
(now-v002)*24*3600*1000;catch,v004=0;v005=0;end,end
function varargout=getUTC_f27(v000),if exist(v000,'dir'),return,end,persistent v001,if ...
isempty(v001),v001=getUTC_f04('<','R2007b','Octave','<',0);end,varargout=cell(1,nargout);if ...
v001,[v002,v003]=fileparts(v000);[varargout{:}]=mkdir(v002,v003);else,[varargout{:}]=...
mkdir(v000);end,end
function[v000,v001]=getUTC_f28(v001),persistent v002,if isempty(v002),v003=version;v004=...
[strfind(v003,'.') numel(v003)];v003=sprintf('%02d.%02d',str2double({v003(1:(v004(1)-1)),...
v003((v004(1)+1):(v004(2)-1))}));v003=['v' strrep(v003,'.','_')];if~exist('OCTAVE_VERSION',...
'builtin'),v005='MATLAB';v006=computer;else,v005='OCTAVE';v007=computer;v007=...
v007(1:(min(strfind(v007,'-'))-1));if ispc,if strcmp(v007,'x86_64'),v006='win_64';elseif ...
strcmp(v007,'i686'),v006='win_i686';elseif strcmp(v007,'x86'),v006='win_x86';else,v006=['win_' ...
v007];end,elseif isunix&&~ismac,if strcmp(v007,'i686'),v006='lnx_i686';elseif strcmp(v007,...
'x86_64'),v006='lnx_64';else,v006=['lnx_' v007];end,elseif ismac,if strcmp(v007,'x86_64'),v006=...
'mac_64';else,v006=['mac_' v007];end,end,end,v006=strrep(strrep(v006,'.',''),'-','');v002=...
cell(2,1);v002{1}=['_' v005 '_' v003 '_' v006];v002{2}=[v002{1} '.' mexext];end,try ...
if~isvarname(v001),error('trigger catch block'),end,catch,error('HJW:mexname:InvalidName',...
'The provided input can''t be a function name'),end,v000=[v001 v002{2}];v001=[v001 v002{1}];end
function[v000,v001]=getUTC_f29(v002,varargin),switch numel(v002),case 0,...
error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),case 1,otherwise,...
v002=v002(1);end,v000=v002;v001={};if nargin==1,return,end,try v003=numel(varargin)==...
1&&isa(varargin{1},'struct');v004=mod(numel(varargin),2)==0&&all(cellfun('isclass',...
varargin(1:2:end),'char')|cellfun('isclass',varargin(1:2:end),'string'));if~(v003||v004),...
error('trigger'),end,if nargin==2,v005=fieldnames(varargin{1});v006=struct2cell(varargin{1});
else,v005=cellstr(varargin(1:2:end));v006=varargin(2:2:end);end,if~iscellstr(v005),...
error('trigger');end,catch,error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),end,v007=...
fieldnames(v002);v008=cell(1,4);v009{1}=v007;v009{2}=lower(v009{1});v009{3}=strrep(v009{2},'_',...
'');v009{4}=strrep(v009{3},'-','');v005=strrep(v005,' ','_');v001=false(size(v007));for v010=...
1:numel(v005),v011=v005{v010};[v012,v008{1}]=getUTC_f30(v008{1},v009{1},v011);if numel(v012)~=1,...
v011=lower(v011);[v012,v008{2}]=getUTC_f30(v008{2},v009{2},v011);end,if numel(v012)~=1,v011=...
strrep(v011,'_','');[v012,v008{3}]=getUTC_f30(v008{3},v009{3},v011);end,if numel(v012)~=1,v011=...
strrep(v011,'-','');[v012,v008{4}]=getUTC_f30(v008{4},v009{4},v011);end,if numel(v012)~=1,...
error('parse_NameValue:NonUniqueMatch',v005{v010}),end,v000.(v007{v012})=v006{v010};v001(v012)=...
true;end,v001=v007(v001);end
function[v000,v001]=getUTC_f30(v001,v002,v003),v000=find(ismember(v002,v003));if numel(v000)==1,...
return,end,if isempty(v001),v001=getUTC_f31(v002);end,v004=v001(:,1:min(end,numel(v003)));if ...
size(v004,2)<numel(v003),v004=[v004 repmat(' ',size(v004,1),numel(v003)-size(v004,2))];end,v005=...
numel(v003)-sum(cumprod(double(v004==repmat(v003,size(v004,1),1)),2),2);v000=find(v005==0);end
function v000=getUTC_f31(v000),v001=cellfun('prodofsize',v000);v002=max(v001);for v003=...
find(v001<v002).',v000{v003}((end+1):v002)=' ';end,v000=vertcat(v000{:});end
function varargout=getUTC_f32(v000,v001,varargin),if nargin<2,...
error('HJW:regexp_outkeys:SyntaxError','No supported syntax used: at least 3 inputs expected.'),...
end,if~(ischar(v000)&&ischar(v001)),error('HJW:regexp_outkeys:InputError',...
'All inputs must be char vectors.'),end,if nargout>nargin,error('HJW:regexp_outkeys:ArgCount',...
'Incorrect number of output arguments. Check syntax.'),end,persistent v002 v003 v004,if ...
isempty(v002),v002.start=true;v002.end=true;v002.match=getUTC_f04('<','R14','Octave','<',4);
v002.tokens=v002.match;v002.split=getUTC_f04('<','R2007b','Octave','<',4);v005=fieldnames(v002);
v003=['Extra regexp output type not implemented,',char(10),'only the following',...
' types are implemented:',char(10),sprintf('%s, ',v005{:})];v003((end-1):end)='';v002.any=...
v002.match||v002.split||v002.tokens;v004=v002;for v006=fieldnames(v004).',v004.(v006{1})=false;
end,end,if v002.any||nargin==2||any(ismember(lower(varargin),{'start','end'})),[v007,v008,v009]=...
regexp(v000,v001);end,if nargin==2,varargout={v007,v008,v009};return,end,varargout=...
cell(size(varargin));v010=v004;v011=[];for v012=1:(nargin-2),if~ischar(varargin{v012}),...
error('HJW:regexp_outkeys:InputError','All inputs must be char vectors.'),end,switch ...
lower(varargin{v012}),case'match',if v010.match,varargout{v012}=v013;continue,end,if v002.match,...
v013=cell(1,numel(v007));for v014=1:numel(v007),v013{v014}=v000(v007(v014):v008(v014));end,else,...
[v013,v007,v008]=regexp(v000,v001,'match');end,varargout{v012}=v013;v010.match=true;case'split',...
if v010.split,varargout{v012}=v011;continue,end,if v002.split,v011=cell(1,numel(v007)+1);v015=...
[v007 numel(v000)+1];v016=[0 v008];for v014=1:numel(v015),v011{v014}=...
v000((v016(v014)+1):(v015(v014)-1));if numel(v011{v014})==0,v011{v014}=char(ones(0,0));end,end,...
else,[v011,v007,v008]=regexp(v000,v001,'split');end,varargout{v012}=v011;v010.split=true;
case'tokens',if v010.tokens,varargout{v012}=v017;continue,end,if v002.tokens,v017=...
cell(numel(v009),0);for v014=1:numel(v009),if size(v009{v014},2)~=2,v017{v014}=cell(1,0);else,...
for v018=1:size(v009{v014},1),v017{v014}{v018}=v000(v009{v014}(v018,1):v009{v014}(v018,2));end,...
end,end,else,[v017,v007,v008]=regexp(v000,v001,'tokens');end,varargout{v012}=v017;v010.tokens=...
true;case'start',varargout{v012}=v007;case'end',varargout{v012}=v008;otherwise,...
error('HJW:regexp_outkeys:NotImplemented',v003),end,end,if nargout>v012,varargout(v012+[1 2])=...
{v007,v008};end,end
function[v000,v001]=getUTC_f33(v001),persistent v002,if isempty(v002),v002={true,false;1,0;
'true','false';'1','0';'on','off';'enable','disable';'enabled','disabled'};end,if isa(v001,...
'matlab.lang.OnOffSwitchState'),v000=true;v001=logical(v001);return,end,if isa(v001,'string'),...
if numel(v001)~=1,v000=false;return,else,v001=char(v001);end,end,if isa(v001,'char'),v001=...
lower(v001);end,for v003=1:size(v002,1),for v004=1:2,if isequal(v001,v002{v003,v004}),v000=true;
v001=v002{1,v004};return,end,end,end,v000=false;end
function[v005,v000]=getUTC_f34,v000=false;try [v001,v002]=fileparts(tempname);v003='.c';v002=...
v002(regexp(v002,'[a-zA-Z0-9_]'));v002=['test_fun__' v002(1:min(15,end))];v004=...
fopen(fullfile(v001,[v002 v003]),'w');fprintf(v004,'%s\n','#include "mex.h"',...
'void mexFunction(int nlhs, mxArray *plhs[],','  int nrhs, const mxArray *prhs[]) {',...
'    plhs[0]=mxCreateString("compiler works");','    return;','}');fclose(v004);catch,v005=[];
v000=true;return,end,try v006=cd(v001);catch,v005=[];v000=true;return,end,try mex([v002 v003]);
v005=feval(str2func(v002));clear(v002);cd(v006);catch,cd(v006);v005=[];v000=false;return,end,end
function v000=getUTC_f35(v001),if~(isempty(v001)||exist(v001,'dir')),v000=false;return,end,v002=...
'';while isempty(v002)||exist(v002,'file'),[v003,v002]=...
fileparts(getUTC_f06('write_permission_test_','.txt'));v002=fullfile(v001,v002);end,try v004=...
fopen(v002,'w');fprintf(v004,'test');fclose(v004);delete(v002);v000=true;catch,if exist(v002,...
'file'),try delete(v002);catch,end,end,v000=false;end,end
function[v001,v000]=getUTC_f36,try v000=[];v001=fullfile(getUTC_f15,'FileExchange',...
'CheckMexCompilerExistence');if isempty(strfind([path ';'],[v001 ';'])),if~exist(v001,'dir'),...
getUTC_f27(v001);end,addpath(v001,'-end');end,catch,v000=struct('identifier',...
'HJW:CheckMexCompilerExistence:PathFolderFail','message',...
'Creating a folder on the path to store the compiled function and flag failed.');end,end

function[v000,v001]=GetWritableFolder(varargin),[v002,v003,v004]=...
GetWritableFolder_f01(varargin{:});if~v002,rethrow(v004),else,[v005,v006,v007]=...
deal(v003.ForceStatus,v003.ErrorOnNotFound,v003.root_folder_list);end,v007{end}=pwd;if v005,...
v001=v005;v000=fullfile(v007{v001},'PersistentFolder');try if~exist(v000,'dir'),...
GetWritableFolder_f02(v000);end,catch,end,return,end,v001=1;v000=v007{v001};try if~exist(v000,...
'dir'),GetWritableFolder_f02(v000);end,catch,end,if~GetWritableFolder_f08(v000),v001=2;v000=...
v007{v001};try if~exist(v000,'dir'),GetWritableFolder_f02(v000);end,catch,end,...
if~GetWritableFolder_f08(v000),v001=3;v000=v007{v001};end,end,v000=fullfile(v000,...
'PersistentFolder');try if~exist(v000,'dir'),GetWritableFolder_f02(v000);end,catch,end,...
if~GetWritableFolder_f08(v000),if v006,error('HJW:GetWritableFolder:NoWritableFolder',...
'This function was unable to find a folder with write permissions.'),else,v001=0;v000='';end,...
end,end
function v002=GetWritableFolder_f00,if ispc,[v000,v001]=system('echo %APPDATA%');v001(v001<14)=...
'';v002=fullfile(v001,'MathWorks','MATLAB Add-Ons');else,[v000,v003]=system('echo $HOME');
v003(v003<14)='';v002=fullfile(v003,'Documents','MATLAB','Add-Ons');end,end
function[v000,v001,v002]=GetWritableFolder_f01(varargin),v000=false;v002=struct('identifier','',...
'message','');persistent v003,if isempty(v003),v003.ForceStatus=false;v003.ErrorOnNotFound=...
false;v003.root_folder_list={GetWritableFolder_f00;fullfile(tempdir,'MATLAB');''};end,if ...
nargin==2,v001=v003;v000=true;return,end,[v001,v004]=GetWritableFolder_f04(v003,varargin{:});
for v005=1:numel(v004),v006=v004{v005};v007=v001.(v006);v002.identifier=...
['HJW:GetWritableFolder:incorrect_input_opt_' lower(v006)];switch v006,case'ForceStatus',try ...
if~isa(v003.root_folder_list{v007},'char'),...
error('the indexing must have failed, trigger error'),end,catch,v002.message=...
sprintf('Invalid input: expected a scalar integer between 1 and %d.',...
numel(v003.root_folder_list));return,end,case'ErrorOnNotFound',[v008,v001.ErrorOnNotFound]=...
GetWritableFolder_f07(v007);if~v008,v002.message=...
'ErrorOnNotFound should be either true or false.';return,end,otherwise,v002.message=...
sprintf('Name,Value pair not recognized: %s.',v006);v002.identifier=...
'HJW:GetWritableFolder:incorrect_input_NameValue';return,end,end,v000=true;v002=[];end
function varargout=GetWritableFolder_f02(v000),if exist(v000,'dir'),return,end,persistent v001,...
if isempty(v001),v001=GetWritableFolder_f09('<','R2007b','Octave','<',0);end,varargout=cell(1,...
nargout);if v001,[v002,v003]=fileparts(v000);[varargout{:}]=mkdir(v002,v003);else,...
[varargout{:}]=mkdir(v000);end,end
function v000=GetWritableFolder_f03(v000),v000=fix(v000+eps*1e3);end
function[v000,v001]=GetWritableFolder_f04(v002,varargin),switch numel(v002),case 0,...
error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),case 1,otherwise,...
v002=v002(1);end,v000=v002;v001={};if nargin==1,return,end,try v003=numel(varargin)==...
1&&isa(varargin{1},'struct');v004=mod(numel(varargin),2)==0&&all(cellfun('isclass',...
varargin(1:2:end),'char')|cellfun('isclass',varargin(1:2:end),'string'));if~(v003||v004),...
error('trigger'),end,if nargin==2,v005=fieldnames(varargin{1});v006=struct2cell(varargin{1});
else,v005=cellstr(varargin(1:2:end));v006=varargin(2:2:end);end,if~iscellstr(v005),...
error('trigger');end,catch,error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),end,v007=...
fieldnames(v002);v008=cell(1,4);v009{1}=v007;v009{2}=lower(v009{1});v009{3}=strrep(v009{2},'_',...
'');v009{4}=strrep(v009{3},'-','');v005=strrep(v005,' ','_');v001=false(size(v007));for v010=...
1:numel(v005),v011=v005{v010};[v012,v008{1}]=GetWritableFolder_f05(v008{1},v009{1},v011);if ...
numel(v012)~=1,v011=lower(v011);[v012,v008{2}]=GetWritableFolder_f05(v008{2},v009{2},v011);end,...
if numel(v012)~=1,v011=strrep(v011,'_','');[v012,v008{3}]=GetWritableFolder_f05(v008{3},v009{3},...
v011);end,if numel(v012)~=1,v011=strrep(v011,'-','');[v012,v008{4}]=...
GetWritableFolder_f05(v008{4},v009{4},v011);end,if numel(v012)~=1,...
error('parse_NameValue:NonUniqueMatch',v005{v010}),end,v000.(v007{v012})=v006{v010};v001(v012)=...
true;end,v001=v007(v001);end
function[v000,v001]=GetWritableFolder_f05(v001,v002,v003),v000=find(ismember(v002,v003));if ...
numel(v000)==1,return,end,if isempty(v001),v001=GetWritableFolder_f06(v002);end,v004=v001(:,...
1:min(end,numel(v003)));if size(v004,2)<numel(v003),v004=[v004 repmat(' ',size(v004,1),...
numel(v003)-size(v004,2))];end,v005=numel(v003)-sum(cumprod(double(v004==repmat(v003,size(v004,...
1),1)),2),2);v000=find(v005==0);end
function v000=GetWritableFolder_f06(v000),v001=cellfun('prodofsize',v000);v002=max(v001);for ...
v003=find(v001<v002).',v000{v003}((end+1):v002)=' ';end,v000=vertcat(v000{:});end
function[v000,v001]=GetWritableFolder_f07(v001),persistent v002,if isempty(v002),v002={true,...
false;1,0;'true','false';'1','0';'on','off';'enable','disable';'enabled','disabled'};end,if ...
isa(v001,'matlab.lang.OnOffSwitchState'),v000=true;v001=logical(v001);return,end,if isa(v001,...
'string'),if numel(v001)~=1,v000=false;return,else,v001=char(v001);end,end,if isa(v001,'char'),...
v001=lower(v001);end,for v003=1:size(v002,1),for v004=1:2,if isequal(v001,v002{v003,v004}),v000=...
true;v001=v002{1,v004};return,end,end,end,v000=false;end
function v000=GetWritableFolder_f08(v001),if~(isempty(v001)||exist(v001,'dir')),v000=false;
return,end,v002='';while isempty(v002)||exist(v002,'file'),[v003,v002]=...
fileparts(GetWritableFolder_f10('write_permission_test_','.txt'));v002=fullfile(v001,v002);end,...
try v004=fopen(v002,'w');fprintf(v004,'test');fclose(v004);delete(v002);v000=true;catch,if ...
exist(v002,'file'),try delete(v002);catch,end,end,v000=false;end,end
function v000=GetWritableFolder_f09(v001,v002,v003,v004,v005),if nargin<2||nargout>1,...
error('incorrect number of input/output arguments'),end,persistent v006 v007 v008,if ...
isempty(v006),v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);
v007={'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;
'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;
'R2009b' 709;'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;
'R2016b' 901;'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;
'R2020a' 908;'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913;'R2023a' 914;
'R2023b' 2302;'R2024a' 2401};end,if v008,if nargin==2,warning('HJW:ifversion:NoOctaveTest',...
['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*GetWritableFolder_f03(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),...
v002);if sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=...
0.1*v009+0.9*GetWritableFolder_f03(v009);v009=round(100*v009);else,[v001,v009]=deal(v004,v005);
v009=0.1*v009+0.9*GetWritableFolder_f03(v009);v009=round(100*v009);end,else,if isnumeric(v002),...
v009=GetWritableFolder_f03(v002*100);if mod(v009,10)==0,v009=...
GetWritableFolder_f03(v002)*100+mod(v002,1)*10;end,else,v010=ismember(v007(:,1),v002);if ...
sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=v006 < v009;case'<=',v000=v006 <=...
v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end
function v000=GetWritableFolder_f10(v001,v002),if nargin<1,v001='';end,if~isempty(v001),v001=...
[v001 '_'];end,if nargin<2,v002='';else,if~strcmp(v002(1),'.'),v002=['.' v002];end,end,v000=...
tempname;[v003,v004]=fileparts(v000);v000=fullfile(v003,[v001 v004 v002]);end
function tf=hasFeature(feature)
% Provide a single point to encode whether specific features are available.
persistent FeatureList
if isempty(FeatureList)
    checkpoint('hasFeature','ifversion')
    FeatureList = struct(...
        'HG2'              ,ifversion('>=','R2014b','Octave','<' ,0),...
        'ImplicitExpansion',ifversion('>=','R2016b','Octave','>' ,0),...
        'bsxfun'           ,ifversion('>=','R2007a','Octave','>' ,0),...
        'IntegerArithmetic',ifversion('>=','R2010b','Octave','>' ,0),...
        'String'           ,ifversion('>=','R2016b','Octave','<' ,0),...
        'HTTPS_support'    ,ifversion('>' ,0       ,'Octave','<' ,0),...
        'json'             ,ifversion('>=','R2016b','Octave','>=',7),...
        'strtrim'          ,ifversion('>=',7       ,'Octave','>=',0),...
        'accumarray'       ,ifversion('>=',7       ,'Octave','>=',0));
    checkpoint('hasFeature','CharIsUTF8')
    FeatureList.CharIsUTF8 = CharIsUTF8;
end
tf = FeatureList.(feature);
end
function v000=ifversion(v001,v002,v003,v004,v005),if nargin<2||nargout>1,...
error('incorrect number of input/output arguments'),end,persistent v006 v007 v008,if ...
isempty(v006),v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);
v007={'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;
'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;
'R2009b' 709;'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;
'R2016b' 901;'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;
'R2020a' 908;'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913;'R2023a' 914;
'R2023b' 2302;'R2024a' 2401};end,if v008,if nargin==2,warning('HJW:ifversion:NoOctaveTest',...
['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*ifversion_f00(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if ...
sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=0.1*v009+0.9*ifversion_f00(v009);v009=...
round(100*v009);else,[v001,v009]=deal(v004,v005);v009=0.1*v009+0.9*ifversion_f00(v009);v009=...
round(100*v009);end,else,if isnumeric(v002),v009=ifversion_f00(v002*100);if mod(v009,10)==0,...
v009=ifversion_f00(v002)*100+mod(v002,1)*10;end,else,v010=ismember(v007(:,1),v002);if ...
sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=v006 < v009;case'<=',v000=v006 <=...
v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end
function v000=ifversion_f00(v000),v000=fix(v000+eps*1e3);end

function tf=ifversion___skip_test
% Some runtimes are very twitchy about tests involving graphics. This function lists them so there
% is only a single place I need to turn them off.
persistent tf_
if isempty(tf_)
    checkpoint('ifversion___skip_test','ifversion')
    OldLinuxMatlab = isunix && ~ismac && ifversion('<','R2013a','Octave','<',0);
    checkpoint('ifversion___skip_test','ifversion')
    MacOctave = ifversion('<',0,'Octave','>',0) && ismac;
    skip = OldLinuxMatlab||MacOctave;
    
    % If the release can not be hardcoded, check two other ways to figure out whether graphics are
    % truly supported.
    if ~skip
        % If figures don't work without warnings, no graphics are likely to work.
        [str,works] = evalc(func2str(@test_figure_available)); %#ok<ASGLU>
        skip = ~works;
        if works
            % The online run tool on Matlab Answers allows figures, but doesn't allow waitbars.
            [str,works] = evalc(func2str(@test_waitbar_available)); %#ok<ASGLU>
            skip = ~works;
        end
    end
    tf_ = skip;
end
tf = tf_;
end
function tf=test_figure_available
try
    [w_msg,w_id] = lastwarn('BLANK','BLANK:BLANK');
    delete(figure);
    [w_msg,w_id] = lastwarn(w_msg,w_id);
    if strcmp(w_id,'BLANK:BLANK') && strcmp(w_msg,'BLANK')
        % No warning occurred.
        tf = true;
    else
        clc % Clear the warnings that were generated.
        error('trigger')
    end
catch
    lastwarn(w_msg,w_id); % Reset lastwarn state.
    tf = false;
end
end
function tf=test_waitbar_available
try
    delete(waitbar(0,'test if GUI is available'));
    tf = true;
catch
    tf = false;
end
end
function[v000,v001]=isnetavl(v002),if nargin==0,v003=false;else,[v004,v005]=isnetavl_f03(v002);
v003=v004&&v005;end,if v003,[v000,v001]=isnetavl_f02;return,end,v003=isnetavl_f01;if ...
isempty(v003),v000=0;v001=0;else,if v003,[v000,v001]=isnetavl_f02;else,[v000,v001]=isnetavl_f00;
end,end,end
function[v003,v006]=isnetavl_f00,if ispc,try [v000,v001]=system('ping -n 1 8.8.8.8');v002=...
v001(strfind(v001,' = ')+3);v002=v002(1:3);if~strcmp(v002,'110'),error('trigger error'),else,...
v003=1;[v004,v005]=regexp(v001,' [0-9]+ms');v006=v001((v004(1)+1):(v005(1)-2));v006=...
str2double(v006);end,catch,v003=0;v006=0;end,elseif isunix,try [v000,v001]=...
system('ping -c 1 8.8.8.8');v007=regexp(v001,', [01] ');if v001(v007+2)~='1',...
error('trigger error'),else,v003=1;[v004,v005]=regexp(v001,'=[0-9.]+ ms');v006=...
v001((v004(1)+1):(v005(1)-2));v006=str2double(v006);end,catch,v003=0;v006=0;end,else,...
error('How did you even get Matlab to work?'),end,end
function[v001,v002,v003]=isnetavl_f01,persistent v000,if~isempty(v000),v001=v000;return,end,...
[v002,v003]=isnetavl_f00;if v002,v000=false;v001=false;return,end,[v002,v003]=isnetavl_f02;if ...
v002,v000=true;v001=true;return,end,v001=[];end
function[v004,v005]=isnetavl_f02,persistent v000,if isempty(v000),try v001=...
isempty(which(func2str(@webread)));catch,v001=true;end,v000=~v001;end,try v002=now;if v000,v003=...
webread('http://google.com');else,v003=urlread('http://google.com');end,v004=1;v005=...
(now-v002)*24*3600*1000;catch,v004=0;v005=0;end,end
function[v000,v001]=isnetavl_f03(v001),persistent v002,if isempty(v002),v002={true,false;1,0;
'true','false';'1','0';'on','off';'enable','disable';'enabled','disabled'};end,if isa(v001,...
'matlab.lang.OnOffSwitchState'),v000=true;v001=logical(v001);return,end,if isa(v001,'string'),...
if numel(v001)~=1,v000=false;return,else,v001=char(v001);end,end,if isa(v001,'char'),v001=...
lower(v001);end,for v003=1:size(v002,1),for v004=1:2,if isequal(v001,v002{v003,v004}),v000=true;
v001=v002{1,v004};return,end,end,end,v000=false;end
function[v000,v001]=JSON(v002,varargin),v003=struct;v003.EnforceValidNumber=true;
v003.ThrowErrorForInvalid=nargout<2;v003.MaxRecursionDepth=101-numel(dbstack);v003=...
JSON_f15(v003,varargin{:});v004=struct;[v004.msg,v004.ID]=lastwarn;v004.w=warning('off',...
'REGEXP:multibyteCharacters');try v001=[];v005=JSON_f12(v002,v003);v000=JSON_f06(v005);catch ...
v001;if isempty(v001),v001=lasterror;end,end,warning(v004.w);lastwarn(v004.msg,v004.ID);
if~isempty(v001),if v003.ThrowErrorForInvalid,rethrow(v001),else,v000=[];end,end,end
function v000=JSON_f00(v001),v002=find(v001.braces==-v001.braces(1));if numel(v002)~=1||v002~=...
numel(v001.str)||~strcmp(v001.str([1 end]),'[]'),v003='Unexpected end of array.';v004='Array';
JSON_f08(v003,v004),end,if strcmp(v001.str,'[]'),v000=[];return,end,if strcmp(v001.str,'[[]]'),...
v000={[]};return,end,v005=v001.braces;v005(1)=0;v006=find(cumsum(v005)==0&v001.s_tokens==',');
v006=[1 v006 numel(v001.str)];v006=[v006(1:(end-1))+1;v006(2:end)-1];if any(diff(v006,1,1)<0),...
v003='Empty array element.';v004='Array';JSON_f08(v003,v004),end,v000=cell(size(v006,2),1);for ...
v007=1:size(v006,2),v000{v007}=JSON_f06(JSON_f09(v001,v006(:,v007)));end,if ...
v001.ArrayOfArrays(1),try if~all(cellfun('isclass',v000,class(v000{1}))),error('trigger'),end,...
v008=v000;v008(cellfun('isempty',v008))={NaN};v000=horzcat(v008{:}).';return,catch,end,end,if ...
ismember(class(v000{v007}),{'double','logical','struct'}),v008=v000;if all(cellfun('isclass',...
v000,'double')),v008(cellfun('isempty',v008))={NaN};if numel(unique(cellfun('prodofsize',...
v008)))==1,v000=horzcat(v008{:}).';return,end,elseif all(cellfun('isclass',v000,'logical')),if ...
numel(unique(cellfun('prodofsize',v000)))==1,v000=horzcat(v000{:}).';return,end,elseif ...
all(cellfun('isclass',v000,'struct')),try v000=vertcat(v000{:});catch,end,else,end,end,end
function v000=JSON_f01(v001),v001=strrep(v001,'\"','__');v002=v001=='"';v003=cumsum(v002);v000=...
v002|mod(v003,2)~=0;end
function[v000,v001]=JSON_f02(v002),v000=zeros(size(v002));v003=v002=='{';v000(v003)=1:sum(v003);
try v004=find(v003);for v005=find(v002=='}'),v006=find(v004<v005);v006=v006(end);v007=...
v004(v006);v004(v006)=[];v000(v005)=-v000(v007);v003(v007)=false;end,if any(v003),...
error('trigger'),end,catch,v008='Unmatched braces found.';v009='PairBraces';JSON_f08(v008,v009),...
end,v003=v002=='[';v000(v003)=max(v000)+(1:sum(v003));try v004=find(v003);for v005=find(v002==...
']'),v006=find(v004<v005);v006=v006(end);v007=v004(v006);v004(v006)=[];v000(v005)=-v000(v007);
v003(v007)=false;end,if any(v003),error('trigger'),end,catch,v008='Unmatched braces found.';
v009='PairBraces';JSON_f08(v008,v009),end,v001=false(1,numel(v002));v010=...
v002(ismember(double(v002),double('[{}]')));v011=v000(v000~=0);[v012,v013]=regexp(v010,...
'(\[)+\[');v013=v013-1;for v014=1:numel(v012);v001(v000==v011(v013(v014)))=true;end;end
function v000=JSON_f03(v000),v001=cellfun('prodofsize',v000);v002=max(v001);for v003=...
find(v001<v002).',v000{v003}((end+1):v002)=' ';end,v000=vertcat(v000{:});end
function v000=JSON_f04(v001),if numel(v001)>1,...
error('this should only be used for single characters'),end,if v001<128,v000=v001;return,end,...
persistent v002,if isempty(v002),v002=struct;v002.limits.lower=hex2dec({'0000','0080','0800',...
'10000'});v002.limits.upper=hex2dec({'007F','07FF','FFFF','10FFFF'});v002.scheme{2}=...
'110xxxxx10xxxxxx';v002.scheme{2}=reshape(v002.scheme{2}.',8,2);v002.scheme{3}=...
'1110xxxx10xxxxxx10xxxxxx';v002.scheme{3}=reshape(v002.scheme{3}.',8,3);v002.scheme{4}=...
'11110xxx10xxxxxx10xxxxxx10xxxxxx';v002.scheme{4}=reshape(v002.scheme{4}.',8,4);for v003=2:4,...
v002.scheme_pos{v003}=find(v002.scheme{v003}=='x');v002.bits(v003)=numel(v002.scheme_pos{v003});
end,end,v004=find(v002.limits.lower<=v001&v001<=v002.limits.upper);v000=v002.scheme{v004};v005=...
v002.scheme_pos{v004};v003=dec2bin(double(v001),v002.bits(v004));v000(v005)=v003;v000=...
bin2dec(v000.').';end
function v000=JSON_f05(v000),persistent v001 v002 v003,if isempty(v001),v003=zeros(1,...
double('u'));v003(double('"\/bfnrtu'))=[ones(1,8) 5]+1;v001={'"','"';'\','\';'/','/';'b',...
char(8);'f',char(12);'n',char(10);'r',char(13);'t',char(9)};v002=double([cell2mat(v001(:,1));
'u']);for v004=1:size(v001,1),v001{v004,1}=['\' v001{v004,1}];end,end,if~strcmp(v000([1 end]),...
'""'),v005='Unexpected end of string.';v006='StringDelim';JSON_f08(v005,v006),end,if ...
any(double(v000)<32),v005='Unescaped control character in string.';v006='StringControlChar';
JSON_f08(v005,v006),end,v000=v000(2:(end-1));v007=regexp(v000,'\\.');if any(v007),...
if~all(ismember(double(v000(v007+1)),v002)),v005='Unexpected escaped character.';v006=...
'StringEscape';JSON_f08(v005,v006),end,v007=regexp(v000,'\\["\\/bfnrtu]');v008=strfind(v000,...
'\u');if~isempty(v008),v009=true;try v008=JSON_f27(v008.',0:5);v010=cellstr(unique(v000(v008),...
'rows'));for v004=1:numel(v010),v010{v004,2}=JSON_f21(hex2dec(v010{v004,1}(3:end)));end,catch,...
v005='Unexpected escaped character.';v006='StringEscape';JSON_f08(v005,v006),end,else,v009=...
false;v010=cell(0,2);end,v011=[v010;v001];v012=v003(v000(v007+1));v012=[0 v012;diff([0,v007,...
1+numel(v000)])-[1 v012]];v013=mat2cell(v000,1,v012(:));v013=reshape(v013,2,[]);if any([v013{2,...
:}]=='\'),v005='Unexpected escaped character.';v006='StringEscape';JSON_f08(v005,v006),end,v014=...
true(size(v013));v014(1,:)=false;v014(cellfun('prodofsize',v013)==0)=true;for v004=1:size(v011,...
1),v015=~v014&ismember(v013,v011{v004,1});v013(v015)=v011(v004,2);v014(v015)=true;if all(v014),...
break,end,end,if any(~v014),v005='Unexpected escaped character.';v006='StringEscape';
JSON_f08(v005,v006),end,v000=horzcat(v013{:});if v009&&JSON_f29,[v000,v016]=JSON_f26(v000);v000=...
JSON_f21(JSON_f25(v000));end,end,end
function v000=JSON_f06(v001),persistent v002,if isempty(v002),v002=num2cell('-0123456789');end,...
if numel(v001.str)==0,v001.str=' ';end,v001.depth=v001.depth+1;if ...
v001.depth>v001.opts.MaxRecursionDepth,...
JSON_f08('Recursion limit reached, exiting to avoid crashes.','Recursion'),end,switch ...
v001.str(1),case'{';v000=JSON_f07(v001);case'[';v000=JSON_f00(v001);case v002;v000=...
JSON_f22(v001.str,v001.opts.EnforceValidNumber);case'"';v000=JSON_f05(v001.str);if numel(v000)==...
0,v000='';end;case't';if~strcmp(v001.str,'true');v003='Unexpected literal, expected ''true''.';
v004='Literal';JSON_f08(v003,v004);end;v000=true;case'f';if~strcmp(v001.str,'false');v003=...
'Unexpected literal, expected ''false''.';v004='Literal';JSON_f08(v003,v004);end;v000=false;
case'n';if~strcmp(v001.str,'null');v003='Unexpected literal, expected ''null''.';v004='Literal';
JSON_f08(v003,v004);end;v000=[];otherwise;v003=...
'Unexpected character, expected a brace, bracket, number, string, or literal.';v004='Literal';
JSON_f08(v003,v004);end;end
function v000=JSON_f07(v001),v002=find(v001.braces==-v001.braces(1));if numel(v002)~=1||v002~=...
numel(v001.str)||~strcmp(v001.str([1 end]),'{}'),v003='Unexpected end of object.';v004='Object';
JSON_f08(v003,v004),end,v000=struct;if v002==2,return,end,v005=JSON_f09(v001,[2 ...
numel(v001.str)-1]);v006=find(cumsum(v005.braces)==0&v005.s_tokens==',');v006=[0 v006 ...
numel(v005.str)+1];v006=[v006(1:(end-1))+1;v006(2:end)-1];v007=cell(size(v006));for v008=...
1:size(v006,2),v009=JSON_f09(v005,v006(:,v008));v010=v009.s_tokens==':';if~any(v010),...
JSON_f08('No colon found in object definition.','Object'),end,v002=find(v010);v002=v002(1);try ...
v007{1,v008}=JSON_f05(v009.str(1:(v002-1)));catch,JSON_f08('Invalid key in object definition.',...
'Object'),end,try v007{2,v008}=JSON_f06(JSON_f09(v009,v002+1));catch,...
JSON_f08('Invalid value in object definition.','Object'),end,if isa(v007{2,v008},'cell'),v007{2,...
v008}=v007(2,v008);end,end,persistent v011 v012,if isempty(v011),v013=char([9 10 11 12 13 32]);
v011=['[' v013 ']+([^' v013 '])'];v012=strcmp('fooBar',regexprep('foo bar',v011,...
'${upper($1)}'));end,for v008=1:size(v007,2),v014=v007{1,v008};if v012,v014=regexprep(v014,v011,...
'${upper($1)}');else,[v015,v016]=regexp(v014,v011);if~isempty(v015),v014(v016)=...
upper(v014(v016));v010=zeros(size(v014));v010(v015)=1;v010(v016)=-1;v010=logical(cumsum(v010));
v014(v010)='';end,end,v014=regexprep(v014,'\s','');v017=find(double(v014)==0);if~isempty(v017),...
v014(v017(1):end)='';end,v014=regexprep(v014,'[^0-9a-zA-Z_]','_');if ...
isempty(v014)||any(v014(1)=='_0123456789'),v014=['x' v014];end,v018=v014;v019=0;while ...
ismember(v014,v007(1,1:(v008-1))),v019=v019+1;v014=sprintf('%s_%d',v018,v019);end,v007{1,v008}=...
v014;end,v000=struct(v007{:});end
function JSON_f08(msg,id),error(['HJW:JSON:' id],msg),end
function v000=JSON_f09(v000,v001),if numel(v001)==1,v001(2)=numel(v000.str);end,v001=...
v001(1):v001(2);v000.str=v000.str(v001);v000.s_tokens=v000.s_tokens(v001);v000.braces=...
v000.braces(v001);v000.ArrayOfArrays=v000.ArrayOfArrays(v001);end
function JSON_f10(v001,varargin),persistent v000,if isempty(v000),v000=func2str(@JSON_f10);end,...
if isempty(v001),v001=JSON_f30(struct);end,v001=JSON_f18(v001);[v002,v003,v004,v005,v006]=...
JSON_f17(varargin{:});if v006,return,end,v007=struct('identifier',v002,'message',v003,'stack',...
v004);if v001.boolean.obj,v008=v003;while v008(end)==10,v008(end)='';end,if any(v008==10),v008=...
JSON_f28(['Error: ' v008]);else,v008=['Error: ' v008];end,for v009=v001.obj(:).',try set(v009,...
'String',v008);catch,end,end,end,if v001.boolean.fid,v010=datestr(now,31);for v011=...
v001.fid(:).',try fprintf(v011,'[%s] Error: %s\n%s',v010,v003,v005);catch,end,end,end,if ...
v001.boolean.fcn,if ismember(v000,{v004.name}),error('prevent recursion'),end,for v012=...
v001.fcn(:).',if isfield(v012,'data'),try feval(v012.h,'error',v007,v012.data);catch,end,else,...
try feval(v012.h,'error',v007);catch,end,end,end,end,rethrow(v007),end
function[v000,v001]=JSON_f11(v002,v001),if nargin==0,v002=1;end,if nargin<2,v001=dbstack;end,...
v001(1:v002)=[];if~isfield(v001,'file'),for v003=1:numel(v001),v004=v001(v003).name;if ...
strcmp(v004(end),')'),v005=strfind(v004,'(');v006=v004((v005(end)+1):(end-1));v007=...
v004(1:(v005(end)-2));else,v007=v004;[v008,v006]=fileparts(v004);end,[v008,v001(v003).file]=...
fileparts(v007);v001(v003).name=v006;end,end,persistent v009,if isempty(v009),v009=JSON_f14('<',...
0,'Octave','>',0);end,if v009,for v003=1:numel(v001),[v008,v001(v003).file]=...
fileparts(v001(v003).file);end,end,v010=v001;v011='>';v000=cell(1,numel(v010)-1);for v003=...
1:numel(v010),[v012,v010(v003).file,v013]=fileparts(v010(v003).file);if v003==numel(v010),...
v010(v003).file='';end,if strcmp(v010(v003).file,v010(v003).name),v010(v003).file='';end,...
if~isempty(v010(v003).file),v010(v003).file=[v010(v003).file '>'];end,v000{v003}=...
sprintf('%c In %s%s (line %d)\n',v011,v010(v003).file,v010(v003).name,v010(v003).line);v011=' ';
end,v000=horzcat(v000{:});end
function v000=JSON_f12(v001,v002),if isa(v001,'string'),v001=cellstr(v001);end,if ...
iscellstr(v001),v001=sprintf('%s\n',v001{:});end,if~isa(v001,'char')||numel(v001)~=length(v001),...
JSON_f08('The input should be a char vector or a string/cellstr.','Input'),end,v001=...
reshape(v001,1,[]);persistent v003 v004 v005,if isempty(v003),v004=[9 10 13 32];v003={['[' ...
char(v004) ']*([\[{\]}:,])[' char(v004) ']*'],'$1','tokenize'};if JSON_f14('>=',7,'Octave','>',...
0),v003(end)=[];end,v005=3==numel(regexprep(['123' char([0 10])],v003{:}));end,v006=...
JSON_f01(v001);v007=v001;v007(v006)='_';if~v005,v007=regexprep(v007,v003{:});else,v008=v007;
v008(:)='n';v008(ismember(double(v007),v004))='w';v008(ismember(double(v007),double('[{}]:,')))=...
't';v009=zeros(1,1+numel(v008));[v010,v011]=regexp(v008,'w+t');if~isempty(v010),v009(v010)=1;
v009(v011)=-1;end,[v010,v011]=regexp(v008,'tw+');if~isempty(v010),v009(v010+1)=1;v009(v011+1)=...
-1;end,v009=logical(cumsum(v009));v009(end)=[];v007(v009)='';end,while ...
numel(v007)>0&&any(v007(end)==v004),v007(end)='';end,while numel(v007)>0&&any(v007(1)==v004),...
v007(1)='';end,v012=v007;v012(v007=='_')=v001(v006);v001=v012;v007(~ismember(double(v007),...
double('[{}]:,')))='_';[v013,v014]=JSON_f02(v007);v000.str=v001;v000.s_tokens=v007;v000.braces=...
v013;v000.ArrayOfArrays=v014;v000.opts=v002;v000.depth=0;end
function v000=JSON_f13(v001),persistent v002,if isempty(v002),v002=struct('ImplicitExpansion',...
JSON_f14('>=','R2016b','Octave','>',0),'bsxfun',JSON_f14('>=','R2007a','Octave','>',0),...
'IntegerArithmetic',JSON_f14('>=','R2010b','Octave','>',0),'String',JSON_f14('>=','R2016b',...
'Octave','<',0),'HTTPS_support',JSON_f14('>',0,'Octave','<',0),'json',JSON_f14('>=','R2016b',...
'Octave','>=',7),'strtrim',JSON_f14('>=',7,'Octave','>=',0));v002.CharIsUTF8=JSON_f29;end,v000=...
v002.(v001);end
function v000=JSON_f14(v001,v002,v003,v004,v005),persistent v006 v007 v008,if isempty(v006),...
v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);v007={'R13' 605;
'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;'R2006a' 702;
'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;'R2009b' 709;
'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;'R2013a' 801;
'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;'R2016b' 901;
'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;'R2020a' 908;
'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913};end,if v008,if nargin==2,...
warning('HJW:ifversion:NoOctaveTest',['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);else,[v001,v009]=deal(v004,v005);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);end,else,if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=...
v006 < v009;case'<=',v000=v006 <=v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end
function[v000,v001]=JSON_f15(v002,varargin),switch numel(v002),case 0,...
error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),case 1,otherwise,...
v002=v002(1);end,v000=v002;v001={};if nargin==1,return,end,try v003=numel(varargin)==...
1&&isa(varargin{1},'struct');v004=mod(numel(varargin),2)==0&&all(cellfun('isclass',...
varargin(1:2:end),'char')|cellfun('isclass',varargin(1:2:end),'string'));if~(v003||v004),...
error('trigger'),end,if nargin==2,v005=fieldnames(varargin{1});v006=struct2cell(varargin{1});
else,v005=cellstr(varargin(1:2:end));v006=varargin(2:2:end);end,if~iscellstr(v005),...
error('trigger');end,catch,error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),end,v007=...
fieldnames(v002);v008=cell(1,4);v009{1}=v007;v009{2}=lower(v009{1});v009{3}=strrep(v009{2},'_',...
'');v009{4}=strrep(v009{3},'-','');v005=strrep(v005,' ','_');v001=false(size(v007));for v010=...
1:numel(v005),v011=v005{v010};[v012,v008{1}]=JSON_f16(v008{1},v009{1},v011);if numel(v012)~=1,...
v011=lower(v011);[v012,v008{2}]=JSON_f16(v008{2},v009{2},v011);end,if numel(v012)~=1,v011=...
strrep(v011,'_','');[v012,v008{3}]=JSON_f16(v008{3},v009{3},v011);end,if numel(v012)~=1,v011=...
strrep(v011,'-','');[v012,v008{4}]=JSON_f16(v008{4},v009{4},v011);end,if numel(v012)~=1,...
error('parse_NameValue:NonUniqueMatch',v005{v010}),end,v000.(v007{v012})=v006{v010};v001(v012)=...
true;end,v001=v007(v001);end
function[v000,v001]=JSON_f16(v001,v002,v003),v000=find(ismember(v002,v003));if numel(v000)==1,...
return,end,if isempty(v001),v001=JSON_f03(v002);end,v004=v001(:,1:min(end,numel(v003)));if ...
size(v004,2)<numel(v003),v004=[v004 repmat(' ',size(v004,1),numel(v003)-size(v004,2))];end,v005=...
numel(v003)-sum(cumprod(double(v004==repmat(v003,size(v004,1),1)),2),2);v000=find(v005==0);end
function[v000,v001,v002,v003,v004]=JSON_f17(varargin),v004=false;if nargin==1,if ...
isa(varargin{1},'struct')||isa(varargin{1},'MException'),v005=varargin{1};if numel(v005)==0,...
v004=true;[v000,v001,v002,v003]=deal('');return,end,try v002=v005.stack;v003=JSON_f11(0,v002);
catch,[v003,v002]=JSON_f11(3);end,v000=v005.identifier;v001=v005.message;v006=...
'Error using <a href="matlab:matlab.internal.language.introspective.errorDocCallbac';if ...
isa(v005,'struct')&&strcmp(v006,v001(1:min(end,numel(v006)))),v001(1:min(find(v001==10)))='';
end,else,[v003,v002]=JSON_f11(3);[v000,v001]=deal('',varargin{1});end,else,[v003,v002]=...
JSON_f11(3);if~isempty(strfind(varargin{1},'%')),v000='';v007=varargin(2:end);v001=...
sprintf(varargin{1},v007{:});else,v000=varargin{1};v001=varargin{2};if nargin>2,v007=...
varargin(3:end);v001=sprintf(v001,v007{:});end,end,end,end
function v000=JSON_f18(v000),if~isfield(v000,'boolean'),v000.boolean=struct;end,...
if~isfield(v000.boolean,'con')||isempty(v000.boolean.con),v000.boolean.con=false;end,...
if~isfield(v000.boolean,'fid')||isempty(v000.boolean.fid),v000.boolean.fid=isfield(v000,'fid');
end,if~isfield(v000.boolean,'obj')||isempty(v000.boolean.obj),v000.boolean.obj=isfield(v000,...
'obj');end,if~isfield(v000.boolean,'fcn')||isempty(v000.boolean.fcn),v000.boolean.fcn=...
isfield(v000,'fcn');end,end
function v000=JSON_f19(v001,v002,v003),v000=v001(:)';if numel(v002)==0,v004=false(size(v001));
elseif numel(v003)>numel(v002),error('not implemented (padding required)'),else,v004=...
true(size(v001));for v005=1:numel(v002),v006=find(v001==v002(v005));v006=v006-v005+1;
v006(v006<1)=[];v007=false(size(v004));v007(v006)=true;v004=v004&v007;if~any(v004),break,end,...
end,end,v006=find(v004);if~isempty(v006),for v005=1:numel(v003),v000(v006+v005-1)=v003(v005);
end,if numel(v003)==0,v005=0;end,if numel(v002)>v005,v006=v006(:);v008=(v005+1):numel(v002);
v009=JSON_f27(v006,v008-1);v000(v009(:))=[];end,end,end
function[v000,v001]=JSON_f20(v001),persistent v002,if isempty(v002),v002={true,false;1,0;'on',...
'off';'enable','disable';'enabled','disabled'};end,if isa(v001,'matlab.lang.OnOffSwitchState'),...
v000=true;v001=logical(v001);return,end,if isa(v001,'string'),if numel(v001)~=1,v000=false;
return,else,v001=char(v001);end,end,if isa(v001,'char'),v001=lower(v001);end,for v003=...
1:size(v002,1),for v004=1:2,if isequal(v001,v002{v003,v004}),v000=true;v001=v002{1,v004};return,...
end,end,end,v000=false;end
function v000=JSON_f21(v001,v002),persistent v003,if isempty(v003),v003=JSON_f14('<',0,'Octave',...
'>',0);end,if nargin==1,v002=~JSON_f29;end,if v002,if all(v001<65536),v000=uint16(v001);v000=...
reshape(v000,1,numel(v000));else,[v004,v005,v006]=unique(v001);v000=cell(1,numel(v001));for ...
v007=1:numel(v004),v008=JSON_f23(v004(v007));v008=uint16(v008);v000(v006==v007)={v008};end,v000=...
cell2mat(v000);end,if~v003,v000=char(v000);end,else,if all(v001<128),v000=char(v001);v000=...
reshape(v000,1,numel(v000));else,[v004,v005,v006]=unique(v001);v000=cell(1,numel(v001));for ...
v007=1:numel(v004),v008=JSON_f04(v004(v007));v008=uint8(v008);v000(v006==v007)={v008};end,v000=...
cell2mat(v000);v000=char(v000);end,end,end
function v000=JSON_f22(v001,v002),if~v002,v003=true;else,v004{1}=...
['-?((0)|([1-9]+\d*))(\.\d+)?([eE]' '\+' '?[0-9]+)?'];v004{2}=...
['-?((0)|([1-9]+\d*))(\.\d+)?([eE]' '-' '?[0-9]+)?'];if true,[v005,v006]=regexp(v001,v004{1},...
'once');v003=~isempty(v005)&&v005==1&&v006==numel(v001);end,if~v003,[v005,v006]=regexp(v001,...
v004{2},'once');v003=~isempty(v005)&&v005==1&&v006==numel(v001);end,end,if~v003,v007=...
'Invalid number format.';v008='Number';JSON_f08(v007,v008),end,v000=str2double(v001);end
function v000=JSON_f23(v001),if v001<65536,v000=v001;return,end,v002=double(v001)-65536;v002=...
dec2bin(v002,20);v000=bin2dec(['110110' v002(1:10);'110111' v002(11:20)]).';end
function[v000,v001,v002]=JSON_f24(v000,v003),v001='success';v002=struct('identifier',...
'HJW:UTF8_to_unicode:notUTF8','message','Input is not UTF-8.');persistent v004,if isempty(v004),...
v004=JSON_f14('<',0,'Octave','>',0);end,if any(v000>255),v001='error';if v003,return,end,elseif ...
all(v000<128),return,end,for v005=4:-1:2,v006=bin2dec([repmat('1',1,v005) repmat('0',1,...
8-v005)]);v007=v000>=v006&v000<256;if any(v007),v007=find(v007);v007=v007(:).';if ...
numel(v000)<(max(v007)+v005-1),v001='error';if v003,return,end,v007((v007+v005-1)>numel(v000))=...
[];end,if~isempty(v007),v008=JSON_f27(v007,(0:(v005-1)).');v008=v008.';v007=v000(v008);end,else,...
v007=[];end,v009=[repmat('1',1,v005-1) repmat('10',1,v005)];v010=unique([1:(v005+1) ...
1:8:(8*v005) 2:8:(8*v005)]);if numel(v007)>0,v007=unique(v007,'rows');v011=mat2cell(v007,...
ones(size(v007,1),1),v005);for v012=1:numel(v011),v013=dec2bin(double(v011{v012}))';
if~strcmp(v009,v013(v010)),v001='error';if v003,return,end,continue,end,v013(v010)='';if~v004,...
v014=uint32(bin2dec(v013));else,v014=uint32(bin2dec(v013.'));end,v000=JSON_f19(v000,v011{v012},...
v014);end,end,end,end
function v000=JSON_f25(v001),persistent v002,if isempty(v002),v002=exist('OCTAVE_VERSION',...
'builtin') ~=0;end,v001=uint32(v001);v003=v001>55295&v001<57344;if~any(v003),v000=v001;return,...
end,v004=find(v001>=55296&v001<=56319);v005=find(v001>=56320&v001<=57343);try v006=v005-v004;if ...
any(v006~=1)||isempty(v006),error('trigger error'),end,catch,...
error('input is not valid UTF-16 encoded'),end,v007='110110110111';v008=[1:6 17:22];v003=...
v001([v004.' v005.']);v003=unique(v003,'rows');v009=mat2cell(v003,ones(size(v003,1),1),2);v000=...
v001;for v010=1:numel(v009),v011=dec2bin(double(v009{v010}))';if~strcmp(v007,v011(v008)),...
error('input is not valid UTF-16 encoded'),end,v011(v008)='';if~v002,v012=uint32(bin2dec(v011));
else,v012=uint32(bin2dec(v011.'));end,v012=v012+65536;v000=JSON_f19(v000,v009{v010},v012);end,...
end
function[v000,v001,v002]=JSON_f26(v003,v004),if nargin<2,v004=[];end,v005=nargout==1;v003=...
uint32(reshape(v003,1,[]));[v002,v006,v007]=JSON_f24(v003,v005);if strcmp(v006,'success'),v001=...
true;v000=v002;elseif strcmp(v006,'error'),v001=false;if v005,JSON_f10(v004,v007),end,v000=v003;
end,end
function v000=JSON_f27(v001,v002),v003=double(JSON_f13('ImplicitExpansion')) + ...
double(JSON_f13('bsxfun'));if v003==2,v000=v001+v002;elseif v003==1,v000=bsxfun(@plus,v001,...
v002);else,v004=size(v001);v005=size(v002);v001=repmat(v001,max(1,v005./v004));v002=repmat(v002,...
max(1,v004./v005));v000=v001+v002;end,end
function v000=JSON_f28(v001,v002),v003=isa(v001,'char');v001=int32(v001);if nargin<2,if ...
any(v001==13),v001=JSON_f19(v001,int32([13 10]),int32(-10));v001(v001==13)=-10;end,v001(v001==...
10)=-10;else,for v004=1:numel(v002),v001=JSON_f19(v001,int32(v002{v004}),int32(-10));end,end,...
v005=[0 find(v001==-10) numel(v001)+1];v000=cell(numel(v005)-1,1);for v004=1:numel(v000),v006=...
(v005(v004)+1);v007=(v005(v004+1)-1);v000{v004}=v001(v006:v007);end,if v003,for v004=...
1:numel(v000),v000{v004}=char(v000{v004});end,else,for v004=1:numel(v000),v000{v004}=...
uint32(v000{v004});end,end,end
function v000=JSON_f29,persistent v001,if isempty(v001),if JSON_f14('<',0,'Octave','>',0),v002=...
struct('w',warning('off','all'));[v002.msg,v002.ID]=lastwarn;v001=~isequal(8364,...
double(char(8364)));warning(v002.w);lastwarn(v002.msg,v002.ID);else,v001=false;end,end,v000=...
v001;end
function[v000,v001]=JSON_f30(v002,v001),if nargin<2,v001=struct;end,if~isfield(v002,...
'print_to_con'),v002.print_to_con=[];end,if~isfield(v002,'print_to_fid'),v002.print_to_fid=[];
end,if~isfield(v002,'print_to_obj'),v002.print_to_obj=[];end,if~isfield(v002,'print_to_fcn'),...
v002.print_to_fcn=[];end,v003=true;v000=struct;v004=v002.print_to_fid;if isempty(v004),...
v000.boolean.fid=false;v000.fid=[];else,v003=false;v000.boolean.fid=true;v000.fid=v004;for v005=...
1:numel(v004),try v006=ftell(v004(v005));catch,v006=-1;end,if v004(v005)~=1&&v006==-1,...
v001.message=['Invalid print_to_fid parameter:',char(10),...
'should be a valid file identifier or 1.'];v001.identifier='HJW:print_to:ValidationFailed';v000=...
[];return,end,end,end,v004=v002.print_to_obj;if isempty(v004),v000.boolean.obj=false;v000.obj=...
[];else,v003=false;v000.boolean.obj=true;v000.obj=v004;for v005=1:numel(v004),try v007=...
get(v004(v005),'String');set(v004(v005),'String','');set(v004(v005),'String',v007);catch,...
v001.message=['Invalid print_to_obj parameter:',char(10),...
'should be a handle to an object with a writeable String property.'];v001.identifier=...
'HJW:print_to:ValidationFailed';v000=[];return,end,end,end,v004=v002.print_to_fcn;if ...
isempty(v004),v000.boolean.fcn=false;v000.fcn=[];else,v003=false;v000.boolean.fcn=true;v000.fcn=...
v004;try for v005=1:numel(v004),if~ismember(class(v004(v005).h),{'function_handle',...
'inline'})||numel(v004(v005).h)~=1,error('trigger error'),end,end,catch,v001.message=...
['Invalid print_to_fcn parameter:',char(10),...
'should be a struct with the h field containing a function handle,',char(10),...
'anonymous function or inline function.'];v001.identifier='HJW:print_to:ValidationFailed';v000=...
[];return,end,end,v004=v002.print_to_con;if isempty(v004),v000.boolean.con=v003;else,[v008,...
v000.boolean.con]=JSON_f20(v004);if~v008,v001.message=['Invalid print_to_con parameter:',...
char(10),'should be a scalar logical.'];v001.identifier='HJW:print_to:ValidationFailed';v000=[];
return,end,end,end

function varargout=makedir(d)
% Wrapper function to account for old Matlab releases, where mkdir fails if the parent folder does
% not exist. This function will use the legacy syntax for those releases.
if exist(d,'dir'),return,end % Take a shortcut if the folder already exists.
persistent IsLegacy
if isempty(IsLegacy)
    % The behavior changed after R14SP3 and before R2007b, but since the legacy syntax will still
    % work in later releases there isn't really a reason to pinpoint the exact release.
    checkpoint('makedir','ifversion')
    IsLegacy = ifversion('<','R2007b','Octave','<',0);
end
varargout = cell(1,nargout);
if IsLegacy
    [d_parent,d_target] = fileparts(d);
    [varargout{:}] = mkdir(d_parent,d_target);
else
    [varargout{:}] = mkdir(d);
end
end
function [opts,replaced]=parse_NameValue(default,varargin)
%Match the Name,Value pairs to the default option, attempting to autocomplete
%
% The autocomplete ignores incomplete names, case, underscores, and dashes, as long as a unique
% match can be found.
%
% The first output is a struct with the same fields as the first input, with field contents
% replaced according to the supplied options struct or Name,Value pairs.
% The second output is a cellstr containing the field names that have been set.
%
% If this fails to find a match, this will throw an error with the offending name as the message.
%
% If there are multiple occurrences of a Name, only the last Value will be returned. This is the
% same as Matlab internal functions like plot. GNU Octave also has this behavior.
%
% If a struct array is provided, only the first element will be used. An empty struct array will
% trigger an error.

switch numel(default)
    case 0
        error('parse_NameValue:MixedOrBadSyntax',...
            'Optional inputs must be entered as Name,Value pairs or as a scalar struct.')
    case 1
        % Do nothing.
    otherwise
        % If this is a struct array, explicitly select the first element.
        default=default(1);
end

% Create default output and return if no other inputs exist.
opts = default;replaced = {};
if nargin==1,return,end

% Unwind an input struct to Name,Value pairs.
try
    struct_input = numel(varargin)==1 && isa(varargin{1},'struct');
    NameValue_input = mod(numel(varargin),2)==0 && all(...
        cellfun('isclass',varargin(1:2:end),'char'  ) | ...
        cellfun('isclass',varargin(1:2:end),'string')   );
    if ~( struct_input || NameValue_input )
        error('trigger')
    end
    if nargin==2
        Names = fieldnames(varargin{1});
        Values = struct2cell(varargin{1});
    else
        % Wrap in cellstr to account for strings (this also deals with the fun(Name=Value) syntax).
        Names = cellstr(varargin(1:2:end));
        Values = varargin(2:2:end);
    end
    if ~iscellstr(Names),error('trigger');end %#ok<ISCLSTR>
catch
    % If this block errors, that is either because a missing Value with the Name,Value syntax, or
    % because the struct input is not a struct, or because an attempt was made to mix the two
    % styles. In future versions of this functions an effort might be made to handle such cases.
    error('parse_NameValue:MixedOrBadSyntax',...
        'Optional inputs must be entered as Name,Value pairs or as a scalar struct.')
end

% The fieldnames will be converted to char matrices in the section below. First an exact match is
% tried, then a case-sensitive (partial) match, then ignoring case, followed by ignoring any
% underscores, and lastly ignoring dashes.
default_Names = fieldnames(default);
Names_char    = cell(1,4);
Names_cell{1} = default_Names;
Names_cell{2} = lower(Names_cell{1});
Names_cell{3} = strrep(Names_cell{2},'_','');
Names_cell{4} = strrep(Names_cell{3},'-','');

% Allow spaces by replacing them with underscores.
Names = strrep(Names,' ','_');

% Attempt to match the names.
replaced = false(size(default_Names));
for n=1:numel(Names)
    name = Names{n};
    
    % Try a case-sensitive match.
    [match_idx,Names_char{1}] = parse_NameValue__find_match(Names_char{1},Names_cell{1},name);
    
    % Try a case-insensitive match.
    if numel(match_idx)~=1
        name = lower(name);
        [match_idx,Names_char{2}] = parse_NameValue__find_match(Names_char{2},Names_cell{2},name);
    end
    
    % Try a case-insensitive match ignoring underscores.
    if numel(match_idx)~=1
        name = strrep(name,'_','');
        [match_idx,Names_char{3}] = parse_NameValue__find_match(Names_char{3},Names_cell{3},name);
    end
    
    % Try a case-insensitive match ignoring underscores and dashes.
    if numel(match_idx)~=1
        name = strrep(name,'-','');
        [match_idx,Names_char{4}] = parse_NameValue__find_match(Names_char{4},Names_cell{4},name);
    end
    
    if numel(match_idx)~=1
        error('parse_NameValue:NonUniqueMatch',Names{n})
    end
    
    % Store the Value in the output struct and mark it as replaced.
    opts.(default_Names{match_idx}) = Values{n};
    replaced(match_idx)=true;
end
replaced = default_Names(replaced);
end
function [match_idx,Names_char]=parse_NameValue__find_match(Names_char,Names_cell,name)
% Try to match the input field to the fields of the struct.

% First attempt an exact match.
match_idx = find(ismember(Names_cell,name));
if numel(match_idx)==1,return,end

% Only spend time building the char array if this point is reached.
if isempty(Names_char),Names_char = parse_NameValue__name2char(Names_cell);end

% Since the exact match did not return a unique match, attempt to match the start of each array.
% Select the first part of the array. Since Names is provided by the user it might be too long.
tmp = Names_char(:,1:min(end,numel(name)));
if size(tmp,2)<numel(name)
    tmp = [tmp repmat(' ', size(tmp,1) , numel(name)-size(tmp,2) )];
end

% Find the number of non-matching characters on every row. The cumprod on the logical array is
% to make sure that only the starting match is considered.
non_matching = numel(name)-sum(cumprod(double(tmp==repmat(name,size(tmp,1),1)),2),2);
match_idx = find(non_matching==0);
end
function Names_char=parse_NameValue__name2char(Names_char)
% Convert a cellstr to a padded char matrix.
len = cellfun('prodofsize',Names_char);maxlen = max(len);
for n=find(len<maxlen).' % Pad with spaces where needed
    Names_char{n}((end+1):maxlen) = ' ';
end
Names_char = vertcat(Names_char{:});
end
function pick=parse_NameValue_option(AllowedChoices,pick)
% Parse a selection option from a list. This function parses the option, accounting for incorrect
% captitalization, incomplete names, and extra/missing dashes/underscores.
% The options must be valid field names. If anything fails, the output will be set to ''.

try
    AllowedChoices      = AllowedChoices(:).';
    AllowedChoices(2,:) = {0};
    AllowedChoices      = struct(AllowedChoices{:});
    
    checkpoint('parse_NameValue_option','parse_NameValue')
    [ignore,pick] = parse_NameValue(AllowedChoices,pick,1); %#ok<ASGLU>
    pick = pick{1};
catch
    pick = '';
end
end
function [opts,named_fields]=parse_print_to___get_default
% This returns the default struct for use with warning_ and error_. The second output contains all
% the possible field names that can be used with the parser.
persistent opts_ named_fields_
if isempty(opts_)
    [opts_,named_fields_] = parse_print_to___get_default_helper;
end
opts = opts_;
named_fields = named_fields_;
end
function [opts_,named_fields_]=parse_print_to___get_default_helper
default_params = struct(...
    'ShowTraceInMessage',false,...
    'WipeTraceForBuiltin',false);
opts_ = struct(...
    'params',default_params,...
    'fid',[],...
    'obj',[],...
    'fcn',struct('h',{},'data',{}),...
    'boolean',struct('con',[],'fid',false,'obj',false,'fcn',false,'IsValidated',false));
named_fields_params = fieldnames(default_params);
for n=1:numel(named_fields_params)
    named_fields_params{n} = ['option_' named_fields_params{n}];
end
named_fields_ = [...
    {'params'};
    named_fields_params;...
    {'con';'fid';'obj';'fcn'}];
for n=1:numel(named_fields_)
    named_fields_{n} = ['print_to_' named_fields_{n}];
end
named_fields_ = sort(named_fields_);
end
function opts=parse_print_to___named_fields_to_struct(named_struct)
% This function parses the named fields (print_to_con, print_to_fcn, etc) to the option struct
% syntax that warning_ and error_ expect. Any additional fields are ignored.
% Note that this function will not validate the contents after parsing and the validation flag will
% be set to false.
%
% Input struct:
% options.print_to_con=true;      % or false
% options.print_to_fid=fid;       % or []
% options.print_to_obj=h_obj;     % or []
% options.print_to_fcn=struct;    % or []
% options.print_to_params=struct; % or []
%
% Output struct:
% options.params
% options.fid
% options.obj
% options.fcn.h
% options.fcn.data
% options.boolean.con
% options.boolean.fid
% options.boolean.obj
% options.boolean.fcn
% options.boolean.IsValidated

persistent default print_to_option__field_names_in print_to_option__field_names_out
if isempty(print_to_option__field_names_in)
    % Generate the list of options that can be set by name.
    checkpoint('parse_print_to___named_fields_to_struct','parse_print_to___get_default')
    [default,print_to_option__field_names_in] = parse_print_to___get_default;
    pattern = 'print_to_option_';
    for n=numel(print_to_option__field_names_in):-1:1
        if ~strcmp(pattern,print_to_option__field_names_in{n}(1:min(end,numel(pattern))))
            print_to_option__field_names_in( n)=[];
        end
    end
    print_to_option__field_names_out = strrep(print_to_option__field_names_in,pattern,'');
end

opts = default;

if isfield(named_struct,'print_to_params')
    opts.params = named_struct.print_to_params;
else
    % There might be param fields set with ['print_to_option_' parameter_name].
    for n=1:numel(print_to_option__field_names_in)
        field_in = print_to_option__field_names_in{n};
        if isfield(named_struct,print_to_option__field_names_in{n})
            field_out = print_to_option__field_names_out{n};
            opts.params.(field_out) = named_struct.(field_in);
        end
    end
end

if isfield(named_struct,'print_to_fid'),opts.fid = named_struct.print_to_fid;end
if isfield(named_struct,'print_to_obj'),opts.obj = named_struct.print_to_obj;end
if isfield(named_struct,'print_to_fcn'),opts.fcn = named_struct.print_to_fcn;end
if isfield(named_struct,'print_to_con'),opts.boolean.con = named_struct.print_to_con;end
opts.boolean.IsValidated = false;
end
function [isValid,ME,opts]=parse_print_to___validate_struct(opts)
% This function will validate all interactions. If a third output is requested, any invalid targets
% will be removed from the struct so the remaining may still be used.
% Any failures will result in setting options.boolean.con to true.
%
% NB: Validation will be skipped if opts.boolean.IsValidated is set to true.

% Initialize some variables.
AllowFailed = nargout>=3;
ME=struct('identifier','','message','');
isValid = true;
if nargout>=3,AllowFailed = true;end

% Check to see whether the struct has already been verified.
checkpoint('parse_print_to___validate_struct','test_if_scalar_logical')
[passed,IsValidated] = test_if_scalar_logical(opts.boolean.IsValidated);
if passed && IsValidated
    return
end

% Parse the logical that determines if a warning will be printed to the command window.
% This is true by default, unless an fid, obj, or fcn is specified, which is ensured elsewhere. If
% the fid/obj/fcn turn out to be invalid, this will revert to true at the end of this function.
checkpoint('parse_print_to___validate_struct','test_if_scalar_logical')
[passed,opts.boolean.con] = test_if_scalar_logical(opts.boolean.con);
if ~passed && ~isempty(opts.boolean.con)
    ME.message = ['Invalid print_to_con parameter:',char(10),...
        'should be a scalar logical or empty double.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:print_to:ValidationFailed';
    isValid = false;
    if ~AllowFailed,return,end
end

[ErrorFlag,opts.fid] = validate_fid(opts.fid);
if ErrorFlag
    ME.message = ['Invalid print_to_fid parameter:',char(10),...
        'should be a valid file identifier or 1.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:print_to:ValidationFailed';
    isValid = false;
    if ~AllowFailed,return,end
end
opts.boolean.fid = ~isempty(opts.fid);

[ErrorFlag,opts.obj]=validate_obj(opts.obj);
if ErrorFlag
    ME.message = ['Invalid print_to_obj parameter:',char(10),...
        'should be a handle to an object with a writeable String property.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:print_to:ValidationFailed';
    isValid = false;
    if ~AllowFailed,return,end
end
opts.boolean.obj = ~isempty(opts.obj);

[ErrorFlag,opts.fcn]=validate_fcn(opts.fcn);
if ErrorFlag
    ME.message = ['Invalid print_to_fcn parameter:',char(10),...
        'should be a struct with the h field containing a function handle,',char(10),...
        'anonymous function or inline function.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:print_to:ValidationFailed';
    isValid = false;
    if ~AllowFailed,return,end
end
opts.boolean.fcn = ~isempty(opts.fcn);

[ErrorFlag,opts.params]=validate_params(opts.params);
if ErrorFlag
    ME.message = ['Invalid print_to____params parameter:',char(10),...
        'should be a scalar struct uniquely matching parameter names.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:print_to:ValidationFailed';
    isValid = false;
    if ~AllowFailed,return,end
end

if isempty(opts.boolean.con)
    % Set default value.
    opts.boolean.con = ~any([opts.boolean.fid opts.boolean.obj opts.boolean.fcn]);
end

if ~isValid
    % If any error is found, enable the print to the command window to ensure output to the user.
    opts.boolean.con = true;
end

% While not all parameters may be present from the input struct, the resulting struct is as much
% validated as is possible to test automatically.
opts.boolean.IsValidated = true;
end
function [ErrorFlag,item]=validate_fid(item)
% Parse the fid. We can use ftell to determine if fprintf is going to fail.
ErrorFlag = false;
for n=numel(item):-1:1
    try position = ftell(item(n));catch,position = -1;end
    if item(n)~=1 && position==-1
        ErrorFlag = true;
        item(n)=[];
    end
end
end
function [ErrorFlag,item]=validate_obj(item)
% Parse the object handle. Retrieving from multiple objects at once works, but writing that output
% back to multiple objects doesn't work if Strings are dissimilar.
ErrorFlag = false;
for n=numel(item):-1:1
    try
        txt = get(item(n),'String'    ); % See if this triggers an error.
        set(      item(n),'String','' ); % Test if property is writable.
        set(      item(n),'String',txt); % Restore original content.
    catch
        ErrorFlag = true;
        item(n)=[];
    end
end
end
function [ErrorFlag,item]=validate_fcn(item)
% Parse the function handles. There is no convenient way to test whether the function actually
% accepts the inputs.
ErrorFlag = false;
for n=numel(item):-1:1
    if ~isa(item,'struct') || ~isfield(item,'h') ||...
            ~ismember(class(item(n).h),{'function_handle','inline'}) || numel(item(n).h)~=1
        ErrorFlag = true;
        item(n)=[];
    end
end
end
function [ErrorFlag,item]=validate_params(item)
% Fill any missing options with defaults. If the input is not a struct, this will return the
% defaults. Any fields that cause errors during parsing are ignored.
ErrorFlag = false;
persistent default_params
if isempty(default_params)
    checkpoint('parse_print_to___validate_struct','parse_print_to___get_default')
    default_params = parse_print_to___get_default;
    default_params = default_params.params;
end
if isempty(item),item=struct;end
if ~isa(item,'struct'),ErrorFlag = true;item = default_params;return,end
while true
    try MExc = []; %#ok<NASGU>
        checkpoint('parse_print_to___validate_struct','parse_NameValue')
        [item,replaced] = parse_NameValue(default_params,item);
        break
    catch MExc;if isempty(MExc),MExc = lasterror;end %#ok<LERR>
        ErrorFlag = true;
        % Remove offending field as option and retry. This will terminate, as removing all
        % fields will result in replacing the struct with the default.
        item = rmfield(item,MExc.message);
    end
end
for n=1:numel(replaced)
    p = replaced{n};
    switch p
        case 'ShowTraceInMessage'
            checkpoint('parse_print_to___validate_struct','test_if_scalar_logical')
            [passed,item.(p)] = test_if_scalar_logical(item.(p));
            if ~passed
                ErrorFlag=true;
                item.(p) = default_params.(p);
            end
        case 'WipeTraceForBuiltin'
            checkpoint('parse_print_to___validate_struct','test_if_scalar_logical')
            [passed,item.(p)] = test_if_scalar_logical(item.(p));
            if ~passed
                ErrorFlag=true;
                item.(p) = default_params.(p);
            end
    end
end
end
function [success,opts,ME,ReturnFlag,replaced]=parse_varargin_robust(default,varargin)
% This function will parse the optional input arguments. If any error occurs, it will attempt to
% parse the exception redirection parameters before returning.

% Pre-assign output.
success = false;
ReturnFlag = false;
ME = struct('identifier','','message','');
replaced = cell(0);

checkpoint('parse_varargin_robust','parse_NameValue')
try ME_ = [];[opts,replaced] = parse_NameValue(default,varargin{:}); %#ok<NASGU>
catch ME_;if isempty(ME_),ME_ = lasterror;end,ME = ME_;ReturnFlag=true;end %#ok<LERR>

if ReturnFlag
    % The normal parsing failed. We should still attempt to convert the input to a struct if it
    % isn't already, so we can attempt to parse the error redirection options.
    if isa(varargin{1},'struct')
        % Copy the input struct to this variable.
        opts = varargin{1};
    else
        % Attempt conversion from Name,Value to struct.
        try
            opts = struct(varargin{:});
        catch
            % Create an empty struct to make sure the variable exists.
            opts = struct;
        end
    end
    
    % Parse any relevant settings if possible.
    if isfield(opts,'print_to')
        print_to = opts.print_to;
    else
        checkpoint('parse_varargin_robust','parse_print_to___named_fields_to_struct')
        print_to = parse_print_to___named_fields_to_struct(opts);
    end
else
    % The normal parsing worked as expected. If print_to was provided as a field, we should use
    % that one instead of the named print_to_ options.
    if ismember('print_to',replaced)
        print_to = opts.print_to;
    else
        checkpoint('parse_varargin_robust','parse_print_to___named_fields_to_struct')
        print_to = parse_print_to___named_fields_to_struct(opts);
    end
end

% Attempt to parse the error redirection options (this generates an ME struct on fail) and validate
% the chosen parameters so we avoid errors in warning_ or error_.
checkpoint('parse_varargin_robust','parse_print_to___validate_struct')
[isValid,ME__print_to,opts.print_to] = parse_print_to___validate_struct(print_to);
if ~isValid,ME = ME__print_to;ReturnFlag = true;end
end
function [id,msg,stack,trace,no_op]=parse_warning_error_redirect_inputs(varargin)
no_op = false;
if nargin==1
    %  error_(options,msg)
    %  error_(options,ME)
    if isa(varargin{1},'struct') || isa(varargin{1},'MException')
        ME = varargin{1};
        if numel(ME)~=1
            no_op = true;
            [id,msg,stack,trace] = deal('');
            return
        end
        try
            stack = ME.stack; % Use the original call stack if possible.
            checkpoint('parse_warning_error_redirect_inputs','get_trace')
            trace = get_trace(0,stack);
        catch
            checkpoint('parse_warning_error_redirect_inputs','get_trace')
            [trace,stack] = get_trace(3);
        end
        id = ME.identifier;
        msg = ME.message;
        % This line will only appear on older releases.
        pat = 'Error using ==> ';
        if strcmp(msg(1:min(end,numel(pat))),pat)
            % Look for the first newline to strip the entire first line.
            ind = min(find(ismember(double(msg),[10 13]))); %#ok<MXFND>
            if any(double(msg(ind+1))==[10 13]),ind = ind-1;end
            msg(1:ind) = '';
        end
        pat = 'Error using <a href="matlab:matlab.internal.language.introspective.errorDocCallbac';
        % This pattern may occur when using try error(id,msg),catch,ME=lasterror;end instead of
        % catching the MException with try error(id,msg),catch ME,end.
        % This behavior is not stable enough to robustly check for it, but it only occurs with
        % lasterror, so we can use that.
        if isa(ME,'struct') && strcmp( pat , msg(1:min(end,numel(pat))) )
            % Strip the first line (which states 'error in function (line)', instead of only msg).
            msg(1:min(find(msg==10))) = ''; %#ok<MXFND>
        end
    else
        checkpoint('parse_warning_error_redirect_inputs','get_trace')
        [trace,stack] = get_trace(3);
        [id,msg] = deal('',varargin{1});
    end
else
    checkpoint('parse_warning_error_redirect_inputs','get_trace')
    [trace,stack] = get_trace(3);
    if ~isempty(strfind(varargin{1},'%')) % The id can't contain a percent symbol.
        %  error_(options,msg,A1,...,An)
        id = '';
        A1_An = varargin(2:end);
        msg = sprintf(varargin{1},A1_An{:});
    else
        %  error_(options,id,msg)
        %  error_(options,id,msg,A1,...,An)
        id = varargin{1};
        msg = varargin{2};
        if nargin>2
            A1_An = varargin(3:end);
            msg = sprintf(msg,A1_An{:});
        end
    end
end
end
function opts=parse_warning_error_redirect_options(opts)
% The input is either:
% - an empty struct
% - the long form struct (with fields names 'print_to_')
% - the short hand struct (the print_to struct with the fields 'boolean', 'fid', etc)
%
% The returned struct will be a validated short hand struct.

if ...
        isfield(opts,'boolean') && ...
        isfield(opts.boolean,'IsValidated') && ...
        opts.boolean.IsValidated
    % Do not re-check a struct that self-reports to be validated.
    return
end

try
    % First, attempt to replace the default values with the entries in the input struct.
    % If the input is the long form struct, this will fail.
    checkpoint('parse_warning_error_redirect_options','parse_NameValue','parse_print_to___get_default')
    print_to = parse_NameValue(parse_print_to___get_default,opts);
    print_to.boolean.IsValidated = false;
catch
    % Apparently the input is the long form struct, and therefore should be parsed to the short
    % form struct, after which it can be validated.
    checkpoint('parse_warning_error_redirect_options','parse_print_to___named_fields_to_struct')
    print_to = parse_print_to___named_fields_to_struct(opts);
end

% Now we can validate the struct. Here we will ignore any invalid parameters, replacing them with
% the default settings.
checkpoint('parse_warning_error_redirect_options','parse_print_to___validate_struct')
[ignore,ignore,opts] = parse_print_to___validate_struct(print_to); %#ok<ASGLU>
end
function out=PatternReplace(in,pattern,rep)
%Functionally equivalent to strrep, but extended to more data types.
% Any input is converted to a row vector.

in = reshape(in,1,[]);
out = in;
if numel(pattern)==0 || numel(pattern)>numel(in)
    % Return input unchanged (apart from the reshape), as strrep does as well.
    return
end

L = true(size(in));
L((end-numel(pattern)+2):end) = false; % Avoid partial matches
for n=1:numel(pattern)
    % For every element of the pattern, look for matches in the data. Keep track of all possible
    % locations of a match by shifting the logical vector.
    % The last n elements should be left unchanged, to avoid false positives with a wrap-around.
    L_n = in==pattern(n);
    L_n = circshift(L_n,[0 1-n]);
    L_n(1:(n-1)) = L(1:(n-1));
    L = L & L_n;
    
    % If there are no matches left (even if n<numel(pat)), the process can be aborted.
    if ~any(L),return,end
end

if numel(rep)==0
    out(L)=[];
    return
end

% For the replacement, we will create a shadow copy with a coded char array. Non-matching values
% will be coded with a space, the first character of a match will be encoded with an asterisk, and
% trailing characters will be encoded with an underscore.
% In the next step, regexprep will be used to perform the replacement, after which indexing can be
% used to compose the final array.
if numel(pattern)>1
    checkpoint('PatternReplace','bsxfun_plus')
    idx = bsxfun_plus(find(L),reshape(1:(numel(pattern)-1),[],1));
else
    idx = find(L);
end
idx = reshape(idx,1,[]);
str = repmat(' ',1,numel(in));
str(idx) = '_';
str( L ) = '*';
NonMatchL = str==' ';

% The regular expression will take care of the lazy pattern matching. This also shifts the number
% of underscores to the length of the replacement array.
str = regexprep(str,'\*_*',['*' repmat('_',1,numel(rep)-1)]);

% We can paste in the non-matching positions. Positions where the replacement should be inserted
% may or may not be correct.
out(str==' ') = in(NonMatchL);

% Now we can paste in all the replacements.
x = strfind(str,'*');
checkpoint('PatternReplace','bsxfun_plus')
idx = bsxfun_plus(x,reshape(0:(numel(rep)-1),[],1));
idx = reshape(idx,1,[]);
out(idx) = repmat(rep,1,numel(x));

% Remove the elements beyond the range of what the resultant array should be.
out((numel(str)+1):end) = [];
end
function A=randi_stable_seed(minmax,sz)
% This uses the GCC LCG to generate values and MINSTD to generate new seed values.
% https://en.wikipedia.org/wiki/Linear_congruential_generator
% https://en.wikipedia.org/wiki/Lehmer_random_number_generator
%
% Syntax:
%   randi_stable_seed('reset')
%   randi_stable_seed('reset',seed_intialize_value)
%   A = randi_stable_seed(minmax,sz)
if isa(minmax,'char') && strcmp(minmax,'reset')
    if nargin<2,seed_intialize_value=default_init_seed;else,seed_intialize_value=sz;end
    GCC_LCG__advance_seed(seed_intialize_value)
    return
end
% Generate the array using the automatically altered seed.
A = internal_GCC_LCG(minmax,sz,GCC_LCG__advance_seed);
end
function A=internal_GCC_LCG(minmax,sz,seed)
% This is the actual LCG.
A=zeros(sz);
if numel(minmax)==1,minmax=[1 minmax];end
m = 2^31;a = 1103515245;c = 12345;
N = abs(diff(minmax))+1;
A(1) = seed;
for n=2:numel(A)
    A(n) = mod(a*A(n-1)+c,m);
end
A = mod(A,N)+min(minmax);
end
function val=default_init_seed,val=1;end
function seed = GCC_LCG__advance_seed(init_val)
% Generate a seed that automatically advances.
persistent seed_
if isempty(seed_) || nargin==1
    if nargin==0,init_val=default_init_seed;end
    x = randi_MINSTD([1 2^30],[1 2],init_val);
    seed_ = randi_MINSTD([1 x(1)],[1 5],x(2));
    if nargin==1,return,end
end
% Use a product and addition to avoid the minmax trending to 1.
seed_ = randi_MINSTD(...
    [1 sum(seed_)],...
    [1 5],...
    seed_(2)*(1+seed_(3))*(2+seed_(4)));
% Extract a single value to serve as the real seed.
seed = seed_(5);
end
function A=randi_MINSTD(minmax,sz,seed)
% https://en.wikipedia.org/wiki/Lehmer_random_number_generator
A = zeros(sz);
a = 48271;m = 2^31 - 1;
N = abs(diff(minmax))+1;
A(1) = seed;
for n=2:numel(A)
    A(n) = mod(a*A(n-1),m);
end
A = mod(A,N)+min(minmax);
end
function v000=readfile(v001,varargin),if nargin<1,error('HJW:readfile:nargin',...
'Incorrect number of input arguments.'),end,if~(nargout==0||nargout==1),...
error('HJW:readfile:nargout','Incorrect number of output arguments.'),end,[v002,v003,v004]=...
readfile_f00(v001,varargin{:});if~v002,readfile_f38(v003.print_to,v004),else,[v001,v005,v006,...
v007,v008,v009,v010,v011,v012,v013,v014]=deal(v003.filename,v003.print_to,v003.legacy,...
v003.UseURLread,v003.err_on_ANSI,v003.EmptyLineRule,v003.Whitespace,v003.LineEnding,...
v003.FailMultiword_UTF16,v003.WhitespaceRule,v003.weboptions);end,if v003.OfflineFile,v000=...
readfile_f29(v001,v011,v005,v008);else,if~v006.allows_https&&strcmpi(v001(1:min(end,8)),...
'https://'),readfile_f39(v005,'HJW:readfile:httpsNotSupported',...
['This implementation of urlread probably doesn''t allow https requests.',char(10),...
'The next lines of code will probably result in an error.']),end,v015=readfile_f30(v001,v007,...
v005,v011,v008,v014);if isa(v015,'cell'),v000=v015;else,v016=true;v015=readfile_f37(v015,v016);
try v004=[];[v017,v018,v019]=readfile_f19(v015);catch v004;if isempty(v004),v004=lasterror;end,...
if strcmp(v004.identifier,'HJW:UTF8_to_unicode:notUTF8'),v018=false;else,readfile_f38(v005,...
v004),end,end,if v018,v015=readfile_f35(v019);end,if isa(v011,'double')&&isempty(v011),v000=...
readfile_f26(v015);else,v000=readfile_f26(v015,v011);end,end,end,if~strcmp(v009,...
'read')||~strcmp(v013,'preserve'),v020=cellfun('isempty',v000);for v021=find(~v020).',v022=...
ismember(v000{v021},v010);v020(v021)=all(v022);if~strcmp(v013,'preserve'),if v020(v021),...
v000{v021}='';continue,end,if~v022(1)&&~v022(end),continue,end,switch v013,case'trim',v023=...
find(~v022);v023=v023([1 end]);case'trimleading',v023=[readfile_f02(~v022,1) numel(v022)];
case'trimtrailing',v023=[1 readfile_f02(~v022,1,'last')];end,v000{v021}=...
v000{v021}(v023(1):v023(2));end,end,end,if~strcmp(v009,'read'),switch v009,case'skip',...
v000(v020)=[];case'error',if any(v020),readfile_f38(v005,'HJW:readfile:EmptyLinesRuleError',...
'Unexpected empty line detected on row %d',readfile_f02(v020,1)),end,case'skipleading',if ...
v020(1),v024=1:(readfile_f02(~v020,1,'first')-1);v000(v024)=[];end,case'skiptrailing',if ...
v020(end),v024=(1+readfile_f02(~v020,1,'last')):numel(v020);v000(v024)=[];end,end,end,...
persistent v025,if isempty(v025),v025=readfile_f06('<',0,'Octave','>',0);end,if v012,for v021=...
1:numel(v000),if v025,if any(v000{v021}>=240),v000{v021}=readfile_f03(v000{v021});end,else,if ...
any(v000{v021}>=55296&v000{v021}<=56319),v000{v021}=readfile_f03(v000{v021});end,end,end,end,end
function[v000,v001,v002]=readfile_f00(v003,varargin),[v004,v005]=readfile_f31;[v000,v001,v002,...
v006,v007]=readfile_f22(v004,varargin{:});if v006,return,end,[v008,v003]=readfile_f01(v003);try ...
v001.OfflineFile=~ (strcmpi(v003(1:min(end,7)),'http://')||strcmpi(v003(1:min(end,8)),...
'https://'));if v001.OfflineFile,if~exist(v003,'file'),v008=false;end,if~v008,error('trigger'),...
end,else,if numel(v003)<10,error('trigger'),end,end,v001.filename=v003;catch,v002.identifier=...
'HJW:readfile:IncorrectInput';v002.message=...
'The file must exist and the name must be a non-empty char or a scalar string.';return,end,if ...
numel(v007)==0,v000=true;v002=[];return,end,for v009=1:numel(v007),v010=v001.(v007{v009});
v002.identifier=['HJW:readfile:incorrect_input_opt_' lower(v007{v009})];switch v007{v009},case ...
v005,case'UseURLread',[v011,v010]=readfile_f32(v010);if~v011,v002.message=...
'UseURLread should be either true or false';return,end,v001.UseURLread=v010||v004.UseURLread;
case'err_on_ANSI',[v011,v010]=readfile_f32(v010);if~v011,v002.message=...
'err_on_ANSI should be either true or false';return,end,v001.err_on_ANSI=v010;
case'EmptyLineRule',if isa(v010,'string'),if numel(v010)~=1,v010=[];else,v010=char(v010);end,...
end,if isa(v010,'char'),v010=lower(v010);end,if~isa(v010,'char')||~ismember(v010,{'read','skip',...
'error','skipleading','skiptrailing'}),v002.message=...
'EmptyLineRule must be a char or string with a specific value.';return,end,v001.EmptyLineRule=...
v010;case'Whitespace',try switch class(v010),case'string',if numel(v010)~=1,...
error('trigger error'),end,v010=char(v010);case'cell',for v012=1:numel(v010),v010{v012}=...
sprintf(v010{v012});end,v010=horzcat(v010{:});case'char',otherwise,error('trigger error'),end,...
v001.Whitespace=v010;catch,v002.message=...
['The Whitespace parameter must be a char vector, string scalar ',...
'or cellstr.\nA cellstr input must be parsable by sprintf.'];return,end,case'WhitespaceRule',if ...
isa(v010,'string'),if numel(v010)~=1,v010=[];else,v010=char(v010);end,end,if isa(v010,'char'),...
v010=lower(v010);end,if~isa(v010,'char')||~ismember(v010,{'preserve','trim','trimleading',...
'trimtrailing'}),v002.message='WhitespaceRule must be a char or string with a specific value.';
return,end,v001.WhitespaceRule=v010;case'LineEnding',v013=false;if isa(v010,'string'),v010=...
cellstr(v010);if numel(v010)==1,v010=v010{1};end,end,if isa(v010,'cell'),try for v012=...
1:numel(v010),v010{v012}=sprintf(v010{v012});end,catch,v013=true;end,elseif isa(v010,'char'),...
v010={v010};else,v013=true;end,if v013||~iscellstr(v010),v002.message=...
['The LineEnding parameter must be a char vector, a string or a ',...
'cellstr.\nA cellstr or string vector input must be parsable by sprintf.'];return,end,if ...
isequal(v010,{char(10) char(13) char([13 10])}),v001.LineEnding=[];else,v001.LineEnding=v010;
end,case'UseReadlinesDefaults',[v011,v010]=readfile_f32(v010);if~v011,v002.message=...
'UseReadlinesDefaults should be either true or false';return,end,v001.UseReadlinesDefaults=v010;
case'weboptions',if~v001.OfflineFile&&~v004.UseURLread,v014=false;if~isa(v010,...
class(weboptions)),v014=true;else,try v010.ContentType=v004.weboptions.ContentType;catch,v014=...
true;end,end,if v014,v002.message='weboptions input is not valid';return,end,end,end,end,if ...
v001.UseReadlinesDefaults,v015=fieldnames(v004.ReadlinesDefaults);for v012=1:numel(v015),...
v001.(v015{v012})=v004.ReadlinesDefaults.(v015{v012});end,end,v000=true;v002=[];end
function[v000,v001]=readfile_f01(v001),v000=true;persistent v002,if isempty(v002),v002={'CON',...
'PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','LPT1','LPT2',...
'LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9'};end,if isa(v001,'string')&&numel(v001)==1,...
v001=char(v001);end,if~isa(v001,'char')||numel(v001)==0,v000=false;return,else,[v003,v004,v005]=...
fileparts(v001);v004=[v004,v005];if any(ismember([char(0:31) '<>:"/\|?*'],...
v004))||any(ismember(v002,upper(v004)))||any(v004(end)=='. '),v000=false;return,end,end,end
function varargout=readfile_f02(v000,varargin),...
if~(isnumeric(v000)||islogical(v000))||numel(v000)==0,error('HJW:findND:FirstInput',...
'Expected first input (X) to be a non-empty numeric or logical array.'),end,switch nargin,case ...
1,v001='first';v002=inf;case 2,v001='first';v002=varargin{1};
if~(isnumeric(v002)||islogical(v002))||numel(v002)~=1||any(v002<0),...
error('HJW:findND:SecondInput',...
'Expected second input (K) to be a positive numeric or logical scalar.'),end,case 3,v002=...
varargin{1};if~(isnumeric(v002)||islogical(v002))||numel(v002)~=1||any(v002<0),...
error('HJW:findND:SecondInput',...
'Expected second input (K) to be a positive numeric or logical scalar.'),end,v001=varargin{2};
if isa(v001,'string')&&numel(v001)==1,v001=char(v001);end,if~isa(v001,'char')||~(strcmpi(v001,...
'first')||strcmpi(v001,'last')),error('HJW:findND:ThirdInput',...
'Third input must be either ''first'' or ''last''.'),end,v001=lower(v001);otherwise,...
error('HJW:findND:InputNumber','Incorrect number of inputs.'),end,if ...
nargout>1&&nargout<ndims(v000),error('HJW:findND:Output',...
'Incorrect number of output arguments.'),end,persistent v003,if isempty(v003),v003=...
readfile_f06('<',7,'Octave','<',3);end,varargout=cell(max(1,nargout),1);if v003,if ...
nargout>ndims(v000),[v004,v005,v006]=find(v000(:));if length(v004)>v002,if strcmp(v001,'first'),...
v004=v004(1:v002);v006=v006(1:v002);else,v004=v004((end-v002+1):end);v006=...
v006((end-v002+1):end);end,end,[varargout{1:(end-1)}]=ind2sub(size(v000),v004);varargout{end}=...
v006;else,v004=find(v000);if numel(v004)>v002,if strcmp(v001,'first'),v004=v004(1:v002);else,...
v004=v004((end-v002+1):end);end,end,[varargout{:}]=ind2sub(size(v000),v004);end,else,if ...
nargout>ndims(v000),[v004,v005,v006]=find(v000(:),v002,v001);[varargout{1:(end-1)}]=...
ind2sub(size(v000),v004);varargout{end}=v006;else,v004=find(v000,v002,v001);[varargout{:}]=...
ind2sub(size(v000),v004);end,end,end
function v000=readfile_f03(v001),persistent v002,if isempty(v002),v002=exist('OCTAVE_VERSION',...
'builtin') ~=0;end,if v002,v003=readfile_f19(v001);else,v003=readfile_f18(v001);end,v003(v003>=...
65536)=26;if v002,v000=char(readfile_f20(v003));else,v000=char(readfile_f33(v003));end,end
function[v000,v001]=readfile_f04(v002,v001),if nargin==0,v002=1;end,if nargin<2,v001=dbstack;
end,v001(1:v002)=[];if~isfield(v001,'file'),for v003=1:numel(v001),v004=v001(v003).name;if ...
strcmp(v004(end),')'),v005=strfind(v004,'(');v006=v004((v005(end)+1):(end-1));v007=...
v004(1:(v005(end)-2));else,v007=v004;[v008,v006]=fileparts(v004);end,[v008,v001(v003).file]=...
fileparts(v007);v001(v003).name=v006;end,end,persistent v009,if isempty(v009),v009=...
readfile_f06('<',0,'Octave','>',0);end,if v009,for v003=1:numel(v001),[v008,v001(v003).file]=...
fileparts(v001(v003).file);end,end,v010=v001;v011='>';v000=cell(1,numel(v010)-1);for v003=...
1:numel(v010),[v012,v010(v003).file,v013]=fileparts(v010(v003).file);if v003==numel(v010),...
v010(v003).file='';end,if strcmp(v010(v003).file,v010(v003).name),v010(v003).file='';end,...
if~isempty(v010(v003).file),v010(v003).file=[v010(v003).file '>'];end,v000{v003}=...
sprintf('%c In %s%s (line %d)\n',v011,v010(v003).file,v010(v003).name,v010(v003).line);v011=' ';
end,v000=horzcat(v000{:});end
function v000=readfile_f05(v001),persistent v002,if isempty(v002),v002=...
struct('ImplicitExpansion',readfile_f06('>=','R2016b','Octave','>',0),'bsxfun',...
readfile_f06('>=','R2007a','Octave','>',0),'IntegerArithmetic',readfile_f06('>=','R2010b',...
'Octave','>',0),'String',readfile_f06('>=','R2016b','Octave','<',0),'HTTPS_support',...
readfile_f06('>',0,'Octave','<',0),'json',readfile_f06('>=','R2016b','Octave','>=',7),'strtrim',...
readfile_f06('>=',7,'Octave','>=',0),'accumarray',readfile_f06('>=',7,'Octave','>=',0));
v002.CharIsUTF8=readfile_f36;end,v000=v002.(v001);end
function v000=readfile_f06(v001,v002,v003,v004,v005),persistent v006 v007 v008,if isempty(v006),...
v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);v007={'R13' 605;
'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;'R2006a' 702;
'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;'R2009b' 709;
'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;'R2013a' 801;
'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;'R2016b' 901;
'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;'R2020a' 908;
'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913};end,if v008,if nargin==2,...
warning('HJW:ifversion:NoOctaveTest',['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);else,[v001,v009]=deal(v004,v005);v009=...
0.1*v009+0.9*fix(v009);v009=round(100*v009);end,else,if isnumeric(v002),v009=...
0.1*v002+0.9*fix(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,...
warning('HJW:ifversion:NotInDict','The requested version is not in the hard-coded list.'),v000=...
NaN;return,else,v009=v007{v010,2};end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=...
v006 < v009;case'<=',v000=v006 <=v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end
function[v000,v001]=readfile_f07(v002,varargin),switch numel(v002),case 0,...
error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),case 1,otherwise,...
v002=v002(1);end,v000=v002;v001={};if nargin==1,return,end,try v003=numel(varargin)==...
1&&isa(varargin{1},'struct');v004=mod(numel(varargin),2)==0&&all(cellfun('isclass',...
varargin(1:2:end),'char')|cellfun('isclass',varargin(1:2:end),'string'));if~(v003||v004),...
error('trigger'),end,if nargin==2,v005=fieldnames(varargin{1});v006=struct2cell(varargin{1});
else,v005=cellstr(varargin(1:2:end));v006=varargin(2:2:end);end,if~iscellstr(v005),...
error('trigger');end,catch,error('parse_NameValue:MixedOrBadSyntax',...
'Optional inputs must be entered as Name,Value pairs or as a scalar struct.'),end,v007=...
fieldnames(v002);v008=cell(1,4);v009{1}=v007;v009{2}=lower(v009{1});v009{3}=strrep(v009{2},'_',...
'');v009{4}=strrep(v009{3},'-','');v005=strrep(v005,' ','_');v001=false(size(v007));for v010=...
1:numel(v005),v011=v005{v010};[v012,v008{1}]=readfile_f08(v008{1},v009{1},v011);if numel(v012)~=...
1,v011=lower(v011);[v012,v008{2}]=readfile_f08(v008{2},v009{2},v011);end,if numel(v012)~=1,v011=...
strrep(v011,'_','');[v012,v008{3}]=readfile_f08(v008{3},v009{3},v011);end,if numel(v012)~=1,...
v011=strrep(v011,'-','');[v012,v008{4}]=readfile_f08(v008{4},v009{4},v011);end,if numel(v012)~=...
1,error('parse_NameValue:NonUniqueMatch',v005{v010}),end,v000.(v007{v012})=v006{v010};
v001(v012)=true;end,v001=v007(v001);end
function[v000,v001]=readfile_f08(v001,v002,v003),v000=find(ismember(v002,v003));if numel(v000)==...
1,return,end,if isempty(v001),v001=readfile_f09(v002);end,v004=v001(:,1:min(end,numel(v003)));
if size(v004,2)<numel(v003),v004=[v004 repmat(' ',size(v004,1),numel(v003)-size(v004,2))];end,...
v005=numel(v003)-sum(cumprod(double(v004==repmat(v003,size(v004,1),1)),2),2);v000=find(v005==0);
end
function v000=readfile_f09(v000),v001=cellfun('prodofsize',v000);v002=max(v001);for v003=...
find(v001<v002).',v000{v003}((end+1):v002)=' ';end,v000=vertcat(v000{:});end
function[v002,v003]=readfile_f10,persistent v000 v001,if isempty(v000),[v000,v001]=readfile_f11;
end,v002=v000;v003=v001;end
function[v001,v004]=readfile_f11,v000=struct('ShowTraceInMessage',false,'WipeTraceForBuiltin',...
false);v001=struct('params',v000,'fid',[],'obj',[],'fcn',struct('h',{},'data',{}),'boolean',...
struct('con',[],'fid',false,'obj',false,'fcn',false,'IsValidated',false));v002=fieldnames(v000);
for v003=1:numel(v002),v002{v003}=['option_' v002{v003}];end,v004=[{'params'};v002;{'con';'fid';
'obj';'fcn'}];for v003=1:numel(v004),v004{v003}=['print_to_' v004{v003}];end,v004=sort(v004);end
function v000=readfile_f12(v001),persistent v002 v003 v004,if isempty(v003),[v002,v003]=...
readfile_f10;v005='print_to_option_';for v006=numel(v003):-1:1,if~strcmp(v005,...
v003{v006}(1:min(end,numel(v005)))),v003(v006)=[];end,end,v004=strrep(v003,v005,'');end,v000=...
v002;if isfield(v001,'print_to_params'),v000.params=v001.print_to_params;else,for v006=...
1:numel(v003),v007=v003{v006};if isfield(v001,v003{v006}),v008=v004{v006};v000.params.(v008)=...
v001.(v007);end,end,end,if isfield(v001,'print_to_fid'),v000.fid=v001.print_to_fid;end,if ...
isfield(v001,'print_to_obj'),v000.obj=v001.print_to_obj;end,if isfield(v001,'print_to_fcn'),...
v000.fcn=v001.print_to_fcn;end,if isfield(v001,'print_to_con'),v000.boolean.con=...
v001.print_to_con;end,v000.boolean.IsValidated=false;end
function[v000,v001,v002]=readfile_f13(v002),v003=nargout>=3;v001=struct('identifier','',...
'message','');v000=true;if nargout>=3,v003=true;end,[v004,v005]=...
readfile_f32(v002.boolean.IsValidated);if v004&&v005,return,end,[v004,v002.boolean.con]=...
readfile_f32(v002.boolean.con);if~v004&&~isempty(v002.boolean.con),v001.message=...
['Invalid print_to_con parameter:',char(10),'should be a scalar logical or empty double.'];
v001.identifier='HJW:print_to:ValidationFailed';v000=false;if~v003,return,end,end,[v006,...
v002.fid]=readfile_f14(v002.fid);if v006,v001.message=['Invalid print_to_fid parameter:',...
char(10),'should be a valid file identifier or 1.'];v001.identifier=...
'HJW:print_to:ValidationFailed';v000=false;if~v003,return,end,end,v002.boolean.fid=...
~isempty(v002.fid);[v006,v002.obj]=readfile_f15(v002.obj);if v006,v001.message=...
['Invalid print_to_obj parameter:',char(10),...
'should be a handle to an object with a writeable String property.'];v001.identifier=...
'HJW:print_to:ValidationFailed';v000=false;if~v003,return,end,end,v002.boolean.obj=...
~isempty(v002.obj);[v006,v002.fcn]=readfile_f16(v002.fcn);if v006,v001.message=...
['Invalid print_to_fcn parameter:',char(10),...
'should be a struct with the h field containing a function handle,',char(10),...
'anonymous function or inline function.'];v001.identifier='HJW:print_to:ValidationFailed';v000=...
false;if~v003,return,end,end,v002.boolean.fcn=~isempty(v002.fcn);[v006,v002.params]=...
readfile_f17(v002.params);if v006,v001.message=['Invalid print_to____params parameter:',...
char(10),'should be a scalar struct uniquely matching parameter names.'];v001.identifier=...
'HJW:print_to:ValidationFailed';v000=false;if~v003,return,end,end,if isempty(v002.boolean.con),...
v002.boolean.con=~any([v002.boolean.fid v002.boolean.obj v002.boolean.fcn]);end,if~v000,...
v002.boolean.con=true;end,v002.boolean.IsValidated=true;end
function[v000,v001]=readfile_f14(v001),v000=false;for v002=numel(v001):-1:1,try v003=...
ftell(v001(v002));catch,v003=-1;end,if v001(v002)~=1&&v003==-1,v000=true;v001(v002)=[];end,end,...
end
function[v000,v001]=readfile_f15(v001),v000=false;for v002=numel(v001):-1:1,try v003=...
get(v001(v002),'String');set(v001(v002),'String','');set(v001(v002),'String',v003);catch,v000=...
true;v001(v002)=[];end,end,end
function[v000,v001]=readfile_f16(v001),v000=false;for v002=numel(v001):-1:1,...
if~ismember(class(v001(v002).h),{'function_handle','inline'})||numel(v001(v002).h)~=1,v000=true;
v001(v002)=[];end,end,end
function[v000,v001]=readfile_f17(v001),v000=false;persistent v002,if isempty(v002),v002=...
readfile_f10;v002=v002.params;end,if isempty(v001),v001=struct;end,if~isa(v001,'struct'),v000=...
true;v001=v002;return,end,while true,try v003=[];[v001,v004]=readfile_f07(v002,v001);break,...
catch v003;if isempty(v003),v003=lasterror;end,v000=true;v001=rmfield(v001,v003.message);end,...
end,for v005=1:numel(v004),v006=v004{v005};switch v006,case'ShowTraceInMessage',[v007,...
v001.(v006)]=readfile_f32(v001.(v006));if~v007,v000=true;v001.(v006)=v002.(v006);end,...
case'WipeTraceForBuiltin',[v007,v001.(v006)]=readfile_f32(v001.(v006));if~v007,v000=true;
v001.(v006)=v002.(v006);end,end,end,end
function v000=readfile_f18(v001),persistent v002,if isempty(v002),v002=exist('OCTAVE_VERSION',...
'builtin') ~=0;end,v001=uint32(v001);v003=v001>55295&v001<57344;if~any(v003),v000=v001;return,...
end,v004=find(v001>=55296&v001<=56319);v005=find(v001>=56320&v001<=57343);try v006=v005-v004;if ...
any(v006~=1)||isempty(v006),error('trigger error'),end,catch,...
error('input is not valid UTF-16 encoded'),end,v007='110110110111';v008=[1:6 17:22];v003=...
v001([v004.' v005.']);v003=unique(v003,'rows');v009=mat2cell(v003,ones(size(v003,1),1),2);v000=...
v001;for v010=1:numel(v009),v011=dec2bin(double(v009{v010}))';if~strcmp(v007,v011(v008)),...
error('input is not valid UTF-16 encoded'),end,v011(v008)='';if~v002,v012=uint32(bin2dec(v011));
else,v012=uint32(bin2dec(v011.'));end,v012=v012+65536;v000=readfile_f28(v000,v009{v010},v012);
end,end
function[v000,v001,v002]=readfile_f19(v003,v004),if nargin<2,v004=[];end,v005=nargout==1;v003=...
uint32(reshape(v003,1,[]));[v002,v006,v007]=readfile_f21(v003,v005);if strcmp(v006,'success'),...
v001=true;v000=v002;elseif strcmp(v006,'error'),v001=false;if v005,readfile_f38(v004,v007),end,...
v000=v003;end,end
function v000=readfile_f20(v001),if numel(v001)>1,...
error('this should only be used for single characters'),end,if v001<128,v000=v001;return,end,...
persistent v002,if isempty(v002),v002=struct;v002.limits.lower=hex2dec({'0000','0080','0800',...
'10000'});v002.limits.upper=hex2dec({'007F','07FF','FFFF','10FFFF'});v002.scheme{2}=...
'110xxxxx10xxxxxx';v002.scheme{2}=reshape(v002.scheme{2}.',8,2);v002.scheme{3}=...
'1110xxxx10xxxxxx10xxxxxx';v002.scheme{3}=reshape(v002.scheme{3}.',8,3);v002.scheme{4}=...
'11110xxx10xxxxxx10xxxxxx10xxxxxx';v002.scheme{4}=reshape(v002.scheme{4}.',8,4);for v003=2:4,...
v002.scheme_pos{v003}=find(v002.scheme{v003}=='x');v002.bits(v003)=numel(v002.scheme_pos{v003});
end,end,v004=find(v002.limits.lower<=v001&v001<=v002.limits.upper);v000=v002.scheme{v004};v005=...
v002.scheme_pos{v004};v003=dec2bin(double(v001),v002.bits(v004));v000(v005)=v003;v000=...
bin2dec(v000.').';end
function[v000,v001,v002]=readfile_f21(v000,v003),v001='success';v002=struct('identifier',...
'HJW:UTF8_to_unicode:notUTF8','message','Input is not UTF-8.');persistent v004,if isempty(v004),...
v004=readfile_f06('<',0,'Octave','>',0);end,if any(v000>255),v001='error';if v003,return,end,...
elseif all(v000<128),return,end,for v005=4:-1:2,v006=bin2dec([repmat('1',1,v005) repmat('0',1,...
8-v005)]);v007=v000>=v006&v000<256;if any(v007),v007=find(v007);v007=v007(:).';if ...
numel(v000)<(max(v007)+v005-1),v001='error';if v003,return,end,v007((v007+v005-1)>numel(v000))=...
[];end,if~isempty(v007),v008=readfile_f25(v007,(0:(v005-1)).');v008=v008.';v007=v000(v008);end,...
else,v007=[];end,v009=[repmat('1',1,v005-1) repmat('10',1,v005)];v010=unique([1:(v005+1) ...
1:8:(8*v005) 2:8:(8*v005)]);if numel(v007)>0,v007=unique(v007,'rows');v011=mat2cell(v007,...
ones(size(v007,1),1),v005);for v012=1:numel(v011),v013=dec2bin(double(v011{v012}))';
if~strcmp(v009,v013(v010)),v001='error';if v003,return,end,continue,end,v013(v010)='';if~v004,...
v014=uint32(bin2dec(v013));else,v014=uint32(bin2dec(v013.'));end,v000=readfile_f28(v000,...
v011{v012},v014);end,end,end,end
function[v000,v001,v002,v003,v004]=readfile_f22(v005,varargin),v000=false;v003=false;v002=...
struct('identifier','','message','');v004=cell(0);try v006=[];[v001,v004]=readfile_f07(v005,...
varargin{:});catch v006;if isempty(v006),v006=lasterror;end,v002=v006;v003=true;end,if v003,if ...
isa(varargin{1},'struct'),v001=varargin{1};else,try v001=struct(varargin{:});catch,v001=struct;
end,end,if isfield(v001,'print_to'),v007=v001.print_to;else,v007=readfile_f12(v001);end,else,if ...
ismember('print_to',v004),v007=v001.print_to;else,v007=readfile_f12(v001);end,end,[v008,v009,...
v001.print_to]=readfile_f13(v007);if~v008,v002=v009;v003=true;end,end
function[v000,v001,v002,v003,v004]=readfile_f23(varargin),v004=false;if nargin==1,if ...
isa(varargin{1},'struct')||isa(varargin{1},'MException'),v005=varargin{1};if numel(v005)~=1,...
v004=true;[v000,v001,v002,v003]=deal('');return,end,try v002=v005.stack;v003=readfile_f04(0,...
v002);catch,[v003,v002]=readfile_f04(3);end,v000=v005.identifier;v001=v005.message;v006=...
'Error using ==> ';if strcmp(v001(1:min(end,numel(v006))),v006),v007=...
min(find(ismember(double(v001),[10 13])));if any(double(v001(v007+1))==[10 13]),v007=v007-1;end,...
v001(1:v007)='';end,v006=...
'Error using <a href="matlab:matlab.internal.language.introspective.errorDocCallbac';if ...
isa(v005,'struct')&&strcmp(v006,v001(1:min(end,numel(v006)))),v001(1:min(find(v001==10)))='';
end,else,[v003,v002]=readfile_f04(3);[v000,v001]=deal('',varargin{1});end,else,[v003,v002]=...
readfile_f04(3);if~isempty(strfind(varargin{1},'%')),v000='';v008=varargin(2:end);v001=...
sprintf(varargin{1},v008{:});else,v000=varargin{1};v001=varargin{2};if nargin>2,v008=...
varargin(3:end);v001=sprintf(v001,v008{:});end,end,end,end
function v000=readfile_f24(v000),if isfield(v000,'boolean')&&isfield(v000.boolean,...
'IsValidated')&&v000.boolean.IsValidated,return,end,try v001=readfile_f07(readfile_f10,v000);
v001.boolean.IsValidated=false;catch,v001=readfile_f12(v000);end,[v002,v002,v000]=...
readfile_f13(v001);end
function v000=readfile_f25(v001,v002),persistent v003,if isempty(v003),v003=...
double(readfile_f05('ImplicitExpansion')) + double(readfile_f05('bsxfun'));end,if v003==2,v000=...
v001+v002;elseif v003==1,v000=bsxfun(@plus,v001,v002);else,v004=size(v001);v005=size(v002);if ...
min([v004 v005])==0,v004(v004==0)=inf;v005(v005==0)=inf;v006=max(v004,v005);v006(isinf(v006))=0;
v000=feval(str2func(class(v001)),zeros(v006));return,end,v001=repmat(v001,max(1,v005./v004));
v002=repmat(v002,max(1,v004./v005));v000=v001+v002;end,end
function v000=readfile_f26(v001,v002),v003=isa(v001,'char');v001=int32(v001);if nargin<2,if ...
any(v001==13),v001=readfile_f28(v001,int32([13 10]),int32(-10));v001(v001==13)=-10;end,...
v001(v001==10)=-10;else,for v004=1:numel(v002),v001=readfile_f28(v001,int32(v002{v004}),...
int32(-10));end,end,v005=[0 find(v001==-10) numel(v001)+1];v000=cell(numel(v005)-1,1);for v004=...
1:numel(v000),v006=(v005(v004)+1);v007=(v005(v004+1)-1);v000{v004}=v001(v006:v007);end,if v003,...
for v004=1:numel(v000),v000{v004}=char(v000{v004});end,else,for v004=1:numel(v000),v000{v004}=...
uint32(v000{v004});end,end,end
function v000=readfile_f27(v001,v002,v003),v000=v001(:)';if numel(v002)==0,v004=...
false(size(v001));elseif numel(v003)>numel(v002),error('not implemented (padding required)'),...
else,v004=true(size(v001));for v005=1:numel(v002),v006=find(v001==v002(v005));v006=v006-v005+1;
v006(v006<1)=[];v007=false(size(v004));v007(v006)=true;v004=v004&v007;if~any(v004),break,end,...
end,end,v006=find(v004);if~isempty(v006),for v005=1:numel(v003),v000(v006+v005-1)=v003(v005);
end,if numel(v003)==0,v005=0;end,if numel(v002)>v005,v006=v006(:);v008=(v005+1):numel(v002);
v009=readfile_f25(v006,v008-1);v009(ismember(v009,v006))=[];v000(v009(:))=[];end,end,end
function v000=readfile_f28(v001,v002,v003),v001=reshape(v001,1,[]);v000=v001;if numel(v002)==...
0||numel(v002)>numel(v001),return,end,v004=true(size(v001));v004((end-numel(v002)+2):end)=false;
for v005=1:numel(v002),v006=v001==v002(v005);v006=circshift(v006,[0 1-v005]);v006(1:(v005-1))=...
v004(1:(v005-1));v004=v004&v006;if~any(v004),return,end,end,if numel(v003)==0,v000(v004)=[];
return,end,if numel(v002)>1,v007=readfile_f25(find(v004),reshape(1:(numel(v002)-1),[],1));else,...
v007=find(v004);end,v007=reshape(v007,1,[]);v008=repmat(' ',1,numel(v001));v008(v007)='_';
v008(v004)='*';v009=v008==' ';v008=regexprep(v008,'\*_*',['*' repmat('_',1,numel(v003)-1)]);
v000(v008==' ')=v001(v009);v010=strfind(v008,'*');v007=readfile_f25(v010,...
reshape(0:(numel(v003)-1),[],1));v007=reshape(v007,1,[]);v000(v007)=repmat(v003,1,numel(v010));
v000((numel(v008)+1):end)=[];end
function v000=readfile_f29(v001,v002,v003,v004),persistent v005,if isempty(v005),v005=...
readfile_f06('<',0,'Octave','>',0);end,persistent v006,if isempty(v006),if v005,v007='Octave';
else,v007='Matlab';end,v006=sprintf(['%s could not read the file %%s.\n',...
'The file doesn''t exist or is not readable.\n',...
'(Note that for online files, only http and https is supported.)'],v007);end,v008=...
struct('identifier','HJW:readfile:ReadFail','message',sprintf(v006,v001));v009=fopen(v001,'rb');
if v009<0,readfile_f38(v003,v008),end,v010=fread(v009,'uint8=>uint8');fclose(v009);v010=v010.';
try v011=[];v012=true;v013=readfile_f19(v010);catch v011;if isempty(v011),v011=lasterror;end,if ...
strcmp(v011.identifier,'HJW:UTF8_to_unicode:notUTF8'),v012=false;if v004,readfile_f38(v003,...
'HJW:readfile:notUTF8','The provided file "%s" is not a correctly encoded UTF-8 file.',v001),...
end,else,readfile_f38(v003,v011),end,end,if v005,if v012,v000=v013;else,try v000=fileread(v001);
catch,readfile_f38(v003,v008),end,v000=readfile_f37(v000);end,else,if ispc,if v012,v000=v013;
else,if readfile_f06('<',7),try v000=fileread(v001);catch,readfile_f38(v003,v008),end,v000=...
readfile_f37(v000);else,try v000=fileread(v001);catch,readfile_f38(v003,v008),end,end,end,else,...
if v012,v000=v013;else,v000=readfile_f37(v010);end,end,end,if numel(v000)>=1&&double(v000(1))==...
65279,v000(1)=[];end,v000=readfile_f35(v000);if isa(v002,'double')&&isempty(v002),v000=...
readfile_f26(v000);else,v000=readfile_f26(v000,v002);end,end
function v000=readfile_f30(v001,v002,v003,v004,v005,v006),try v007=false;v008=...
readfile_f34('readfile_from_URL_tmp_','.txt');try if v002,v008=urlwrite(v001,v008);else,v008=...
websave(v008,v001,v006);end,v000=readfile_f29(v008,v004,v003,v005);catch,v007=true;end,try if ...
exist(v008,'file'),delete(v008);end,catch,end,if v007,error('revert to urlread'),end,catch,try ...
v009=[];if v002,v000=urlread(v001);else,v000=webread(v001,v006);end,catch v009;if isempty(v009),...
v009=lasterror;end,readfile_f38(v003,v009),end,end,end
function[v007,v008]=readfile_f31,persistent v000 v001,if isempty(v000),v002.allows_https=...
readfile_f05('HTTPS_support');v000.legacy=v002;try v003=isempty(which(func2str(@webread)));
catch,v003=true;end,try v004=isempty(which(func2str(@websave)));catch,v004=true;end,try v005=...
isempty(which(func2str(@weboptions)));catch,v005=true;end,v000.UseURLread=v003||v004||v005;
[v000.print_to,v001]=readfile_f10;for v006=1:numel(v001),v000.(v001{v006})=[];end,...
v000.err_on_ANSI=false;v000.FailMultiword_UTF16=false;v000.EmptyLineRule='read';v000.Whitespace=...
readfile_f35([8 9 28:32 160 5760 8192:8202 8239 8287 12288]);v000.DefaultLineEnding=true;
v000.LineEnding=[];v000.WhitespaceRule='preserve';if v005,v000.weboptions=struct('ContentType',...
'raw');else,try v000.weboptions=weboptions('ContentType','raw');catch,v000.weboptions=...
weboptions('ContentType','text');end,end,v000.UseReadlinesDefaults=false;
v000.ReadlinesDefaults.FailMultiword_UTF16=true;v000.ReadlinesDefaults.Whitespace=...
sprintf(' \b\t');end,v007=v000;v008=v001;end
function[v000,v001]=readfile_f32(v001),persistent v002,if isempty(v002),v002={true,false;1,0;
'on','off';'enable','disable';'enabled','disabled'};end,if isa(v001,...
'matlab.lang.OnOffSwitchState'),v000=true;v001=logical(v001);return,end,if isa(v001,'string'),...
if numel(v001)~=1,v000=false;return,else,v001=char(v001);end,end,if isa(v001,'char'),v001=...
lower(v001);end,for v003=1:size(v002,1),for v004=1:2,if isequal(v001,v002{v003,v004}),v000=true;
v001=v002{1,v004};return,end,end,end,v000=false;end
function v000=readfile_f33(v001),if v001<65536,v000=v001;return,end,v002=double(v001)-65536;
v002=dec2bin(v002,20);v000=bin2dec(['110110' v002(1:10);'110111' v002(11:20)]).';end
function v000=readfile_f34(v001,v002),if nargin<1,v001='';end,if~isempty(v001),v001=[v001 '_'];
end,if nargin<2,v002='';else,if~strcmp(v002(1),'.'),v002=['.' v002];end,end,v000=tempname;[v003,...
v004]=fileparts(v000);v000=fullfile(v003,[v001 v004 v002]);end
function v000=readfile_f35(v001,v002),persistent v003,if isempty(v003),v003=readfile_f06('<',0,...
'Octave','>',0);end,if nargin==1,v002=~readfile_f36;end,if v002,if all(v001<65536),v000=...
uint16(v001);v000=reshape(v000,1,numel(v000));else,[v004,v005,v006]=unique(v001);v000=cell(1,...
numel(v001));for v007=1:numel(v004),v008=readfile_f33(v004(v007));v008=uint16(v008);v000(v006==...
v007)={v008};end,v000=cell2mat(v000);end,if~v003,v000=char(v000);end,else,if all(v001<128),v000=...
char(v001);v000=reshape(v000,1,numel(v000));else,[v004,v005,v006]=unique(v001);v000=cell(1,...
numel(v001));for v007=1:numel(v004),v008=readfile_f20(v004(v007));v008=uint8(v008);v000(v006==...
v007)={v008};end,v000=cell2mat(v000);v000=char(v000);end,end,end
function v000=readfile_f36,persistent v001,if isempty(v001),if readfile_f06('<',0,'Octave','>',...
0),v002=struct('w',warning('off','all'));[v002.msg,v002.ID]=lastwarn;v001=~isequal(8364,...
double(char(8364)));warning(v002.w);lastwarn(v002.msg,v002.ID);else,v001=false;end,end,v000=...
v001;end
function v000=readfile_f37(v000,v001),persistent v002 v003,if isempty(v002),v004=[338 140;339 ...
156;352 138;353 154;376 159;381 142;382 158;402 131;710 136;732 152;8211 150;8212 151;8216 145;
8217 146;8218 130;8220 147;8221 148;8222 132;8224 134;8225 135;8226 149;8230 133;8240 137;8249 ...
139;8250 155;8364 128;8482 153];v002=v004(:,2);v003=v004(:,1);end,if nargin>1&&v001,v005=v003;
v006=v002;else,v005=v002;v006=v003;end,v000=uint32(v000);for v007=1:numel(v005),v000=...
readfile_f28(v000,v005(v007),v006(v007));end,end
function readfile_f38(v001,varargin),persistent v000,if isempty(v000),v000=func2str(...
@readfile_f38);end,if isempty(v001),v001=struct;end,v001=readfile_f24(v001);[v002,v003,v004,...
v005,v006]=readfile_f23(varargin{:});if v006,return,end,if v001.params.ShowTraceInMessage,v003=...
sprintf('%s\n%s',v003,v005);end,v007=struct('identifier',v002,'message',v003,'stack',v004);if ...
v001.params.WipeTraceForBuiltin,v007.stack=v004('name','','file','','line',[]);end,if ...
v001.boolean.obj,v008=v003;while v008(end)==10,v008(end)='';end,if any(v008==10),v008=...
readfile_f26(['Error: ' v008]);else,v008=['Error: ' v008];end,for v009=v001.obj(:).',try ...
set(v009,'String',v008);catch,end,end,end,if v001.boolean.fid,v010=datestr(now,31);for v011=...
v001.fid(:).',try fprintf(v011,'[%s] Error: %s\n%s',v010,v003,v005);catch,end,end,end,if ...
v001.boolean.fcn,if ismember(v000,{v004.name}),error('prevent recursion'),end,for v012=...
v001.fcn(:).',if isfield(v012,'data'),try feval(v012.h,'error',v007,v012.data);catch,end,else,...
try feval(v012.h,'error',v007);catch,end,end,end,end,rethrow(v007),end
function readfile_f39(v001,varargin),persistent v000,if isempty(v000),v000=func2str(...
@readfile_f39);end,if isempty(v001),v001=struct;end,v001=readfile_f24(v001);[v002,v003,v004,...
v005,v006]=readfile_f23(varargin{:});if v006,return,end,v007=warning;if ...
any(ismember({v007(ismember({v007.identifier},{v002,'all'})).state},'off')),return,end,v008=...
warning('query','backtrace');if strcmp(v008.state,'off'),v005='';end,if ...
v001.params.ShowTraceInMessage&&~isempty(v005),v003=sprintf('%s\n%s',v003,v005);end,if ...
v001.params.WipeTraceForBuiltin&&strcmp(v008.state,'on'),warning('off','backtrace'),end,if ...
v001.boolean.con,v009=warning('query','verbose');if strcmp(v009.state,'on'),warning('off',...
'verbose'),end,if~isempty(v002),warning(v002,'%s',v003),else,warning(v003),end,if ...
strcmp(v009.state,'on'),warning('on','verbose'),end,else,if~isempty(v002),lastwarn(v003,v002);
else,lastwarn(v003),end,end,if v001.params.WipeTraceForBuiltin&&strcmp(v008.state,'on'),...
warning('on','backtrace'),end,if v001.boolean.obj,v010=v003;while v010(end)==10,v010(end)=[];
end,if any(v010==10),v010=readfile_f26(['Warning: ' v010]);else,v010=['Warning: ' v010];end,...
set(v001.obj,'String',v010),for v011=v001.obj(:).',try set(v011,'String',v010);catch,end,end,...
end,if v001.boolean.fid,v012=datestr(now,31);for v013=v001.fid(:).',try fprintf(v013,...
'[%s] Warning: %s\n%s',v012,v003,v005);catch,end,end,end,if v001.boolean.fcn,if ismember(v000,...
{v004.name}),error('prevent recursion'),end,v014=struct('identifier',v002,'message',v003,...
'stack',v004);for v015=v001.fcn(:).',if isfield(v015,'data'),try feval(v015.h,'warning',v014,...
v015.data);catch,end,else,try feval(v015.h,'warning',v014);catch,end,end,end,end,end

function varargout=regexp_outkeys(v000,v001,varargin),if nargin<2,...
error('HJW:regexp_outkeys:SyntaxError','No supported syntax used: at least 3 inputs expected.'),...
end,if~(ischar(v000)&&ischar(v001)),error('HJW:regexp_outkeys:InputError',...
'All inputs must be char vectors.'),end,if nargout>nargin,error('HJW:regexp_outkeys:ArgCount',...
'Incorrect number of output arguments. Check syntax.'),end,persistent v002 v003 v004,if ...
isempty(v002),v002.start=true;v002.end=true;v002.match=regexp_outkeys_f01('<','R14','Octave',...
'<',4);v002.tokens=v002.match;v002.split=regexp_outkeys_f01('<','R2007b','Octave','<',4);v005=...
fieldnames(v002);v003=['Extra regexp output type not implemented,',char(10),...
'only the following',' types are implemented:',char(10),sprintf('%s, ',v005{:})];
v003((end-1):end)='';v002.any=v002.match||v002.split||v002.tokens;v004=v002;for v006=...
fieldnames(v004).',v004.(v006{1})=false;end,end,if v002.any||nargin==...
2||any(ismember(lower(varargin),{'start','end'})),[v007,v008,v009]=regexp(v000,v001);end,if ...
nargin==2,varargout={v007,v008,v009};return,end,varargout=cell(size(varargin));v010=v004;v011=...
[];for v012=1:(nargin-2),if~ischar(varargin{v012}),error('HJW:regexp_outkeys:InputError',...
'All inputs must be char vectors.'),end,switch lower(varargin{v012}),case'match',if v010.match,...
varargout{v012}=v013;continue,end,if v002.match,v013=cell(1,numel(v007));for v014=1:numel(v007),...
v013{v014}=v000(v007(v014):v008(v014));end,else,[v013,v007,v008]=regexp(v000,v001,'match');end,...
varargout{v012}=v013;v010.match=true;case'split',if v010.split,varargout{v012}=v011;continue,...
end,if v002.split,v011=cell(1,numel(v007)+1);v015=[v007 numel(v000)+1];v016=[0 v008];for v014=...
1:numel(v015),v011{v014}=v000((v016(v014)+1):(v015(v014)-1));if numel(v011{v014})==0,v011{v014}=...
char(ones(0,0));end,end,else,[v011,v007,v008]=regexp(v000,v001,'split');end,varargout{v012}=...
v011;v010.split=true;case'tokens',if v010.tokens,varargout{v012}=v017;continue,end,if ...
v002.tokens,v017=cell(numel(v009),0);for v014=1:numel(v009),if size(v009{v014},2)~=2,v017{v014}=...
cell(1,0);else,for v018=1:size(v009{v014},1),v017{v014}{v018}=v000(v009{v014}(v018,...
1):v009{v014}(v018,2));end,end,end,else,[v017,v007,v008]=regexp(v000,v001,'tokens');end,...
varargout{v012}=v017;v010.tokens=true;case'start',varargout{v012}=v007;case'end',...
varargout{v012}=v008;otherwise,error('HJW:regexp_outkeys:NotImplemented',v003),end,end,if ...
nargout>v012,varargout(v012+[1 2])={v007,v008};end,end
function v000=regexp_outkeys_f00(v000),v000=fix(v000+eps*1e3);end
function v000=regexp_outkeys_f01(v001,v002,v003,v004,v005),if nargin<2||nargout>1,...
error('incorrect number of input/output arguments'),end,persistent v006 v007 v008,if ...
isempty(v006),v008=exist('OCTAVE_VERSION','builtin');v006=[100,1] * sscanf(version,'%d.%d',2);
v007={'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;'R14SP3' 701;
'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;'R2008a' 706;'R2008b' 707;'R2009a' 708;
'R2009b' 709;'R2010a' 710;'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;'R2015b' 806;'R2016a' 900;
'R2016b' 901;'R2017a' 902;'R2017b' 903;'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;
'R2020a' 908;'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913;'R2023a' 914};end,...
if v008,if nargin==2,warning('HJW:ifversion:NoOctaveTest',...
['No version test for Octave was provided.',char(10),...
'This function might return an unexpected outcome.']),if isnumeric(v002),v009=...
0.1*v002+0.9*regexp_outkeys_f00(v002);v009=round(100*v009);else,v010=ismember(v007(:,1),v002);
if sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,elseif nargin==4,[v001,v009]=deal(v003,v004);v009=0.1*v009+0.9*regexp_outkeys_f00(v009);
v009=round(100*v009);else,[v001,v009]=deal(v004,v005);v009=...
0.1*v009+0.9*regexp_outkeys_f00(v009);v009=round(100*v009);end,else,if isnumeric(v002),v009=...
regexp_outkeys_f00(v002*100);if mod(v009,10)==0,v009=regexp_outkeys_f00(v002)*100+mod(v002,...
1)*10;end,else,v010=ismember(v007(:,1),v002);if sum(v010)~=1,warning('HJW:ifversion:NotInDict',...
'The requested version is not in the hard-coded list.'),v000=NaN;return,else,v009=v007{v010,2};
end,end,end,switch v001,case'==',v000=v006==v009;case'<',v000=v006 < v009;case'<=',v000=v006 <=...
v009;case'>',v000=v006 > v009;case'>=',v000=v006 >=v009;end,end

function SelfTestFailMessage=SelfTest__bsxfun_plus
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__bsxfun_plus','bsxfun_plus')
ParentFunction = 'bsxfun_plus';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            try ME=[];
                in1 = 1;
                in2 = ones(0,0);
                expected = [0 0];
                try   sz = size(bsxfun_plus(in1,in2));
                catch,sz=[];
                end
                if ~isequal(sz,expected)
                    error('unexpected output size: %s instead of %s',...
                        size_compose(sz),size_compose(expected))
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 2
            try ME=[];
                in1 = 1;
                in2 = ones(1,0);
                expected = [1 0];
                try   sz = size(bsxfun_plus(in1,in2));
                catch,sz=[];
                end
                if ~isequal(sz,expected)
                    error('unexpected output size: %s instead of %s',...
                        size_compose(sz),size_compose(expected))
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 3
            try ME=[];
                in1 = ones(0,1);
                in2 = ones(1,0);
                expected = [0 0];
                try   sz = size(bsxfun_plus(in1,in2));
                catch,sz=[];
                end
                if ~isequal(sz,expected)
                    error('unexpected output size: %s instead of %s',...
                        size_compose(sz),size_compose(expected))
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 4
            try ME=[];
                in1 = ones(1,1,2);
                in2 = ones(2,1);
                expected = [2 1 2];
                sz = size(bsxfun_plus(in1,in2));
                if ~isequal(sz,expected)
                    error('unexpected output size: %s instead of %s',...
                        size_compose(sz),size_compose(expected))
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 5
            try ME=[];
                in1 = ones(1,1,2);
                in2 = ones(2,1,3);
                sz = size(bsxfun_plus(in1,in2));
                ME = struct('identifier','','message',...
                    sprintf('test should have failed (%s+%s=%s)',...
                    size_compose([],in1),size_compose([],in2),size_compose(sz)));
                ErrorFlag = true;break
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                if ismember(ME.identifier,{...
                        'MATLAB:sizeDimensionsMustMatch',...
                        'MATLAB:bsxfun:arrayDimensionsMustMatch',...
                        'Octave:nonconformant-args',...
                        'HJW:bsxfun_plus:arrayDimensionsMustMatch'})
                    % Failed as expected.
                else
                    ErrorFlag = true;break
                end
            end
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function str=size_compose(sz,array)
if nargin==2,sz = size(array);end
str = ['[' sprintf('%d ',sz)];
str(end) = ']';
end
function SelfTestFailMessage=SelfTest__error_
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__error_','error_')
ParentFunction = 'error_';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            % Test the syntax: error_(options,msg)
            try ME=[];
                filename = tempname;
                msg = 'some error message';
                options = struct('fid',fopen(filename,'w'));
                error_(options,msg)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                str = SelfTest__error_extract_message(filename);
                if ~strcmp(ME.message,msg) || ...
                        ~strcmp(str,['Error: ' msg])
                    ErrorFlag = true;break
                end
            end
            try delete(filename);catch,end % Clean up file
        case 2
            % Test the syntax: error_(options,msg,A1,...,An)
            try ME=[];
                filename = tempname;
                msg = 'important values:\nA1=''%s''\nAn=%d';
                A1 = 'char array';An = 20;
                options = struct('fid',fopen(filename,'w'));
                error_(options,msg,A1,An)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                str = SelfTest__error_extract_message(filename);
                if ~strcmp(ME.message,sprintf(msg,A1,An)) || ...
                        ~strcmp(str,sprintf(['Error: ' msg],A1,An))
                    ErrorFlag = true;break
                end
            end
            try delete(filename);catch,end % Clean up file
        case 3
            % Test the syntax: error_(options,id,msg)
            try ME=[];
                filename = tempname;
                id = 'SelfTest:ErrorID';
                msg = 'some error message';
                options = struct('fid',fopen(filename,'w'));
                error_(options,id,msg)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                str = SelfTest__error_extract_message(filename);
                if ~strcmp(ME.identifier,id) || ~strcmp(ME.message,msg) || ...
                        ~strcmp(str,['Error: ' msg])
                    ErrorFlag = true;break
                end
            end
            try delete(filename);catch,end % Clean up file
        case 4
            % Test the syntax: error_(options,id,msg,A1,...,An)
            try ME=[];
                filename = tempname;
                id = 'SelfTest:ErrorID';
                msg = 'important values:\nA1=''%s''\nAn=%d';
                A1 = 'char array';An = 20;
                options = struct('fid',fopen(filename,'w'));
                error_(options,id,msg,A1,An)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                str = SelfTest__error_extract_message(filename);
                if ~strcmp(ME.identifier,id) || ~strcmp(ME.message,sprintf(msg,A1,An)) || ...
                        ~strcmp(str,sprintf(['Error: ' msg],A1,An))
                    ErrorFlag = true;break
                end
            end
            try delete(filename);catch,end % Clean up file
        case 5
            % Test the syntax: error_(options,ME)
            try ME=[];
                filename = tempname;
                id = 'SelfTest:ErrorID';
                msg = 'some error message';
                options = struct('fid',fopen(filename,'w'));
                try M=[];error(id,msg),catch M;if isempty(M),M=lasterror;end,end %#ok<NASGU,LERR>
                error_(options,M)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                str = SelfTest__error_extract_message(filename);
                if ~strcmp(ME.identifier,id) || ~strcmp(ME.message,msg) || ...
                        ~strcmp(str,['Error: ' msg])
                    ErrorFlag = true;break
                end
            end
            try delete(filename);catch,end % Clean up file
        case 6
            % Test the write to object option.
            % Only perform graphics-based tests on runtimes where we expect them to work.
            checkpoint('SelfTest__error_','ifversion___skip_test')
            if ifversion___skip_test,continue,end
            try ME = [];
                S.h_fig = figure('Visible','off');drawnow;
                S.h_obj = text(1,1,'test','Parent',axes('Parent',S.h_fig));
                error_(struct('obj',S.h_obj),...
                    struct(...
                    'identifier','SomeFunction:ThisIsAnIdentifier',...
                    'message',['multiline' char([13 10]) 'message']));
                close(S.h_fig)
                ErrorFlag = true;break
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                close(S.h_fig)
                if ~strcmp(ME.identifier,'SomeFunction:ThisIsAnIdentifier')
                    ErrorFlag = true;break
                end
            end
        case 7
            % Test the print to function option.
            try ME = [];
                filename = [tempname '.txt'];
                fid = fopen(filename,'w');
                s_fcn = struct('h',@SelfTest__error_function_call_wrapper,...
                    'data',{{fid,'Very important error message.'}});
                error_(struct('fcn',s_fcn),...
                    struct(...
                    'identifier','SomeFunction:ThisIsAnIdentifier',...
                    'message',['multiline' char([13 10]) 'message']));
                fclose(fid);
                ErrorFlag = true;break
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(fid);
                if ~strcmp(ME.identifier,'SomeFunction:ThisIsAnIdentifier')
                    ErrorFlag = true;break
                end
            end
            % Now we can test whether the contents of the file are correct.
            try
                str=SelfTest__error_extract_message(filename);
                str(str<32) = '';
                if ~strcmp(str,['Error: This <error> was caught:multilinemessageThis message ',...
                        'was included: Very important error message.'])
                    ErrorFlag = true;break
                end
            catch
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function SelfTest__error_function_call_wrapper(error_or_warning,ME,data)
fid = data{1};
msg = data{2};
error_(struct('fid',fid),'This <%s> was caught:\n%s\nThis message was included: %s\n',...
    error_or_warning,ME.message,msg);
end
function str=SelfTest__error_extract_message(filename)
% Extract the error message from the log file.
try
    str = fileread(filename);
catch
    str = '';return
end
ind1 = min(strfind(str,']')+2); % Strip the timestamp
ind2 = max(strfind(str,'> In')-1); % Remove the function stack.
while ismember(double(str(ind2)),[10 13 32]),ind2=ind2-1;end
str = str(ind1:ind2);
end
function SelfTestFailMessage=SelfTest__findND
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__findND','findND')
ParentFunction = 'findND';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            try ME=[];
                x = findND([0 1         0        1    2    ],2,'last');
                y = findND([0 1 isequal(x,[4,5]) 1 numel(x)],2,'first');
                if ~isequal([2 3],y)
                    ErrorFlag = true;break
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 2
            try ME=[];
                checkpoint('SelfTest__findND','randi_stable_seed')
                randi_stable_seed('reset',test_number)
                for n=1:10
                    checkpoint('SelfTest__findND','randi_stable_seed')
                    dims = randi_stable_seed(4,1);
                    % Generate an array of a random size.
                    A = zeros([10*ones(1,dims) 1]);
                    % Generate a random index to mark.
                    checkpoint('SelfTest__findND','randi_stable_seed')
                    xyz = randi_stable_seed(length(A),[1,ndims(A)]);
                    xyz = num2cell(xyz);
                    A(xyz{:}) = rand;
                    % Attempt to replicate the index array with findND.
                    c = cell(size(xyz));
                    [c{:}] = findND(A);
                    if ~isequal(xyz,c),ErrorFlag = true;break,end
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 3
            try ME=[];
                checkpoint('SelfTest__findND','randi_stable_seed')
                randi_stable_seed('reset',test_number)
                for n=1:10
                    dims = randi_stable_seed(4,1);
                    % Generate an array of a random size.
                    A = zeros([10*ones(1,dims) 1]);
                    % Generate a random index to mark.
                    checkpoint('SelfTest__findND','randi_stable_seed')
                    xyz = randi_stable_seed(length(A),[1,ndims(A)]);
                    xyz_ = num2cell(xyz);
                    xyz = mat2cell(xyz,size(xyz,1),ones(1,size(xyz,2)));
                    for k=1:size(xyz_,1)
                        A(xyz_{k,:})=rand;
                    end
                    % Attempt to replicate the index array with findND.
                    c = cell(size(xyz));
                    [c{:}] = findND(A);
                    result = {size( c ),sortrows(horzcat( c {:}))};
                    expect = {size(xyz),sortrows(horzcat(xyz{:}))};
                    if ~isequal(result,expect),ErrorFlag = true;break,end
                    % Confirm equivalence with built-in for 1D/2D arrays.
                    if ndims(A)<=2
                        checkpoint('SelfTest__findND________________________line078','CoverTest')
                        for k=1:3
                            c1 = cell(1,k);
                            c2 = cell(1,k);
                            [c1{:}] = find(A);
                            [c2{:}] = findND(A);
                            if ~isequal(c1,c2),ErrorFlag = true;break,end
                        end
                        if ErrorFlag,break,end % Break out of the outer loop.
                    end
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function SelfTestFailMessage=SelfTest__PatternReplace
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__PatternReplace','PatternReplace')
ParentFunction = 'PatternReplace';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            try ME=[];
                x = {'abababa','aba','1'};
                expect = strrep(x{:});
                result = PatternReplace(x{:});
                if ~strcmp(expect,result),ErrorFlag = true;break,end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 2
            try ME=[];
                x = {'abababa','aba','123'};
                expect = strrep(x{:});
                result = PatternReplace(x{:});
                if ~strcmp(expect,result),ErrorFlag = true;break,end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 3
            try ME=[];
                expect = [1 4 5 3];
                result = PatternReplace([1 2 3],2,[4 5]);
                if ~isequal(expect,result),ErrorFlag = true;break,end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 4
            try ME=[];
                expect = int32([1 -10 3]);
                result = PatternReplace(int32([1 13 10 3]),int32([13 10]),int32(-10));
                if ~isequal(expect,result),ErrorFlag = true;break,end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function SelfTestFailMessage=SelfTest__regexp_outkeys
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__regexp_outkeys','regexp_outkeys')
ParentFunction = 'regexp_outkeys';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            % Test if all implemented output keys will return a value.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 99 ';
                [val1,val2,val3] = regexp_outkeys(str,'( )','split','match','tokens');
                if isempty(val1) || isempty(val2) || isempty(val3)
                    error('one of the implemented outkeys is empty')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 2
            % Test if adding the start and end indices as outputs does not alter the others.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 99 ';
                [a1,a2,a3,start_,end_] = regexp_outkeys(str,'( )','split','match','tokens');
                [b1,b2,b3] = regexp_outkeys(str,'( )','split','match','tokens');
                if isempty(start_) || isempty(end_) || ...
                        ~isequal(a1,b1) || ~isequal(a2,b2) || ~isequal(a3,b3)
                    error('one of the implemented outkeys is empty')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 3
            % Confirm a regex without tokens will have an empty tokens output.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 99 ';
                NoTokenMatch = regexp_outkeys(str,' ','tokens');
                expected = repmat({cell(1,0)},1,6);
                if ~isequal(NoTokenMatch,expected)
                    error('no tokens in regex did not return empty result')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 4
            % Check the split option, including trailing empty.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 99 ';
                SpaceDelimitedElements = regexp_outkeys(str,' ','split');
                expected = {'lorem1','ipsum1.2','dolor3','sit','amet','99',char(ones(0,0))};
                if ~isequal(SpaceDelimitedElements,expected)
                    error(['space delimited elements did not match expected result' char(10) ...
                        '(perhaps the trailing empty is 1x0 instead of 0x0)']) %#ok<CHARTEN>
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 5
            % Check the split option, including trailing empty.
            try ME=[];
                SpaceDelimitedElements = regexp_outkeys('',' ','split');
                expected = {char(ones(0,0))};
                if ~isequal(SpaceDelimitedElements,expected)
                    size(SpaceDelimitedElements{end}),size(expected{end}),keyboard
                    error('split on empty str did not return 0x0 empty')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 6
            % Check the extraction of a matched pattern.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 99 ';
                RawTokens = regexp_outkeys(str,'([a-z]+)[0-9]','tokens');
                words_with_number = horzcat(RawTokens{:});
                expected = {'lorem','ipsum','dolor'};
                if ~isequal(words_with_number,expected)
                    error('actual results did not match expected result')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 7
            % Check the extraction of a matched pattern.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 9x9 ';
                numbers = regexp_outkeys(str,'[0-9.]*','match');
                expected = {'1','1.2','3','9','9'};
                if ~isequal(numbers,expected)
                    error('actual results did not match expected result')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 8
            % Check the addition of start and end as tokens.
            try ME=[];
                str = 'lorem1 ipsum1.2 dolor3 sit amet 9x9 ';
                [ignore,end1,start1,end2] = regexp_outkeys(str,' .','match','end'); %#ok<ASGLU>
                [start2,end3] = regexp_outkeys(str,' .');
                expected = [7 16 23 27 32];
                if ~isequal(start1,expected) || ~isequal(start2,expected)
                    error('start indices did not match expectation')
                end
                expected = expected+1;
                if ~isequal(end1,expected) || ~isequal(end2,expected) || ~isequal(end3,expected)
                    error('end indices did not match expectation')
                end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 9
            % Check multi-element tokens.
            [t,s] = regexp_outkeys('2000/12/31','(\d\d\d\d)/(\d\d)/(\d\d)','tokens','split');
            expected1 = {{'2000','12','31'}};
            expected2 = {char(ones(0,0)),char(ones(0,0))};
            if ~isequal(t,expected1) || ~isequal(s,expected2)
                error('result did not match expectation for multiple tokens')
            end
        case 10
            % Check multi-element tokens.
            t = regexp_outkeys('12/34 56/78','(\d\d)/(\d\d)','tokens');
            expected = {{'12','34'},{'56','78'}};
            if ~isequal(t,expected)
                error('result did not match expectation for multiple tokens')
            end
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function SelfTestFailMessage=SelfTest__stringtrim
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__stringtrim','stringtrim')
ParentFunction = 'stringtrim';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME=[];
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            try ME=[];
                in = {' a  b '};
                expected = {'a b'};
                out = stringtrim(in);
                if ~isequal(out,expected),error('comparison failed'),end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 2
            try ME=[];
                in = ' a  b ';
                expected = 'a b';
                out = stringtrim(in);
                if ~isequal(out,expected),error('comparison failed'),end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 3
            try ME=[];
                in = [' a  b ';'  a b ';'_a__b '];
                expected = ['a b  ';'a b  ';'_a__b'];
                out = stringtrim(in);
                if ~isequal(out,expected),error('comparison failed'),end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 4
            try ME=[];
                in = {' a b ','  c';'d',' e  '};
                expected = {'a b','c';'d','e'};
                out = stringtrim(in);
                if ~isequal(out,expected),error('comparison failed'),end
            catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        otherwise % No more tests.
            break
    end
end
if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function SelfTestFailMessage=SelfTest__warning_
% Run a self-test to ensure the function works as intended.
% This is intended to test internal function that do not have stand-alone testers, or are included
% in many different functions as subfunction, which would make bug regression a larger issue.

checkpoint('SelfTest__warning_','warning_')
ParentFunction = 'warning_';
% This flag will be reset if an error occurs, but otherwise should ensure this test function
% immediately exits in order to minimize the impact on runtime.
if nargout==1,SelfTestFailMessage='';end
persistent SelfTestFlag,if ~isempty(SelfTestFlag),return,end
SelfTestFlag = true; % Prevent infinite recursion.

% Capture the warning state so we can reset it when this function returns.
blank = struct('msg','Blank message for testing','id','Warning:BlankWarning');
w = struct('w',warning);[w.msg,w.ID] = lastwarn;

% Ensure the backtrace is enabled.
backtrace = warning('query','backtrace');
if strcmp(backtrace.state,'off'),warning('backtrace','on'),end

test_number = 0;ErrorFlag = false;
while true,test_number=test_number+1;
    switch test_number
        case 0 % (test template)
            try ME = [];
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                ErrorFlag = true;break
            end
        case 1
            % Test the syntax: warning_(options,msg)
            lastwarn(blank.msg,blank.id);
            try ME = [];
                filename = tempname;
                msg = 'some warning message';
                options = struct('fid',fopen(filename,'w'));
                warning_(options,msg)
                fclose(options.fid);
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                ErrorFlag = true;break
            end
            str = SelfTest__warning_extract_message(filename);
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,['Warning: ' msg]) || ...
                    ~strcmp(set_msg,msg) || ~strcmp(set_ID,'')
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        case 2
            % Test the syntax: warning_(options,msg,A1,...,An)
            lastwarn(blank.msg,blank.id);
            try ME = [];
                filename = tempname;
                msg = 'important values:\nA1=''%s''\nAn=%d';
                A1='char array';An=20;
                options = struct('fid',fopen(filename,'w'));
                warning_(options,msg,A1,An)
                fclose(options.fid);
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                ErrorFlag = true;break
            end
            str = SelfTest__warning_extract_message(filename);
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,sprintf(['Warning: ' msg],A1,An)) || ...
                    ~strcmp(set_msg,sprintf(msg,A1,An)) || ~strcmp(set_ID,'')
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        case 3
            % Test the syntax: warning_(options,id,msg)
            lastwarn(blank.msg,blank.id);
            try ME = [];
                filename = tempname;
                id = 'SelfTest:WarningID';
                msg = 'some warning message';
                options = struct('fid',fopen(filename,'w'));
                warning_(options,id,msg)
                fclose(options.fid);
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                ErrorFlag = true;break
            end
            str = SelfTest__warning_extract_message(filename);
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,['Warning: ' msg]) || ...
                    ~strcmp(set_msg,msg) || ~strcmp(set_ID,id)
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        case 4
            % Test the syntax: warning_(options,id,msg,A1,...,An)
            lastwarn(blank.msg,blank.id);
            try ME = [];
                filename = tempname;
                msg = 'important values:\nA1=''%s''\nAn=%d';
                id = 'SelfTest:WarningID';
                A1 = 'char array';An = 20;
                options = struct('fid',fopen(filename,'w'));
                warning_(options,id,msg,A1,An)
                fclose(options.fid);
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                ErrorFlag = true;break
            end
            str = SelfTest__warning_extract_message(filename);
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,sprintf(['Warning: ' msg],A1,An)) || ...
                    ~strcmp(set_msg,sprintf(msg,A1,An)) || ~strcmp(set_ID,id)
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        case 5
            % Test the syntax: warning_(options,ME)
            lastwarn(blank.msg,blank.id);
            try ME = [];
                filename = tempname;
                id = 'SelfTest:ErrorID';
                msg = 'some error message';
                options = struct('fid',fopen(filename,'w'));
                try M=[];error(id,msg),catch M;if isempty(M),M=lasterror;end,end %#ok<NASGU,LERR>
                warning_(options,M)
                fclose(options.fid);
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                fclose(options.fid);
                ErrorFlag = true;break
            end
            str = SelfTest__warning_extract_message(filename);
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,['Warning: ' msg]) || ...
                    ~strcmp(set_msg,msg) || ~strcmp(set_ID,id)
                ErrorFlag = true;break
            end
            try delete(filename);catch,end % Clean up file
        case 6
            % Test the write to object option.
            lastwarn(blank.msg,blank.id);
            % Only perform graphics-based tests on runtimes where we expect them to work.
            checkpoint('SelfTest__warning_','ifversion___skip_test')
            if ifversion___skip_test,continue,end
            try ME = [];
                id = 'SelfTest:WarningID';
                msg = 'some warning message';
                S.h_fig = figure('Visible','off');drawnow;
                S.h_obj = text(1,1,'test','Parent',axes('Parent',S.h_fig));
                options = struct('obj',S.h_obj);
                warning_(options,id,msg)
                str = get(S.h_obj,'String');
                close(S.h_fig)
            catch ME;if isempty(ME),ME = lasterror;end %#ok<LERR>
                close(S.h_fig)
                ErrorFlag = true;break
            end
            [set_msg,set_ID] = lastwarn;
            if ~strcmp(str,['Warning: ' msg]) || ...
                    ~strcmp(set_msg,msg) || ~strcmp(set_ID,id)
                ErrorFlag = true;break
            end
        case 7
            % Test invalid fid.
            lastwarn(blank.msg,blank.id);
            [console_output,ErrorFlag,msg] = evalc(func2str(@SelfTest__warning_wrapper_for_evalc1));
            if ErrorFlag,break,end
            [set_msg,set_ID] = lastwarn;
            if isempty(strfind(lower(console_output),['warning: ' lower(msg)])) || ...
                    strcmp(set_msg,blank.msg) || strcmp(set_ID,blank.id) %#ok<STREMP>
                ErrorFlag = true;break
            end
        case 8
            % Test optional parameters
            lastwarn(blank.msg,blank.id);
            [console_output,ErrorFlag,msg] = evalc(func2str(@SelfTest__warning_wrapper_for_evalc2));
            if ErrorFlag,break,end
            
            % Clean up the console output so we can compare it to the message.
            ind = find(double(console_output)==8); % Find backspaces.
            if ~isempty(ind),console_output([ind ind-1]) = '';end
            console_output(ismember(double(console_output),[10 13])) = '';
            while strcmp(console_output(end),' '),console_output(end) = '';end
            
            [set_msg,set_ID] = lastwarn;
            if ~strcmpi(console_output,['warning: ' msg]) || ...
                    strcmp(set_msg,blank.msg) || strcmp(set_ID,blank.id)
                ErrorFlag = true;break
            end
        otherwise % No more tests.
            break
    end
end

% Reset warning and backtrace state.
warning(w.w);lastwarn(w.msg,w.ID);
if strcmp(backtrace.state,'off'),warning('backtrace','off'),end

if ErrorFlag
    SelfTestFlag = [];
    if isempty(ME)
        if nargout==1
            SelfTestFailMessage=sprintf('Self-validator %s failed on test %d.\n',...
                ParentFunction,test_number);
        else
            error('self-test %d failed',test_number)
        end
    else
        if nargout==1
            SelfTestFailMessage=sprintf(...
                'Self-validator %s failed on test %d.\n   ID: %s\n   msg: %s\n',...
                ParentFunction,test_number,ME.identifier,ME.message);
        else
            error('self-test %d failed\n   ID: %s\n   msg: %s',...
                test_number,ME.identifier,ME.message)
        end
    end
end
end
function [ErrorFlag,msg]=SelfTest__warning_wrapper_for_evalc1
try
    ErrorFlag = false;
    id = 'SelfTest:WarningID';
    msg = 'some warning message';
    options = struct('fid',-1);
    warning_(options,id,msg)
catch
    ErrorFlag = true;
end
end
function [ErrorFlag,msg]=SelfTest__warning_wrapper_for_evalc2
try
    ErrorFlag = false;
    id = 'SelfTest:WarningID';
    msg = 'some warning message';
    options = struct(...
        'print_to_con',true,...
        'print_to_option_WipeTraceForBuiltin',true);
    warning_(options,id,msg)
catch
    ErrorFlag = true;
end
end
function str=SelfTest__warning_extract_message(filename)
% Extract the error message from the log file.
try
    str = fileread(filename);
catch
    str = '';return
end
ind1 = min(strfind(str,']')+2); % Strip the timestamp
ind2 = max(strfind(str,'> In')-1); % Remove the function stack.
while ismember(double(str(ind2)),[10 13 32]),ind2=ind2-1;end
str = str(ind1:ind2);
end
function str=stringtrim(str)
% Extend strtrim to remove double spaces as well and implement it for old releases.
% Strings are converted to cellstr.
%
% Note that the non-breaking space (char 160) is not considered whitespace in this function.
%
% Note that results will be different between UTF-16 encoded char (MATLAB) and UTF-8 encoded char
% (GNU Octave) when padding a char matrix with spaces. If a stable output is required, convert to a
% cellstr prior to calling this function.

if ~(isa(str,'char') || isa(str,'string') || iscellstr(str)) %#ok<ISCLSTR>
    error('MATLAB:strtrim:InputClass',...
        'Input should be a string, character array, or a cell array of character arrays.')
end

% Handle string and cellstr inputs (char input needs to be converted back to char at the end).
ReturnChar = isa(str,'char');
str = cellstr(str);

% Remove the leading, trailing, and duplicative whitespace element by element.
for n=1:numel(str)
    str{n} = stringtrim_internal(str{n});
end

% Unwrap back to char if required.
if ReturnChar
    if numel(str)==1
        str = str{1};
    else
        % Pad short elements with spaces. This depends on the encoding of char (UTF-8 vs UTF-16).
        prodofsize = cellfun('prodofsize',str);
        padlength = max(prodofsize)-prodofsize;
        for k=find(padlength).'
            str{k}(end+(1:padlength(k))) = ' ';
        end
        str = vertcat(str{:});
    end
end
end
function str=stringtrim_internal(str)
persistent hasStrtrim
if isempty(hasStrtrim)
    checkpoint('stringtrim','hasFeature')
    hasStrtrim = hasFeature('strtrim');
end

% Trim leading and trailing whitespace.
if hasStrtrim
    str = strtrim(str);
else
    if numel(str)==0,return,end
    L = isspace(str);
    if L(end)
        % The last character is whitespace, so trim the end.
        idx = find(~L);
        if isempty(idx)
            % The char only contains whitespace.
            str = '';return
        end
        str((idx(end)+1):end) = '';
    end
    if isempty(str),return,end
    if L(1)
        % The first character is whitespace, so trim the start.
        idx = find(~L);
        str(1:(idx(1)-1)) = '';
    end
end

if numel(str)>1
    % Remove double whitespace inside the char vector. A leading space will have a diff of 1 (since
    % diff([false true]) returns 1). Non-trailing spaces will have a diff of 0.
    L = isspace(str);
    str([false diff(L)~=1] & L) = '';
end
end
function [isLogical,val]=test_if_scalar_logical(val)
%Test if the input is a scalar logical or convertible to it.
% The char and string test are not case sensitive.
% (use the first output to trigger an input error, use the second as the parsed input)
%
%  Allowed values:
% - true or false
% - 1 or 0
% - 'on' or 'off'
% - "on" or "off"
% - matlab.lang.OnOffSwitchState.on or matlab.lang.OnOffSwitchState.off
% - 'enable' or 'disable'
% - 'enabled' or 'disabled'
persistent states
if isempty(states)
    states = {...
        true,false;...
        1,0;...
        'true','false';...
        '1','0';...
        'on','off';...
        'enable','disable';...
        'enabled','disabled'};
    % We don't need string here, as that will be converted to char.
end

% Treat this special case.
if isa(val,'matlab.lang.OnOffSwitchState')
    isLogical = true;val = logical(val);return
end

% Convert a scalar string to char and return an error state for non-scalar strings.
if isa(val,'string')
    if numel(val)~=1,isLogical = false;return
    else            ,val = char(val);
    end
end

% Convert char/string to lower case.
if isa(val,'char'),val = lower(val);end

% Loop through all possible options.
for n=1:size(states,1)
    for m=1:2
        if isequal(val,states{n,m})
            isLogical = true;
            val = states{1,m}; % This selects either true or false.
            return
        end
    end
end

% Apparently there wasn't any match, so return the error state.
isLogical = false;
end
function tf=TestFolderWritePermission(f)
%Returns true if the folder exists and allows Matlab to write files.
% An empty input will generally test the pwd.
%
% examples:
%   fn='foo.txt';if ~TestFolderWritePermission(fileparts(fn)),error('can''t write!'),end

if ~( isempty(f) || exist(f,'dir') )
    tf = false;return
end

fn = '';
while isempty(fn) || exist(fn,'file')
    % Generate a random file name, making sure not to overwrite any existing file.
    % This will try to create a file without an extension.
    checkpoint('TestFolderWritePermission','tmpname')
    [ignore,fn] = fileparts(tmpname('write_permission_test_','.txt')); %#ok<ASGLU>
    fn = fullfile(f,fn);
end
try
    % Test write permission.
    fid = fopen(fn,'w');fprintf(fid,'test');fclose(fid);
    delete(fn);
    tf = true;
catch
    % Attempt to clean up.
    if exist(fn,'file'),try delete(fn);catch,end,end
    tf = false;
end
end
function str=tmpname(StartFilenameWith,ext)
% Inject a string in the file name part returned by the tempname function.
% This is equivalent to the line below:
% str = fullfile(tempdir,[StartFilenameWith '_' strrep(tempname,tempdir,'') ext])
if nargin<1,StartFilenameWith = '';end
if ~isempty(StartFilenameWith),StartFilenameWith = [StartFilenameWith '_'];end
if nargin<2,ext='';else,if ~strcmp(ext(1),'.'),ext = ['.' ext];end,end
str = tempname;
[p,f] = fileparts(str);
str = fullfile(p,[StartFilenameWith f ext]);
end
function varargout=var2str(varargin)
%Analogous to func2str, return the variable names as char arrays, as detected by inputname
% This returns an error for invalid inputs and if nargin~=max(1,nargout).
%
% You can use comma separated lists to create a cell array:
%   out=cell(1,2);
%   foo=1;bar=2;
%   [out{:}]=var2str(foo,bar);

% One-line alternative: function out=var2str(varargin),out=inputname(1);end
err_flag = nargin~=max(1,nargout) ;
if ~err_flag
    varargout = cell(nargin,1);
    for n=1:nargin
        try varargout{n} = inputname(n);catch,varargout{n} = '';end
        if isempty(varargout{n}),err_flag = true;break,end
    end
end
if err_flag
    error('Invalid input and/or output.')
end
end
function warning_(options,varargin)
%Print a warning to the command window, a file and/or the String property of an object
% The lastwarn state will be set if the warning isn't thrown with warning().
% The printed call trace omits this function, but the warning() call does not.
%
% Apart from controlling the way an error is written, you can also run a specific function. The
% 'fcn' field of the options must be a struct (scalar or array) with two fields: 'h' with a
% function handle, and 'data' with arbitrary data passed as third input. These functions will be
% run with 'warning' as first input. The second input is a struct with identifier, message, and
% stack as fields. This function will be run with feval (meaning the function handles can be
% replaced with inline functions or anonymous functions).
%
% The intention is to allow replacement of most warning(___) call with warning_(options,___). This
% does not apply to calls that query or set the warning state.
%
% NB: the function trace that is written to a file or object may differ from the trace displayed by
% calling the builtin error/warning functions (especially when evaluating code sections). The
% calling code will not be included in the constructed trace.
%
% There are two ways to specify the input options. The shorthand struct described below can be used
% for fast repeated calls, while the input described below allows an input that is easier to read.
% Shorthand struct:
%  options.boolean.IsValidated: if true, validation is skipped
%  options.params:              optional parameters for error_ and warning_, as explained below
%  options.boolean.con:         only relevant for warning_, ignored
%  options.fid:                 file identifier for fprintf (array input will be indexed)
%  options.boolean.fid:         if true print error to file
%  options.obj:                 handle to object with String property (array input will be indexed)
%  options.boolean.obj:         if true print error to object (options.obj)
%  options.fcn                  struct (array input will be indexed)
%  options.fcn.h:               handle of function to be run
%  options.fcn.data:            data passed as third input to function to be run (optional)
%  options.boolean.fnc:         if true the function(s) will be run
%
% Full input description:
%   print_to_con:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A logical that controls whether warnings and other output will be printed to the command
%      window. Errors can't be turned off. [default=true;]
%      Specifying print_to_fid, print_to_obj, or print_to_fcn will change the default to false,
%      unless parsing of any of the other exception redirection options results in an error.
%   print_to_fid:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The file identifier where console output will be printed. Errors and warnings will be
%      printed including the call stack. You can provide the fid for the command window (fid=1) to
%      print warnings as text. Errors will be printed to the specified file before being actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_obj:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The handle to an object with a String property, e.g. an edit field in a GUI where console
%      output will be printed. Messages with newline characters (ignoring trailing newlines) will
%      be returned as a cell array. This includes warnings and errors, which will be printed
%      without the call stack. Errors will be written to the object before the error is actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_fcn:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A struct with a function handle, anonymous function or inline function in the 'h' field and
%      optionally additional data in the 'data' field. The function should accept three inputs: a
%      char array (either 'warning' or 'error'), a struct with the message, id, and stack, and the
%      optional additional data. The function(s) will be run before the error is actually thrown.
%      [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_params:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      This struct contains the optional parameters for the error_ and warning_ functions.
%      Each field can also be specified as ['print_to_option_' parameter_name]. This can be used to
%      avoid nested struct definitions.
%      ShowTraceInMessage:
%        [default=false] Show the function trace in the message section. Unlike the normal results
%        of rethrow/warning, this will not result in clickable links.
%      WipeTraceForBuiltin:
%        [default=false] Wipe the trace so the rethrow/warning only shows the error/warning message
%        itself. Note that the wiped trace contains the calling line of code (along with the
%        function name and line number), while the generated trace does not.
%
% Syntax:
%   warning_(options,msg)
%   warning_(options,msg,A1,...,An)
%   warning_(options,id,msg)
%   warning_(options,id,msg,A1,...,An)
%   warning_(options,ME)               %rethrow error as warning
%
%examples options struct:
%  % Write to a log file:
%  opts=struct;opts.fid=fopen('log.txt','wt');
%  % Display to a status window and bypass the command window:
%  opts=struct;opts.boolean.con=false;opts.obj=uicontrol_object_handle;
%  % Write to 2 log files:
%  opts=struct;opts.fid=[fopen('log2.txt','wt') fopen('log.txt','wt')];

persistent this_fun
if isempty(this_fun),this_fun = func2str(@warning_);end

% Parse options struct, allowing an empty input to revert to default.
if isempty(options),options = struct;end
checkpoint('warning_','parse_warning_error_redirect_options')
options                    = parse_warning_error_redirect_options(  options  );
checkpoint('warning_','parse_warning_error_redirect_inputs')
[id,msg,stack,trace,no_op] = parse_warning_error_redirect_inputs( varargin{:});
forced_trace = trace;

% Don't waste time parsing the options in case of a no-op.
if no_op,return,end
% Check if the warning is turned off and exit the function if this is the case.
w = warning;if any(ismember({w(ismember({w.identifier},{id,'all'})).state},'off')),return,end

% Check whether we need to include the trace in the warning message.
backtrace = warning('query','backtrace');if strcmp(backtrace.state,'off'),trace = '';end

if options.params.ShowTraceInMessage && ~isempty(trace)
    msg = sprintf('%s\n%s',msg,trace);
end
if options.params.WipeTraceForBuiltin && strcmp(backtrace.state,'on')
    warning('off','backtrace')
end

if options.boolean.con
    % Always omit the verbosity statement ("turn this warning off with ___").
    x = warning('query','verbose');if strcmp(x.state,'on'),warning('off','verbose'),end
    if ~isempty(id),warning(id,'%s',msg),else,warning(msg), end
    % Restore verbosity setting.
    if strcmp(x.state,'on'),warning('on','verbose'),end
else
    if ~isempty(id),lastwarn(msg,id);    else,lastwarn(msg),end
end
% Reset the backtrace state as soon as possible.
if options.params.WipeTraceForBuiltin && strcmp(backtrace.state,'on')
    warning('on','backtrace')
end

if options.boolean.obj
    msg_ = msg;while msg_(end)==10,msg_(end)=[];end % Crop trailing newline.
    if any(msg_==10)  % Parse to cellstr and prepend warning.
        checkpoint('warning_','char2cellstr')
        msg_ = char2cellstr(['Warning: ' msg_]);
    else              % Only prepend warning.
        msg_ = ['Warning: ' msg_];
    end
    set(options.obj,'String',msg_)
    for OBJ=reshape(options.obj,1,[])
        try set(OBJ,'String',msg_);catch,end
    end
end

if options.boolean.fid
    T = datestr(now,31); %#ok<DATST,TNOW1> Print the time of the warning to the log as well.
    for FID=reshape(options.fid,1,[])
        try fprintf(FID,'[%s] Warning: %s\n%s',T,msg,trace);catch,end
    end
end

if options.boolean.fcn
    if ismember(this_fun,{stack.name})
        % To prevent an infinite loop, trigger an error.
        error('prevent recursion')
    end
    ME = struct('identifier',id,'message',msg,'stack',stack,'trace',forced_trace);
    for FCN=reshape(options.fcn,1,[])
        if isfield(FCN,'data')
            try feval(FCN.h,'warning',ME,FCN.data);catch,end
        else
            try feval(FCN.h,'warning',ME);catch,end
        end
    end
end
end
function [outfilename,FileCaptureInfo]=WBM(filename,url_part,varargin)
%This functions acts as an API for the Wayback Machine (web.archive.org)
%
% With this function you can download captures to the internet archive that matches a date pattern.
% If the current time matches the pattern and there is no valid capture, a capture will be
% generated. The WBM time stamps are in UTC, so a switch allows you to provide the date-time
% pattern in local time, whose upper and lower bounds will be shifted to UTC internally.
%
% This code enables you to use a specific web page in your data processing, without the need to
% check if the page has changed its structure or is not available at all.
% You can also redirect all outputs (errors only partially) to a file or a graphics object, so you
% can more easily use this function in a GUI or allow it to write to a log file.
%
% Usage instruction about the syntax of the WBM interface are derived from a Wikipedia help page:
% https://en.wikipedia.org/wiki/Help:Using_the_Wayback_Machine
% Fuzzy date matching behavior is based on https://archive.org/web/web-advancedsearch.php
%
% If the Wayback Machine is useful to you, please consider donating to them
% (https://archive.org/donate/). Based on a yearly operating cost of 35m$ and approximately 6k
% hits/s, please donate at least $1 for every 5000 requests. They don't block API access, require a
% login, or anything similar. If you abuse it, they may have to change that and you will have
% spoiled it for everyone. Please make sure your usage doesn't break this Nice Thing(tm).
% Generally, each call to this function will result in two requests. A counter will be stored in a
% file. The WBMRequestCounterFile optional input can be used to interact with the file. Run
% WBM([],[],'WBMRequestCounterFile','read') to read the current count.
% (These statistics are based on https://analytics1.archive.org/stats/wb.php#60d and the 990 IRS
% forms posted on https://projects.propublica.org/nonprofits/organizations/943242767.)
%
% Syntax:
%   outfilename = WBM(filename,url_part)
%   [outfilename,FileCaptureInfo] = WBM(filename,url_part)
%   [___] = WBM(___,Name,Value)
%   [___] = WBM(___,options)
%
% Input/output arguments:
% outfilename:
%   Full path of the output file, the variable is empty if the download failed.
% FileCaptureInfo:
%   A struct containing the information about the downloaded file. It contains the timestamp of the
%   file (in the 'timestamp' field), the flag used ('flag'), and the base URL ('url'). In short,
%   all elements needed to form the full URL of the capture.
% filename:
%   The target filename in any format that websave (or urlwrite) accepts. If this file already
%   exists, it will be overwritten in most cases.
% url_part:
%   This URL will be searched for on the WBM. The URL might be changed (e.g. ':80' is often added).
% options:
%   A struct with Name,Value parameters. Missing parameters are filled with the defaults listed
%   below. Using incomplete parameter names or incorrect capitalization is allowed, as long as
%   there is a unique match.
%   Parameters related to warning/error redirection will be parsed first.
%
% Name,Value parameters:
%   date_part:
%      A string with the date of the capture. It must be in the yyyymmddHHMMSS format, but doesn't
%      have to be complete. Note that this is represented in UTC. If incomplete, the Wayback
%      Machine will return a capture that is as close to the midpoint of the matching range as
%      possible. So for date_part='2' the range is 2000-01-01 00:00 to 2999-12-31 23:59:59, meaning
%      the WBM will attempt to return the capture closest to 2499-12-31 23:59:59. [default='2';]
%   target_date:
%      Normally, the Wayback Machine will return the capture closest to the midpoint between the
%      earliest valid date matching the date_part and the latest date matching the date_part. This
%      parameter allows setting a different target, while still allowing a broad range of results.
%      This can be used to skew the preference when loading a page. Like date_part, it must be in
%      the yyyymmddHHMMSS format, and doesn't have to be complete.
%      An example would be to provide 'date_part','2','target_date','20220630'. That way, if a
%      capture is available from 2022, that will be loaded, but any result from 2000 to 2999 is
%      allowed. If left empty, the midpoint determined by date_part will be used as the target. If
%      the target is in the future (which will be determined by parsing the target to bounds and
%      determining the midpoint), it will be cropped to the current local time minus 14 hours to
%      avoid errors in the Wayback Machine API call. [default='';]
%   UseLocalTime:
%      A scalar logical. Interpret the date_part in local time instead of UTC. This has the
%      practical effect of the upper and lower bounds of the matching date being shifted by the
%      timezone offset. [default=false;]
%   tries:
%      A 1x3 vector. The first value is the total number of times an attempt to load the page is
%      made, the second value is the number of save attempts and the last value is the number of
%      timeouts allowed. [default=[5 4 4];]
%   verbose:
%      A scalar denoting the verbosity. Level 0 will hide all errors that are caught. Level 1 will
%      enable only warnings about the internet connection being down. Level 2 includes errors NOT
%      matching the usual pattern as well and level 3 includes all other errors that get rethrown
%      as warning. Level 4 adds a warning on retrying to retrieve the timestamp (this will always
%      happen for pages without a capture, and may happen every now and then for no apparent
%      reason).[default=3;]
%      Octave uses libcurl, making error catching is bit more difficult. This will result in more
%      HTML errors being rethrown as warnings under Octave than Matlab. There is no check in place
%      to restrict this to level 0-4 (even inf is allowed), so you can anticipate on higher levels
%      in future versions of this function.
%   if_UTC_failed:
%      This is a char array with the intended behavior for when this function is unable to
%      determine the UTC. The options are 'error', 'warn_0', 'warn_1', 'warn_2', 'warn_3', and
%      'ignore'. For the options starting with warn_, a warning will be triggered if the 'verbose'
%      parameter is set to this level or higher (so 'warn_0' will trigger a warning if 'verbose' is
%      set to 0).
%      If this parameter is not set to 'error', the valid time range is expanded by -12 and +14
%      hours to account for all possible time zones, and the midpoint is shifted accordingly.
%      [default='warn_3']
%   m_date_r:
%      A string describing the response to the date missing in the downloaded web page. Usually,
%      either the top bar will be present (which contains links), or the page itself will contain
%      links, so this situation may indicate a problem with the save to the WBM. Allowed values are
%      'ignore', 'warning' and 'error'. Be aware that non-page content (such as images) will set
%      off this response. Flags other than the default will also set off this response.
%      [default='warning';] if flags is not default then [default='ignore']
%   response:
%      The response variable is a cell array, where each row encodes one sequence of HMTL errors
%      and the appropriate next action. The syntax of each row is as follows:
%      #1 If there is a sequence of failure that fit the first cell,
%      #2 and the HTML error codes of the sequence are equal to the second cell,
%      #3 then respond as per the third cell.
%      The sequence of failures are encoded like this:
%      t1: failed attempt to load, t2: failed attempt to save, tx: either failed to load, or failed
%      to save.
%      The error code list must be HTML status codes. The Matlab timeout error is encoded with 4080
%      (analogous to the HTTP 408 timeout error code). The  error is extracted from the identifier,
%      which is not always possible, especially in the case of Octave.
%      The response in the third cell is either 'load', 'save', 'exit', or 'pause_retry'.
%      Load and save set the preferred type. If a response is not allowed (i.e. if the
%      corresponding element of 'tries' is 0), the other response (save or load) is tried, until
%      sum(tries(1:2))==0. If the response is set to exit, or there is still no successful download
%      after tries has been exhausted, the output file will be deleted and the function will exit.
%      The pause_retry is intended for use with an error 429. See the err429 parameter for more
%      options. [default={'tx',404,'load';'txtx',[404 404],'save';'tx',403,'save';
%      't2t2',[403 403],'exit';'tx',429,'pause_retry';'t2t2t2',[429 429 429],'exit'};]
%   err429:
%      Sometimes the webserver will return a 429 status code. This should trigger a waiting period
%      of a few seconds. If this status code is return 3 times for a save, that probably means the
%      number of saves is exceeded. Disable saves when retrying within 24 hours, as they will keep
%      leading to this error code.
%      This parameter controls the behavior of this function in case of a 429 status code. It is a
%      struct with the following fields:
%      The CountsAsTry field (logical) describes if the attempt should decrease the tries counter.
%      The TimeToWait field (double) contains the time in seconds to wait before retrying.
%      The PrintAtVerbosityLevel field (double) contains the verbosity level at which a text should
%      be printed, showing the user the function did not freeze.
%      Missing fields are replaced by the default, the same way the other optional parameters are
%      parsed.
%      [default=struct('CountsAsTry',false,'TimeToWait',15,'PrintAtVerbosityLevel',3);]
%   ignore:
%      The ignore variable is vector with the same type of error codes as in the response variable.
%      Ignored errors will only be ignored for the purposes of the response, they will not prevent
%      the tries vector from decreasing. [default=4080;]
%   flag:
%      The flags can be used to specify an explicit version of the archived page. The options are
%      '', '*', 'id' (identical), 'js' (Javascript), 'cs' (CSS), 'im' (image), or 'fw'/'if'
%      (iFrame). An empty flag will only expand the date. Providing '*' used to explicitly expand
%      the date and only show the calendar view when using a browser, but it seems to now also load
%      the calendar with websave/urlwrite. With the 'id' flag the page is show as captured (i.e.
%      without the WBM banner, making it ideal for e.g. exe files). With the 'id' and '*' flags the
%      date check will fail, so the missing date response (m_date_r) will be invoked. For the 'im'
%      flag you can circumvent this by first loading in the normal mode (''), and then extracting
%      the image link from that page. That way you can enforce a date pattern and still get the
%      image. You can also use the target_date option. The Wikipedia page suggest that a flag
%      syntax requires a full date, but this seems not to be the case, as the date can still
%      auto-expand. [default='';]
%   waittime:
%      This value controls the maximum time that is spent waiting on the internet connection for
%      each call of this function. This does not include the time waiting as a result of a 429
%      error. The input must be convertible to a scalar double. This is the time in seconds.
%      NB: Setting this to inf will cause an infite loop if the internet connection is lost.
%      [default=60]
%   timeout:
%      This value is the allowed timeout in seconds. It is ignored if it isn't supported. The input
%      must be convertible to a scalar double. [default=10;]
%   WBMRequestCounterFile:
%      This must be empty, or a char containing 'read' or 'reset'. If it is provided, all other
%      inputs are ignored, except the exception redirection. That means
%      count=WBM([],[],'WBMRequestCounterFile','read'); is a valid call. For the 'read' input, the
%      output will contain the number of requests posted to the Wayback Machine. This counter is
%      intended to cover all releases of Matlab and GNU Octave. Using the 'reset' switch will reset
%      the counter back to 0. [default='';]
%   print_to_con:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A logical that controls whether warnings and other output will be printed to the command
%      window. Errors can't be turned off. [default=true;]
%      Specifying print_to_fid, print_to_obj, or print_to_fcn will change the default to false,
%      unless parsing of any of the other exception redirection options results in an error.
%   print_to_fid:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The file identifier where console output will be printed. Errors and warnings will be
%      printed including the call stack. You can provide the fid for the command window (fid=1) to
%      print warnings as text. Errors will be printed to the specified file before being actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_obj:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      The handle to an object with a String property, e.g. an edit field in a GUI where console
%      output will be printed. Messages with newline characters (ignoring trailing newlines) will
%      be returned as a cell array. This includes warnings and errors, which will be printed
%      without the call stack. Errors will be written to the object before the error is actually
%      thrown. [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_fcn:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      A struct with a function handle, anonymous function or inline function in the 'h' field and
%      optionally additional data in the 'data' field. The function should accept three inputs: a
%      char array (either 'warning' or 'error'), a struct with the message, id, and stack, and the
%      optional additional data. The function(s) will be run before the error is actually thrown.
%      [default=[];]
%      If print_to_fid, print_to_obj, and print_to_fcn are all empty, this will have the effect of
%      suppressing every output except errors.
%      Array inputs are allowed.
%   print_to_params:
%      NB: An attempt is made to use this parameter for warnings or errors during input parsing.
%      This struct contains the optional parameters for the error_ and warning_ functions.
%      Each field can also be specified as ['print_to_option_' parameter_name]. This can be used to
%      avoid nested struct definitions.
%      ShowTraceInMessage:
%        [default=false] Show the function trace in the message section. Unlike the normal results
%        of rethrow/warning, this will not result in clickable links.
%      WipeTraceForBuiltin:
%        [default=false] Wipe the trace so the rethrow/warning only shows the error/warning message
%        itself. Note that the wiped trace contains the calling line of code (along with the
%        function name and line number), while the generated trace does not.
%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%|                                                                         |%
%|  Version: 4.1.0                                                         |%
%|  Date:    2024-04-10                                                    |%
%|  Author:  H.J. Wisselink                                                |%
%|  Licence: CC by-nc-sa 4.0 ( creativecommons.org/licenses/by-nc-sa/4.0 ) |%
%|  Email = 'h_j_wisselink*alumnus_utwente_nl';                            |%
%|  Real_email = regexprep(Email,{'*','_'},{'@','.'})                      |%
%|                                                                         |%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%
% Tested on several versions of Matlab (ML 6.5 and onward) and Octave (4.4.1 and onward), and on
% multiple operating systems (Windows/Ubuntu/MacOS). You can see the full test matrix below.
% Compatibility considerations:
% - HTML error codes are harder to catch on Octave. Depending on the selected verbosity level that
%   means the number of warnings will be larger.
% - The duration of a timeout can only be set with websave. This means that for larger files or
%   less stable internet connections, a timeout error will be more likely when using older releases
%   or Octave.

if nargin==0 && nargout==0
    % Use func2str to make robust to minify.
    fprintf('Call help(''%s'') for the documentation.\n',func2str(@WBM))
    fprintf([...
        'Number of requests to archive.org logged by this function: %d.\n',...
        'Consider donating $1 for every 5000 requests.\n'],...
        WBM([],[],'WBMRequestCounterFile','read'))
    return
end

if nargin<2
    error('HJW:WBM:nargin','Incorrect number of input argument.')
end
if ~(nargout==0 || nargout==1) %might trigger 'MATLAB:TooManyOutputs' instead
    error('HJW:WBM:nargout','Incorrect number of output argument.')
end
checkpoint('WBM','WBM_parse_inputs')
[success,opts,ME] = WBM_parse_inputs(filename,url_part,varargin{:});
if ~success
    % If the parsing of print_to failed (which is tried first), the default will be used.
    checkpoint('WBM','error_')
    error_(opts.print_to,ME)
end
if nargout>1,FileCaptureInfo=struct;end % Pre-allocate the output variable.
[        tries,     verbose,     UseURLwrite,     err429,     print_to] = ...
    deal(...
    opts.tries,opts.verbose,opts.UseURLwrite,opts.err429,opts.print_to);
SavesAllowed = tries(2)>0;
% Cap the time we wait for an internet connection to avoid infinite loops (time is in seconds).
waittime = struct('cap',opts.waittime,'total',0);

if ~isempty(opts.RequestCounter.interaction)
    switch opts.RequestCounter.interaction
        case 'read'
            outfilename = str2double(fileread(opts.RequestCounter.fn));
        case 'reset'
            fid = fopen(opts.RequestCounter.fn,'w');
            fprintf(fid,'%d',0);
            fclose(fid);
        case 'filename'
            % Allow 'filename' as undocumented feature.
            outfilename = opts.RequestCounter.fn;
    end
    return
end

checkpoint('WBM','TestFolderWritePermission')
if ~TestFolderWritePermission(fileparts(filename))
    error_(print_to,'HJW:WBM:NoWriteFolder',...
        'The target folder doesn''t exist or Matlab doesn''t have write permission for it.')
end
checkpoint('WBM','WBM_UTC_test')
if ~WBM_UTC_test % No UTC determination is available.
    if strcmp(opts.UTC_fail_response,'error')
        error_(print_to,'HJW:WBM:UTC_missing_error','Retrieval of UTC failed.')
    elseif strcmp(opts.UTC_fail_response,'warn')
        warning_(print_to,'HJW:WBM:UTC_missing_warning',...
            'Retrieval of UTC failed, continuing with wider date/time range.')
    end
end

% Order responses based on pattern length to match. There is no need to do this in the parser,
% since this is fast anyway, and response_lengths is needed in the loop below as well.
response_lengths = cellfun('length',opts.response(:,2));
[response_lengths,order] = sort(response_lengths);
order = order(end:-1:1); % sort(__,'descend'); is not supported in ML6.5
response = opts.response(order,:);
response_lengths = response_lengths(end:-1:1);

% Generate the weboptions only once.
if ~UseURLwrite,webopts = weboptions('Timeout',opts.timeout);end

prefer_type = 1;                % Prefer loading.
success = false;                % Start loop.
response_list_vector = [];      % Initialize response list
type_list = [];                 % Initialize type list
connection_down_wait_factor = 0;% Initialize
while ~success && ...           %no successful download yet?
        sum(tries(1:2))>0 ...   %any save or load tries left?
        && tries(3)>=0          %timeout limit reached?
    if tries(prefer_type)<=0 % No tries left for the preferred type.
        prefer_type = 3-prefer_type; % Switch 1 to 2 and 2 to 1.
    end
    type = prefer_type;
    try ME = []; %#ok<NASGU>
        if type==1 % Load.
            SaveAttempt = false;
            tries(type) = tries(type)-1;
            
            [status,waittime,t] = confirm_capture_is_available(url_part,waittime,opts);
            if status<200 || status>=300
                % No capture is available for this URL. Report this to the user (if the verbosity
                % is set high enough). Then return to the start of the loop to try saving (if there
                % are save attempts left).
                if verbose>=3
                    txt = sprintf('No capture found for this URL. (download of %s)',filename);
                    if print_to.boolean.con
                        fprintf('%s\n',txt)
                    end
                    if print_to.boolean.fid
                        for FID=print_to.fid(:).',fprintf(FID,'%s\n',txt);end
                    end
                    if print_to.boolean.obj
                        set(print_to.obj,'String',txt)
                    end
                    drawnow
                end
                % Try saving or quit.
                prefer_type = 2;
                if tries(2)>0,continue
                else         ,break
                end
            end
            
            % If the execution reaches this point, there is a capture available. To avoid redirects
            % messing this up, we should use the timestamp returned by the API.
            IncrementRequestCounter(opts)
            if UseURLwrite
                outfilename = urlwrite(...
                    ['http://web.archive.org/web/' t opts.flag '_/' url_part],...
                    filename); %#ok<URLWR>
                checkpoint('WBM','check_filename')
                outfilename = check_filename(filename,outfilename);
                checkpoint('WBM_____________________________________line323','CoverTest')
            else
                outfilename = WebsaveInternal(filename,...
                    ['https://web.archive.org/web/' t opts.flag '_/' url_part],...
                    webopts,verbose,print_to);
                checkpoint('WBM_____________________________________line328','CoverTest')
            end
        elseif type==2 % Save.
            SaveAttempt = true;
            tries(type) = tries(type)-1;
            IncrementRequestCounter(opts)
            if UseURLwrite
                outfilename = urlwrite(...
                    ['http://web.archive.org/save/' url_part],...
                    filename); %#ok<URLWR>
                checkpoint('WBM','check_filename')
                outfilename = check_filename(filename,outfilename);
            else
                outfilename = WebsaveInternal(filename,...
                    ['https://web.archive.org/save/' url_part],...
                    webopts,verbose,print_to);
            end
        end
        success = true;connection_down_wait_factor = 0;
        checkpoint('WBM','check_date')
        if SavesAllowed && ~check_date(outfilename,opts,SaveAttempt)
            % Incorrect date or live page loaded, so try saving.
            success = false;prefer_type = 2;
        end
    catch ME;if isempty(ME),ME = lasterror;end%#ok<LERR>
        success = false;
        checkpoint('WBM','isnetavl')
        if debug_hook(false) || ~isnetavl
            % If the connection is down, retry in intervals
            while debug_hook(false) || ~isnetavl
                if waittime.total>waittime.cap
                    % Total wait time exceeded, return the error condition.
                    if verbose>=1
                        checkpoint('WBM','warning_')
                        warning_(print_to,'Maximum waiting time for internet connection exceeded.')
                    end
                    tries = zeros(size(tries));continue
                end
                curr_time = datestr(now,'HH:MM:SS'); %#ok<TNOW1,DATST>
                if verbose>=1
                    checkpoint('WBM','warning_')
                    warning_(print_to,'Internet connection down, retrying in %d seconds (@%s).',...
                        2^connection_down_wait_factor,curr_time)
                end
                pause(2^connection_down_wait_factor)
                waittime.total = waittime.total+2^connection_down_wait_factor;
                % Increment, but cap to a reasonable interval.
                connection_down_wait_factor = min(1+connection_down_wait_factor,6);
            end
            % Skip the rest of the error processing and retry without reducing points.
            continue
        end
        connection_down_wait_factor = 0;
        ME_id = ME.identifier;
        ME_id = strrep(ME_id,':urlwrite:',':webservices:');
        if strcmp(ME_id,'MATLAB:webservices:Timeout')
            code = 4080;
            tries(3) = tries(3)-1;
        else
            % Equivalent to raw_code=textscan(ME_id,'MATLAB:webservices:HTTP%dStatusCodeError');
            raw_code = strrep(ME_id,'MATLAB:webservices:HTTP','');
            raw_code = strrep(raw_code,'StatusCodeError','');
            raw_code = str2double(raw_code);
            if isnan(raw_code)
                % Some other error occurred, set a code and throw a warning. As Octave does not
                % report an HTML error code, this will happen almost every error. To reduce command
                % window clutter, consider lowering the verbosity level.
                code = -1;
                if verbose>=2
                    checkpoint('WBM','warning_')
                    warning_(print_to,ME)
                end
            else
                % Octave doesn't really returns a identifier for urlwrite, nor do very old releases
                % of Matlab.
                switch ME.message
                    case 'urlwrite: Couldn''t resolve host name'
                        code = 404;
                    case ['urlwrite: Peer certificate cannot be ',...
                            'authenticated with given CA certificates']
                        % It's not really a 403, but the result in this context is similar.
                        code = 403;
                    otherwise
                        code = raw_code;
                end
            end
        end
        
        if verbose>=3
            txt = sprintf('Error %d tries(%d,%d,%d) (download of %s).',...
                double(code),tries(1),tries(2),tries(3),filename);
            if print_to.boolean.con
                fprintf('%s\n',txt)
            end
            if print_to.boolean.fid
                for FID=print_to.fid(:).',fprintf(FID,'%s\n',txt);end
            end
            if print_to.boolean.obj
                set(print_to.obj,'String',txt)
            end
            drawnow
        end
        if ~any(code==opts.ignore)
            response_list_vector(end+1) = code; %#ok<AGROW>
            type_list(end+1) = type; %#ok<AGROW>
            for n_response_pattern=1:size(response,1)
                if length(response_list_vector) < response_lengths(n_response_pattern)
                    % Not enough failed attempts (yet) to match against the current pattern.
                    continue
                end
                last_part_of_response_list = response_list_vector(...
                    (end-response_lengths(n_response_pattern)+1):end);
                last_part_of_type_list = type_list(...
                    (end-response_lengths(n_response_pattern)+1):end);
                
                % Compare the last types to the type patterns.
                temp_type_pattern = response{n_response_pattern,1}(2:2:end);
                temp_type_pattern = strrep(temp_type_pattern,'x',num2str(type));
                type_fits = strcmp(temp_type_pattern,sprintf('%d',last_part_of_type_list));
                if isequal(...
                        response{n_response_pattern,2},...
                        last_part_of_response_list)...
                        && type_fits
                    % If the last part of the response list matches with the response pattern in
                    % the current element of 'response', set prefer_type to 1 for load, and to 2
                    % for save.
                    switch response{n_response_pattern,3}
                        % The otherwise will not occur: that should be caught in the input parser.
                        case 'load'
                            prefer_type = 1;
                        case 'save'
                            prefer_type = 2;
                        case 'exit'
                            % Cause a break in the while loop.
                            tries = [0 0 -1];
                        case 'pause_retry'
                            if ~err429.CountsAsTry
                                % Increment the counter, which has the effect of not counting this
                                % as a try.
                                tries(prefer_type) = tries(prefer_type)+1;
                            end
                            if verbose>=err429.PrintAtVerbosityLevel
                                N = 10;
                                s = 'Waiting a while until the server won''t block us anymore';
                                if print_to.boolean.con
                                    fprintf(s);drawnow
                                end
                                if print_to.boolean.fid
                                    for FID=print_to.fid(:).',fprintf(FID,s);end,drawnow
                                end
                                for n=1:N
                                    pause(err429.TimeToWait/N)
                                    if print_to.boolean.con
                                        fprintf('.');drawnow
                                    end
                                    if print_to.boolean.fid
                                        for FID=print_to.fid(:).',fprintf(FID,'.');end,drawnow
                                    end
                                    if print_to.boolean.obj
                                        s = [s '.']; %#ok<AGROW>
                                        set(print_to.obj,s);drawnow
                                    end
                                end
                                if print_to.boolean.con
                                    fprintf('\nContinuing\n');drawnow
                                end
                                if print_to.boolean.fid
                                    for FID=print_to.fid(:).',fprintf(FID,'\nContinuing\n');end
                                    drawnow
                                end
                                if print_to.boolean.obj
                                    set(print_to.obj,'Continuing');drawnow
                                end
                            else
                                pause(err429.TimeToWait)
                            end
                    end
                    break
                end
            end
        end
    end
end

checkpoint('WBM','check_date')
if ~success || ( ~SavesAllowed && ~check_date(outfilename,opts,SaveAttempt) )
    % If saving isn't allowed and the date doesn't match the date_part, or no successful download
    % was reached within the allowed tries, delete the output file (as it will be either the
    % incorrect date, or 0 bytes).
    if exist(filename,'file'),try delete(filename);catch,end,end
    outfilename = [];
end
filename2 = [filename '.html'];
if exist(filename2,'file')
    a=dir(filename2);
    if numel(a)==1 && a.bytes==0 && abs(datenum(a.date)-now)<=(1/24) %#ok<ISCL,TNOW1,DATNM>
        % Apparently the file is newly created.
        try delete(filename2);catch,end % Assume a 0 byte is never correct (although it might be).
    end
end
if nargout==0
    checkpoint('WBM','var2str')
    clear(var2str(outfilename));
elseif nargout>1
    FileCaptureInfo = struct('timestamp',t,'flag',opts.flag,'url',url_part);
end
end
function outfilename=WebsaveInternal(filename,url,options,verbose,print_to)
% Catch any warnings triggered by websave.
% The best way to do this is with the undocumented warning('error',warnID), but evalc should also
% do the trick in this case.
checkpoint('WBM','var2str')
[str,outfilename] = evalc([...
    func2str(@websave) '(' var2str(filename) ',' var2str(url) ',' var2str(options) ')']);
if isempty(str),return,end
if verbose>=2
    % Warnings are allowed.
    checkpoint('WBM','warning_')
    warning_(print_to,str)
end
end
function [status,waittime,t]=confirm_capture_is_available(url,waittime,opts)
% Retrieve the time stamp closest to the requested date and compare it to date_part.
IncrementRequestCounter(opts)
checkpoint('WBM','WBM_retrieve_timestamp')
[t,status,waittime] = WBM_retrieve_timestamp(url,opts,waittime);
if isempty(t)
    % Sometimes this will just fail for some reason. We should probably retry only once to avoid an
    % unnecessary save. See WBM_retrieve_timestamp for the conditions under which this might occur.
    if opts.verbose>3 %Print a warning to alert the user.
        checkpoint('WBM','warning_')
        msg = sprintf('Retrying to retrieve the timestamp for %s',url);
        warning_(opts.print_to,'HJW:WBM:RetryTimestamp',msg)
    end
    IncrementRequestCounter(opts)
    checkpoint('WBM','WBM_retrieve_timestamp')
    [t,status,waittime] = WBM_retrieve_timestamp(url,opts,waittime);
end
if status<200 || status>=300
    % There might be a timestamp available, but since the status is not 2xx urlwrite and websave
    % will probably error anyway.
    return
end
date_as_double = str2double(t);
if opts.date_bounds.double(1)>date_as_double || date_as_double>opts.date_bounds.double(2)
    % As a capture with an appropriate timestamp could not be found, a 404 status code seems
    % appropriate. This should normally trigger a save.
    status = 404;
    return
end
end
function IncrementRequestCounter(opts)
% Keep track of the number of calls to the WBM in a file. This file is intended to be shared across
% as many releases of Matlab/Octave.
return % Skip this function in the tester, as that doesn't actually call archive.org.
fn = opts.RequestCounter.fn;
old_file_contents = fileread(fn);
counter = 1+str2double(old_file_contents);
if ~isfinite(counter)
    checkpoint('WBM','error_')
    error_(opts.print_to,'HJW:WBM:CounterIncrementFailed',...
        ['The counter file seems to be corrupted. Please reset.\n',...
        '    current file contents:\n',...
        '%s\n'],old_file_contents)
end
fid = fopen(fn,'w');
fprintf(fid,'%d',counter);
fclose(fid);
end
function atomTime=WBM_getUTC_local
persistent pref_order % Some checks take a relatively long time, so store this in a persistent.
if isempty(pref_order)
    checkpoint('WBM_getUTC_local','CheckMexCompilerExistence')
    tf = CheckMexCompilerExistence;
    checkpoint('WBM_getUTC_local','GetWritableFolder')
    [ignore,status] = GetWritableFolder('ErrorOnNotFound',false); %#ok<ASGLU>
    if status==0,status=inf;end
    if tf && status<3
        % There is a compiler, and there is a writable folder other than the pwd, so the c
        % implementation should be tried before the web implementation.
        % Since the c implementation is probably faster than the OS call, try that first.
        pref_order = [1 3 2];
    else
        % Either a compiler is missing, or only the pwd is writable. Only use c if web fails.
        pref_order = [3 2 1];
    end
end
for n=1:numel(pref_order)
    checkpoint('WBM_getUTC_local','getUTC')
    atomTime = max([0 getUTC(pref_order(n))]); % Ensure it is 0 if getUTC fails
    if atomTime~=0,break,end
end
end
function [bounds,midpoint]=WBM_parse_date_to_range(date_part)
% Match the partial date to the range of allowed dates.
% This throws an error if the date_part doesn't fit a valid date pattern.

date = generate_date_bound(date_part,'0');
lower_bound = num2cell(date);
lower_bound = datenum(lower_bound{:}); %#ok<DATNM>

% Confirm this fits the date pattern provided.
test    = datestr(lower_bound,'yyyymmddTHHMMSS'); %#ok<DATST>
test(9) = '';
if ~strcmp(test(1:numel(date_part)),date_part)
    error('incorrect date_part format')
end

upper_bound = generate_date_bound(date_part,'9');
d = [31 28 31 30 31 30 31 31 30 31 30 31];
y = upper_bound(1);if rem(y,4)==0 && (rem(y,100)~=0 || rem(y,400)==0),d(2) = 29;end
d = d(min(12,upper_bound(2))); % Handle October-December as a single digit; would overflow to '19'.
overflow = find(upper_bound>[inf 12 d 23 59 59])+1;
if ~isempty(overflow),upper_bound(min(overflow):end) = inf;end
upper_bound = min(upper_bound,[inf 12 d 23 59 59]);
upper_bound = num2cell(upper_bound);
upper_bound = datenum(upper_bound{:}); %#ok<DATNM>

% Confirm this fits the date pattern provided.
test    = datestr(upper_bound,'yyyymmddTHHMMSS'); %#ok<DATST>
test(9) = '';
if ~strcmp(test(1:numel(date_part)),date_part)
    error('incorrect date_part format')
end

% If the UTC time can't be determined, the valid time should be expanded by -12 and +14 hours.
% If an error or warning should be thrown, this will happen in the main function.
checkpoint('WBM_parse_date_to_range','WBM_UTC_test')
if ~WBM_UTC_test % Expand by -12 and +14 hours.
    lower_bound = lower_bound+datenum(0,0,0,-12,0,0); %#ok<DATNM>
    upper_bound = upper_bound+datenum(0,0,0,+14,0,0); %#ok<DATNM>
end

midpoint    = (lower_bound+upper_bound)/2+5/360000; % Add half a second to round .499 up.
midpoint    = datestr(midpoint,'yyyymmddTHHMMSS'); %#ok<DATST>
midpoint(9) = '';
bounds = [lower_bound upper_bound];
end

function date = generate_date_bound(date_part,pad_val)
date = char(zeros(1,14)+pad_val);
date(1:numel(date_part)) = date_part;
date = {...
    date(1:4 ),date( 5:6 ),date( 7:8 ),... % date
    date(9:10),date(11:12),date(13:14)};   % time
date = str2double(date);date(1:3) = max(date(1:3),1);
end
function [success,opts,ME]=WBM_parse_inputs(filename,url,varargin)
% The print_to variable will be parsed first. If the parsing of print_to fails, an empty double
% will be returned.

[default,print_to_fieldnames] = WBM_parse_inputs_defaults;
% Attempt to match the inputs to the available options. This will return a struct with the same
% fields as the default option struct. If anything fails, an attempt will be made to parse the
% exception redirection options anyway.
checkpoint('WBM_parse_inputs','parse_varargin_robust')
[success,opts,ME,ReturnFlag,replaced] = parse_varargin_robust(default,varargin{:});
if ReturnFlag,return,end

% Add the required inputs to the struct.
opts.filename = filename;opts.url=url;

[opts,ME] = ParseRequestCounterInteraction(opts,replaced);
if ~isempty(ME.message),return,end
if ~isempty(opts.RequestCounter.interaction)
    success = true;return
end

% Test the required inputs.
checkpoint('WBM_parse_inputs','filename_is_valid')
[valid,opts.filename] = filename_is_valid(opts.filename);
if valid
    fullpath = fileparts(opts.filename);
    if ~isempty(fullpath) && ~exist(fullpath,'dir')
        valid = false;
    end
end
if ~valid
    ME.message = 'The first input (filename) is not char and/or empty or the folder does not exist.';
    ME.identifier = 'HJW:WBM:incorrect_input_filename';
    checkpoint('WBM_parse_inputs________________________line034','CoverTest')
    return
end
if ~ischar(opts.url) || numel(opts.url)==0
    ME.message = 'The second input (url) is not char and/or empty.';
    ME.identifier = 'HJW:WBM:incorrect_input_url';
    checkpoint('WBM_parse_inputs________________________line040','CoverTest')
    return
end
if ~any(opts.url==':') || ~any(opts.url=='/')
    % A slash is not technically required for a valid URL, but without one, the chance that this is
    % a valid URL is much lower than the chance this is a user error.
    ME.message = 'The URL is highly unlikely to be valid.';
    ME.identifier = 'HJW:WBM:invalid_url';
    checkpoint('WBM_parse_inputs________________________line048','CoverTest')
    return
end

if numel(replaced)==0,success = true;ME = [];return,end % No default values were changed.

% Sort to make sure date_part is parsed before target_date.
replaced = sort(replaced);

% Check optional inputs
default = WBM_parse_inputs_defaults;
for k=1:numel(replaced)
    item = opts.(replaced{k});
    switch replaced{k}
        case print_to_fieldnames
            % Already checked.
        case 'date_part'
            valid_date = true;
            if isa(item,'string') && numel(item)==1,item=char(item);end
            if  ~ischar(item) || numel(item)==0 || numel(item)>14 || any(item<48 & item>57)
                valid_date = false;
            end
            % Parse the date to bounds.
            checkpoint('WBM_parse_inputs','WBM_parse_date_to_range')
            try [bounds,midpoint] = WBM_parse_date_to_range(item);catch,valid_date=false;end
            if ~valid_date
                ME.message = 'The value of options.date_part is empty or not a valid numeric char.';
                return
            end
            opts.date_part = midpoint; % May be overwritten by target_date.
            opts.date_bounds.datenum = bounds;
            checkpoint('WBM_parse_inputs________________________line081','CoverTest')
        case 'target_date'
            if isa(item,'string') && numel(item)==1,item=char(item);end
            if isempty(item)
                % Since this will use the midpoint determined by date_part, there is no point in
                % repeating the parsing.
                continue
            end
            valid_date = true;
            if  ~ischar(item) || numel(item)==0 || numel(item)>14 || any(item<48 & item>57)
                valid_date = false;
            end
            
            % Parse the date to a midpoint and convert it to a datenum.
            checkpoint('WBM_parse_inputs','WBM_parse_date_to_range')
            try [bounds,midpoint] = WBM_parse_date_to_range(item);catch,valid_date=false;end
            midpoint = mat2cell(midpoint,1,[4 2 2   2 2 2]);
            midpoint = num2cell(str2double(midpoint));
            midpoint = datenum(midpoint{:}); %#ok<DATNM>
            
            % If the lower bound is in the future, set local_time-14h as the midpoint.
            if midpoint>now %#ok<TNOW1>
                item = datestr(now-14/24,30);item(9)=''; %#ok<TNOW1,DATST>
            end
            
            % Ensure the new midpoint is within the bounds specified by date_part.
            if midpoint<opts.date_bounds.datenum(1) || midpoint>opts.date_bounds.datenum(2)
                valid_date = false;
            end
            
            if ~valid_date
                ME.message=['The value of options.target_date is not a valid numeric char,',...
                    char(10) 'or is not compatible with the specified date_part.']; %#ok<CHARTEN>
                return
            end
            opts.date_part = item; % Overwrite with new midpoint.
            checkpoint('WBM_parse_inputs________________________line117','CoverTest')
        case 'tries'
            if ~isnumeric(item) || numel(item)~=3 || any(isnan(item))
                ME.message = ['The value of options.tries has an incorrect format.',char(10),...
                    'The value should be a numeric vector with 3 integer elements.'];%#ok<CHARTEN>
                return
            end
            checkpoint('WBM_parse_inputs________________________line124','CoverTest')
        case 'response'
            checkpoint('WBM_parse_inputs','WBM_parse_inputs__validate_response_format')
            if WBM_parse_inputs__validate_response_format(item)
                ME.message = 'The value of options.response has an incorrect format.';
                return
            end
        case 'ignore'
            if ~isnumeric(item) || numel(item)==0 || any(isnan(item))
                ME.message = ['The value of options.ignore has an incorrect format.',char(10),...
                    'The value should be a numeric vector with HTML error codes.'];%#ok<CHARTEN>
                return
            end
        case 'verbose'
            if ~isnumeric(item) || numel(item)~=1 || double(item)~=round(double(item))
                % The integer test could cause unexpected behavior due to float rounding, but in
                % fact an error is preferred here.
                ME.message = 'The value of options.verbose is not an integer scalar.';
                return
            end
        case 'm_date_r'
            if (iscellstr(item)||isa(item,'string')) && numel(item)==1 %#ok<ISCLSTR>
                item = char(item); % Unwrap a scalar string/cellstr.
            end
            AllowedChoices = {'ignore','warning','error'};
            checkpoint('WBM_parse_inputs','parse_NameValue_option')
            item=-1+find(ismember(AllowedChoices,parse_NameValue_option(AllowedChoices,item)));
            if numel(item)==0
                ME.message = 'Options.m_date_r should be ''ignore'', ''warning'', or ''error''.';
                return
            end
            opts.m_date_r = item;
            checkpoint('WBM_parse_inputs________________________line156','CoverTest')
        case 'flag'
            if isa(item,'string') && numel(item)==1,item=char(item);end
            EmptyChar = ischar(item)&&numel(item)==0;
            if EmptyChar,item = '*';end % Make the ismember call easier.
            if ischar(item)&&~ismember({item},{'*','id','js','cs','im','if','fw'})
                ME.message = 'Invalid flag. Must be an empty char or *, id, js, cs, im, fw, or if.';
                return
            end
            checkpoint('WBM_parse_inputs________________________line165','CoverTest')
        case 'UseLocalTime'
            checkpoint('WBM_parse_inputs','test_if_scalar_logical')
            [passed,opts.UseLocalTime] = test_if_scalar_logical(item);
            if ~passed
                ME.message = 'UseLocalTime should be either true or false';
                return
            end
        case 'UseURLwrite'
            checkpoint('WBM_parse_inputs','test_if_scalar_logical')
            [passed,item] = test_if_scalar_logical(item);
            if ~passed
                ME.message = 'UseURLwrite should be either true or false';
                return
            end
            %Force the use of urlwrite if websave is not available.
            opts.UseURLwrite = item || default.UseURLwrite;
        case 'err429'
            if ~isa(item,'struct')
                ME.message = 'The err429 parameter should be a struct.';
                return
            end
            
            % Find the fields of the struct that are changed from the default.
            [item,fn_] = parse_NameValue(default.err429,item);
            
            % Loop through the fields in the input and overwrite defaults.
            for n=1:numel(fn_)
                item_ = item.(fn_{n});
                switch fn_{n}
                    case 'CountsAsTry'
                        checkpoint('WBM_parse_inputs','test_if_scalar_logical')
                        [passed,item_] = test_if_scalar_logical(item_);
                        if ~passed
                            ME.message = ['Invalid field CountsAsTry in the err429 parameter:',...
                                char(10),'should be a logical scalar.']; %#ok<CHARTEN>
                            return
                        end
                        opts.err429.CountsAsTry = item_;
                    case 'TimeToWait'
                        if ~isnumeric(item_) || numel(item_)~=1
                            ME.message = ['Invalid field TimeToWait in the err429 parameter:',...
                                char(10),'should be a numeric scalar.']; %#ok<CHARTEN>
                            return
                        end
                        % Under some circumstances this value is divided, so it has to be converted
                        % to a float type.
                        opts.err429.TimeToWait = double(item_);
                    case 'PrintAtVerbosityLevel'
                        if ~isnumeric(item_) || numel(item_)~=1 || ...
                                double(item_)~=round(double(item_))
                            ME.message = ['Invalid field PrintAtVerbosityLevel in the err429 ',...
                                'parameter:',char(10),'should be a scalar double integer.']; %#ok<CHARTEN>
                            return
                        end
                        opts.err429.PrintAtVerbosityLevel = item_;
                    otherwise
                        checkpoint('WBM_parse_inputs','warning_')
                        warning_(opts.print_to,'HJW:WBM:NameValue_not_found',...
                            ['Name,Value pair not recognized during parsing of err429 ',...
                            'parameter:\n    %s'],fn_{n});
                end
            end
            checkpoint('WBM_parse_inputs________________________line228','CoverTest')
        case 'waittime'
            try item = double(item);catch,end
            if ~isa(item,'double') || numel(item)~=1 || item<0
                ME.message = 'The waittime parameter should be a scalar convertible to double.';
                return
            end
            opts.waittime = item;
            checkpoint('WBM_parse_inputs________________________line236','CoverTest')
        case 'if_UTC_failed'
            if (iscellstr(item)||isa(item,'string')) && numel(item)==1 %#ok<ISCLSTR>
                item = char(item); % Unwrap a scalar string/cellstr.
            end
            AllowedChoices = {'error','ignore','warn_0','warn_1','warn_2','warn_3'};
            checkpoint('WBM_parse_inputs','parse_NameValue_option')
            item = parse_NameValue_option(AllowedChoices,item);
            if isempty(item)
                ME.message = ['The UTC_failed parameter is invalid.',char(10),...
                    'See the documentation for valid values.']; %#ok<CHARTEN>
                return
            end
            opts.UTC_failed = item;
            checkpoint('WBM_parse_inputs________________________line250','CoverTest')
        case 'RunAsDate__fix'
            % Undocumented. You should probably not change this default.
            [passed,item] = test_if_scalar_logical(item);
            if ~passed
                ME.message = 'RunAsDate__fix is expected to be a scalar logical.';
                return
            end
            opts.RunAsDate__fix = item;
        case 'timeout'
            try
                item = double(item);
                if numel(item)~=1 || item<0
                    error('trigger error')
                end
            catch
                ME.message = 'The timeout parameter should be a positive numeric scalar.';
                return
            end
            opts.timeout = item;
            checkpoint('WBM_parse_inputs________________________line270','CoverTest')
    end
end

% Set the behavior based on the UTC_failed setting and the verbosity.
if strcmp(opts.UTC_failed,'error')
    opts.UTC_fail_response = 'error';
elseif strcmp(opts.UTC_failed,'ignore')
    opts.UTC_fail_response = 'ignore';
else
    level=str2double(strrep(opts.UTC_failed,'warn_',''));
    if opts.verbose>=level
        opts.UTC_fail_response = 'warn';
    else
        opts.UTC_fail_response = 'ignore';
    end
end

% If the requested date doesn't match the current date, saves are not allowed, even if tries would
% suggest they are, so the code below checks this and sets tries(2) to 0 if needed.
% Because the server is in UTC (which might differ from the (local) time returned by the now
% function), the bounds need to be adjusted if the local time was used to determine the bounds.
checkpoint('WBM_parse_inputs','WBM_getUTC_local')
currentUTC = WBM_getUTC_local;
if currentUTC==0,currentUTC=now;end %#ok<TNOW1> This will be dealt with elsewhere if needed.
if opts.UseLocalTime
    % Shift the bounds (which are currently in the local time) to UTC.
    timezone_offset = currentUTC-now; %#ok<TNOW1>
    if opts.RunAsDate__fix && abs(timezone_offset)>(14.1/24)
        % This means Matlab does not know the correct time, as timezones range from -12 to +14.
        % Round down to true timezone offset. This is generally not what you would want.
        timezone_offset = rem(timezone_offset,1);
    end
    % Round the offset to 15 minutes (the maximum resolution of timezones).
    timezone_offset = round(timezone_offset*24*4)/(24*4);
    opts.date_bounds.datenum = opts.date_bounds.datenum-timezone_offset;
    bounds = opts.date_bounds.datenum;
else
    % The date_part is in already in UTC.
    bounds = opts.date_bounds.datenum;
end
% Old releases of Matlab need a specific format from a short list, the closest to the needed format
% (yyyymmddHHMMSS) is ISO 8601 (yyyymmddTHHMMSS).
item = {datestr(bounds(1),'yyyymmddTHHMMSS'),datestr(bounds(2),'yyyymmddTHHMMSS')}; %#ok<DATST>
item{1}(9) = '';item{2}(9)='';%Remove the T.
opts.date_bounds.double = [str2double(item{1}) str2double(item{2})];
if ~( bounds(1)<=currentUTC && currentUTC<=bounds(2) )
    % No saves allowed, because datepart doesn't match today.
    opts.tries(2) = 0;
end

% If the m_date_r is set to error and the flag is set to something other than the default, the
% check_date function will return an error, regardless of the date stamp of the file.
% If that is the case, throw an error here.
if opts.m_date_r==2 && ~( strcmp(opts.flag,'*') || isempty(opts.flag) )
    ME.message = ['m_date_r set to ''error'' and the flag set to something other than '''' will',...
        char(10),'by definition cause an error, as the downloaded pages will not contain any',...
        char(10),'dates. See the help text for a work-around for images.']; %#ok<CHARTEN>
    ME.identifier = 'HJW:WBM:IncompatibleInputs';
    return
end
if ~ismember('m_date_r',replaced) && ~( strcmp(opts.flag,'*') || isempty(opts.flag) )
    % If the default is not changed, but the flag is set to something else than '*'/'', then the
    % m_date_r should be set to 0 (ignore).
    opts.m_date_r = 0;
end
success = true;ME = [];
end
function [opts,print_to_fieldnames]=WBM_parse_inputs_defaults
% Create a struct with default values.
persistent opts_ print_to_fieldnames_
if isempty(opts_)
    opts_ = struct;
    opts_.date_part = '2'; % Load the date the closest to 2499-12-31 11:59:59.
    opts_.target_date = '';% Load the date the closest to 2499-12-31 11:59:59.
    opts_.tries = [5 4 4];% These are the [loads saves timeouts] allowed.
    opts_.response = {...
        'tx',404,'load'; % A 404 may also occur after a successful save.
        'txtx',[404 404],'save';
        'tx',403,'save';
        't2t2',[403 403],'exit'; % The page likely doesn't support the WBM.
        'tx',429,'pause_retry'; % Server is overloaded, wait a while and retry.
        't2t2t2',[429 429 429],'exit' ... % Page save probably forbidden by WBM.
        };
    opts_.ignore = 4080;
    opts_.verbose = 3;
    opts_.UTC_failed = 'warn_3'; % Unused in default, but used when parsing options.
    opts_.UTC_fail_response = 'warn';
    opts_.m_date_r = 1; % This selects 'warning' as default behavior.
    opts_.flag = '';
    opts_.UseLocalTime = false;
    % The websave function was introduced in R2014b (v8.4) and isn't built into Octave (webread was
    % introduced in 6.1.0, but websave not yet). As an undocumented feature, this can be forced to
    % true, which causes urlwrite to be used, even if websave is available. A check is in place to
    % prevent the reverse.
    try no_websave = isempty(which(func2str(@websave)));catch,no_websave = true;end
    opts_.UseURLwrite = no_websave; % (this allows user-implementation in subfunction)
    opts_.err429 = struct('CountsAsTry',false,'TimeToWait',15,'PrintAtVerbosityLevel',3);
    opts_.waittime = 60;
    opts_.timeout = 10;
    
    checkpoint('WBM_parse_inputs','parse_print_to___get_default')
    [opts_.print_to,print_to_fieldnames_] = parse_print_to___get_default;
    for n=1:numel(print_to_fieldnames_)
        opts_.(print_to_fieldnames_{n})=[];
    end
    
    checkpoint('WBM_parse_inputs','WBM_parse_date_to_range')
    [bounds,midpoint] = WBM_parse_date_to_range(opts_.date_part);
    opts_.date_part = midpoint;opts_.date_bounds.datenum=bounds;
    item = {datestr(bounds(1),'yyyymmddTHHMMSS'),datestr(bounds(2),'yyyymmddTHHMMSS')}; %#ok<DATST>
    item{1}(9) = '';item{2}(9) = '';
    opts_.date_bounds.double = [str2double(item{1}) str2double(item{2})];
    
    opts_.RunAsDate__fix = false;
    
    opts_.WBMRequestCounterFile = '';
end
opts = opts_;
print_to_fieldnames = print_to_fieldnames_;
end
function [opts,ME]=ParseRequestCounterInteraction(opts,replaced)
ME = struct('identifier','','message','');
persistent filename
if isempty(filename)
    % Generate the filename for the request counter file. If it doesn't exist, create one and store
    % the number zero. This counter is intended to be shared across all releases of Matlab and
    % Octave from this user.
    try
        checkpoint('WBM_parse_inputs','GetWritableFolder')
        [f,status] = GetWritableFolder('ErrorOnNotFound',0);
        if status==0
            error('trigger')
        end
        filename = fullfile(f,'WBM','RequestCounter.txt');
        
        checkpoint('WBM_parse_inputs','makedir')
        if ~exist(fileparts(filename),'dir'),makedir(fileparts(filename));end
        
        if ~exist(fileparts(filename),'dir'),error('trigger');end
        
        if ~exist(filename,'file')
            fid = fopen(filename,'w');
            fprintf(fid,'%d',0);
            fclose(fid);
        end
    catch
        filename = [];
        ME = struct(...
            'identifier','HJW:WBM:RequestCounterFailed',...
            'message','Failed to create a folder/file to store the request counter.');
        return
    end
end
RequestCounter = struct('fn',filename,'interaction','');
if ismember('WBMRequestCounterFile',replaced)
    % Allow 'filename' as undocumented feature.
    AllowedChoices = {'read','reset','filename'};
    checkpoint('WBM_parse_inputs','parse_NameValue_option')
    RequestCounter.interaction = parse_NameValue_option(AllowedChoices,opts.WBMRequestCounterFile);
    if isempty(RequestCounter.interaction)
        ME = struct(...
            'identifier','',...
            'message','WBMRequestCounterFile should be empty, or contain ''read'' or ''reset''.');
        return
    end
end
opts.RequestCounter = RequestCounter;
end
function is_invalid=WBM_parse_inputs__validate_response_format(response)
% Check if the content of the response input is in the correct format.
% See doc('WBM') for a description of the correct format.
is_invalid = false;
if isa(response,'string'),response=char(response);end
if ~iscell(response) || isempty(response) || size(response,2)~=3
    is_invalid = true;return
end
for row=1:size(response,1)
    % Check col 1: t1, t2, tx or combination.
    item = response{row,1};
    item_count = numel(item(2:2:end));
    if ~ischar(item) || numel(item)==0 || ~all(ismember(item(2:2:end),'12x'))
        is_invalid = true;return
    end
    % Check col 2: html codes.
    item = response{row,2};
    if ~isa(item,'double') || numel(item)~=item_count
        % The validity of a html code is not checked.
        % A timeout caught in Matlab is encoded with 4080 (due to its similarity with HTML status
        % code 408).
        is_invalid = true;return
    end
    % Check col 3: load, save, exit or pause_retry.
    item = response{row,3};
    if ~ischar(item) || ~ismember({item},{'load','save','exit','pause_retry'})
        is_invalid = true;return
    end
end
end
function [timestamp,status,waittime]=WBM_retrieve_timestamp(url,opts,waittime)
% Attempt to retrieve the exact timestamp of a capture close to date_part.
% Usage is based on https://archive.org/help/wayback_api.php
%
% The timestamp is a char array and may be empty, in which case the status will be 404.
% The status is a double with either the HTTP status code returned by archive.org, or 404.

% Avoid problems caused by any & symbol in the url.
url = strrep(url,'&','%26');

avl_url = ['http://archive.org/wayback/available?url=' url '&timestamp=' opts.date_part];
if opts.UseURLwrite
    checkpoint('WBM_retrieve_timestamp','tmpname')
    fn = tmpname('WBM_available_API_response','.txt');
end
for try_iterations=1:3
    try
        if opts.UseURLwrite
            fn = urlwrite(avl_url,fn); %#ok<URLWR>
            checkpoint('WBM_retrieve_timestamp','readfile')
            a = readfile(fn);delete(fn);
            checkpoint('WBM_retrieve_timestamp','JSON')
            a = JSON(a{1});
        else
            a = webread(avl_url);
        end
        break
    catch
        % Assume the connection is down, retry in intervals.
        connection_down_wait_factor = 0; % Initialize.
        checkpoint('WBM_retrieve_timestamp','isnetavl')
        while ~isnetavl
            if waittime.total<=waittime.cap
                % Total wait time exceeded, return the error condition.
                a = [];break
            end
            curr_time = datestr(now,'HH:MM:SS'); %#ok<DATST,TNOW1>
            if opts.verbose>=1
                msg = sprintf('Internet connection down, retrying in %d seconds (@%s)',...
                    2^connection_down_wait_factor,curr_time);
                checkpoint('WBM_retrieve_timestamp','warning_')
                warning_(opts.print_to,msg)
            end
            pause(2^connection_down_wait_factor)
            waittime.total = waittime.total+2^connection_down_wait_factor;
            % Increment, but cap to a reasonable interval.
            connection_down_wait_factor = min(1+connection_down_wait_factor,6);
        end
    end
end
try
    % This can fail for 4 reasons: the waittime has been exceeded (e.g. because there is no
    % connection in the first place), the connection is stable enough to get the ping (but not to
    % read the JSON response), an unparsed error occurred when reading the JSON, or the url simply
    % doesn't have a capture.
    % It is also possible for the target date to be too precise. There may not be a perfect
    % solution to deal with this automatically.
    timestamp = a.archived_snapshots.closest.timestamp;
    status = str2double(a.archived_snapshots.closest.status);
catch
    timestamp = '';
    status = 404; % A 404 would probably be the best guess.
end
end
function tf=WBM_UTC_test
% This returns a logical encoding whether the UTC determination can be expected to work.
persistent UTC_is_available
if isempty(UTC_is_available)
    UTC_is_available = WBM_getUTC_local>0;
    if ~UTC_is_available && ~isnetavl
        % The web method might have failed due to internet connection issues.
        UTC_is_available = []; % Clear the persistent to test at the next call.
        tf = false;
    else
        tf = UTC_is_available;
    end
else
    tf = UTC_is_available;
end
end

function out=checkpoint(caller,varargin)
% This function has limited functionality compared to the debugging version.
% (one of the differences being that this doesn't read/write to a file)
% Syntax:
%   checkpoint(caller,dependency)
%   checkpoint(caller,dependency_1,...,dependency_n)
%   checkpoint(caller,checkpoint_flag)
%   checkpoint('reset')
%   checkpoint('read')
%   checkpoint('write_only_to_file_on_read')
%   checkpoint('write_to_file_every_call')

persistent data
if isempty(data)||strcmp(caller,'reset')
    data = struct('total',0,'time',0,'callers',{{}});
end
if strcmp(caller,"read")
    out = data.time;return
end
if nargin==1,return,end
then = now;
for n=1:numel(varargin)
    data.total = data.total+1;
    data.callers = sort(unique([data.callers {caller}]));
    if ~isfield(data,varargin{n}),data.(varargin{n})=0;end
    data.(varargin{n}) = data.(varargin{n})+1;
end
data.time = data.time+ (now-then)*( 24*60*60*1e3 );
data.time = round(data.time);
end

