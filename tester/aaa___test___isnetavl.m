function aaa___test___isnetavl(varargin)
%test the isnetavl function as far as that is possible
%this test will assume there is internet connectivity

% suppress v6.5 warning
v=version;v(strfind(v,'.'):end)='';v=str2double(v);
if v<=7
    warning off MATLAB:m_warning_end_without_block;clc
end

[connected(1),timing(1)]=isnetavl___ping_via_html;
[connected(2),timing(2)]=isnetavl___ping_via_system;

fprintf('results:\n')
for n=1:2
    fprintf('  method %d returned: ',n)
    if connected(n)
        fprintf(' [online] ')
    else
        fprintf(' [offline] ')
    end
    fprintf(' (ping time= %.0f ms)\n',timing(n))
end
fprintf('\n')

if any(~connected)
    error('test did not match expected result')
else
    disp('test completed')
end
end
function [connected,timing]=isnetavl
% Ping to one of Google's DNSes.
% Optional second output is the ping time (0 if not connected).
%
% Includes a fallback to HTML if usage of ping is not allowed. This increases the measured ping.
%
%  _________________________________________________________________
% | Compatibility | Windows 10  | Ubuntu 20.04 LTS | MacOS Catalina |
% |---------------|-------------|------------------|----------------|
% | ML R2020a     |  works      |  not tested      |  not tested    |
% | ML R2015b     |  works      |  not tested      |  not tested    |
% | ML R2011a     |  works      |  not tested      |  not tested    |
% | ML 6.5 (R13)  |  works      |  not tested      |  not tested    |
% | Octave 5.2.0  |  works      |  works           |  not tested    |
% | Octave 4.4.1  |  works      |  not tested      |  works         |
% """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
%
% Version: 1.2.2
% Date:    2020-06-28
% Author:  H.J. Wisselink
% Licence: CC by-nc-sa 4.0 ( http://creativecommons.org/licenses/by-nc-sa/4.0 )
% Email=  'h_j_wisselink*alumnus_utwente_nl';
% Real_email = regexprep(Email,{'*','_'},{'@','.'})

tf=ICMP_is_blocked;
if isempty(tf)
    %Unable to determine if ping is allowed, the connection must be down
    connected=0;
    timing=0;
else
    if tf
        %ping not allowed
        %(the timing is not reliable)
        [connected,timing]=isnetavl___ping_via_html;
    else
        %ping allowed
        [connected,timing]=isnetavl___ping_via_system;
    end
end
end
function [tf,connected,timing]=ICMP_is_blocked
%Check if ICMP 0/8/11 is blocked
%
%tf is empty if both methods fail

persistent output
if ~isempty(output)
    tf=output;return
end

%First check if ping works
[connected,timing]=isnetavl___ping_via_system;
if connected
    %Ping worked and there is an internet connection
    output=false;
    tf=false;
    return
end

%There are two options: no internet connection, or ping is blocked
[connected,timing]=isnetavl___ping_via_html;
if connected
    %There is an internet connection, therefore ping must be blocked
    output=true;
    tf=true;
    return
end

%Both methods failed, internet is down. Leave the value of tf (and the persistent variable) set to
%empty so it is tried next time.
tf=[];
end
function [connected,timing]=isnetavl___ping_via_html
%Ping is blocked by some organizations. As an alternative, the google.com page can be loaded as a
%normal HTML, which should work as well, although it is slower. This also means the ping timing is
%no longer reliable.
try
    then=now;
    if exist('webread','file')
        str=webread('http://google.com'); %#ok<NASGU>
    else
        str=urlread('http://google.com'); %#ok<NASGU,URLRD>
    end
    connected=1;
    timing=(now-then)*24*3600*1000;
catch
    connected=0;
    timing=0;
end
end
function [connected,timing]=isnetavl___ping_via_system
if ispc
    try
        %                                   8.8.4.4 will also work
        [ignore_output,b]=system('ping -n 1 8.8.8.8');%#ok<ASGLU> ~
        stats=b(strfind(b,' = ')+3);
        stats=stats(1:3);%[sent received lost]
        if ~strcmp(stats,'110')
            error('trigger error')
        else
            %This branch will error for 'destination host unreachable'
            connected=1;
            %This assumes there is only one place with '=[digits]ms' in the response, but this code
            %is not language-specific.
            [ind1,ind2]=regexp(b,' [0-9]+ms');
            timing=b((ind1(1)+1):(ind2(1)-2));
            timing=str2double(timing);
        end
    catch
        connected=0;
        timing=0;
    end
elseif isunix
    try
        %                                   8.8.4.4 will also work
        [ignore_output,b]=system('ping -c 1 8.8.8.8');%#ok<ASGLU> ~
        ind=regexp(b,', [01] ');
        if b(ind+2)~='1'
            %This branch includes 'destination host unreachable' errors
            error('trigger error')
        else
            connected=1;
            %This assumes the first place with '=[digits] ms' in the response contains the ping
            %timing. This code is not language-specific.
            [ind1,ind2]=regexp(b,'=[0-9.]+ ms');
            timing=b((ind1(1)+1):(ind2(1)-2));
            timing=str2double(timing);
        end
    catch
        connected=0;
        timing=0;
    end
else
    error('How did you even get Matlab to work?')
end
end