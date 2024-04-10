# WBM documentation
[![View WBM on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/64746-wayback-machine-api)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=thrynae/WBM)


Table of contents

- Description section:
- - [Description](#description)
- Matlab/Octave section:
- - [Syntax](#syntax)
- - [Output arguments](#output-arguments)
- - [Input arguments](#input-arguments)
- - [Name,Value pairs](#namevalue-pairs)
- - [Compatibility, version info, and licence](#compatibility-version-info-and-licence)

## Description

With this function you can download captures to the internet archive that matches a date pattern. If the current time matches the pattern and there is no valid capture, a capture will be generated. The WBM time stamps are in UTC, so a switch allows you to provide the date-time pattern in local time, which will be converted to UTC internally.

This code enables you to use a specific web page in your data processing, without the need to check if the page has changed its structure or is not available at all.

You can also redirect all outputs (errors only partially) to a file or a graphics object, so you can more easily use this function in a GUI or allow it to write to a log file.

Usage instruction about the syntax of the WBM interface are derived from a [Wikipedia help page](https://en.wikipedia.org/wiki/Help:Using_the_Wayback_Machine). Fuzzy date matching behavior is based on [this](https://archive.org/web/web-advancedsearch.php) archive.org page.

If the Wayback Machine is useful to you, please [consider donating](https://archive.org/donate/). Based on a yearly operating cost of 35m$ and approximately 6k&nbsp;hits/s, please donate at least $1 for every 5000 requests. They don't block API access, require a login, or anything similar. If you abuse it, they may have to change that and you will have spoiled it for everyone. Please make sure your usage doesn't break this Nice&nbsp;Thing&trade;.

Generally, each call to this function will result in two requests. A counter will be stored in a file. The `WBMRequestCounterFile` optional input can be used to interact with the file. Run `WBM([],[],'WBMRequestCounterFile','read')` to read the current count.

(These statistics are based on HTTP responses shown on [this 60-day average chart](https://analytics1.archive.org/stats/wb.php#60d) and the 990&nbsp;IRS forms posted by [ProPublica](https://projects.propublica.org/nonprofits/organizations/943242767).)

## Matlab/Octave

### Syntax

    WBM(filename,url_part)
    WBM(___,Name,Value)
    WBM(___,options)
    outfilename = WBM(___)
    [outfilename,FileCaptureInfo] = WBM(___)

### Output arguments

|Argument|Description|
|---|---|
|outfilename|Full path of the output file, the variable is empty if the download failed.|
|FileCaptureInfo|A struct containing the information about the downloaded file. It contains the timestamp of the file (in the `'timestamp'` field), the flag used (`'flag'`), and the base URL (`'url'`). In short, all elements needed to form the full URL of the capture.|

### Input arguments

|Argument|Description|
|---|---|
|filename|The target filename in any format that websave (or urlwrite) accepts. If this file already exists, it will be overwritten in most cases.|
|url_part|This URL will be searched for on the WBM. The URL might be changed (e.g. `:80` is often added).|
|Name,Value|The settings below can be entered with a Name,Value syntax.|
|options|Instead of the Name,Value, parameters can also be entered in a struct. Missing fields will be set to the default values.|

### Name,Value pairs

|Name|Value|
|---|---|
|date_part|A string with the date of the capture. It must be in the yyyymmddHHMMSS format, but doesn't have to be complete. Note that this is represented in UTC.<br>If incomplete, the Wayback Machine will return a capture that is as close to the midpoint of the matching range as possible. So for `date_part='2'` the range is `2000-01-01 00:00` to `2999-12-31 23:59:59`, meaning the WBM will attempt to return the capture closest to `2499-12-31 23:59:59`.<br>`default='2';`|
|target_date|Normally, the Wayback Machine will return the capture closest to the midpoint between the earliest valid date matching the date_part and the latest date matching the date_part. This parameter allows setting a different target, while still allowing a broad range of results. This can be used to skew the preference when loading a page. Like date_part, it must be in the yyyymmddHHMMSS format, and doesn't have to be complete. An example would be to provide `'date_part','2','target_date','20220630'`. That way, if a capture is available from 2022, that will be loaded, but any result from 2000 to 2999 is allowed. If left empty, the midpoint determined by date_part will be used as the target. If the target is in the future (which will be determined by parsing the target to bounds and determining the midpoint), it will be cropped to the current local time minus 14 hours to avoid errors in the Wayback Machine API call.<br>`default='';`|
|UseLocalTime|A scalar logical. Interpret the date_part in local time instead of UTC. This has the practical effect of the upper and lower bounds of the matching date being shifted by the timezone offset.<br>`default=false;`|
|tries|A 1x3 vector. The first value is the total number of times an attempt to load the page is made, the second value is the number of save attempts and the last value is the number of timeouts allowed.<br>`default=[5 4 4];`|
|verbose|A scalar denoting the verbosity. Level 0 will hide all errors that are caught. Level 1 will enable only warnings about the internet connection being down. Level 2 includes errors NOT matching the usual pattern as well and level 3 includes all other errors that get rethrown as warning.<br>Octave uses libcurl, making error catching is bit more difficult. This will result in more HTML errors being rethrown as warnings under Octave than Matlab.<br>`default=3;`|
|if_UTC_failed|This is a char array with the intended behavior for when this function is unable to determine the UTC. The options are `'error'`, `'warn_0'`, `'warn_1'`, `'warn_2'`, `'warn_3'`, and `'ignore'`. For the options starting with warn_, a warning will be triggered if the `'verbose'` parameter is set to this level or higher (so `'warn_0'` will trigger a warning if `'verbose'` is set to 0).<br>If this parameter is not set to `'error'`, the valid time range is expanded by -12 and +14 hours to account for all possible time zones, and the midpoint is shifted accordingly.<br>`default='warn_3';`|
|m_date_r|A string describing the response to the date missing in the downloaded web page. Usually, either the top bar will be present (which contains links), or the page itself will contain links, so this situation may indicate a problem with the save to the WBM. Allowed values are `'ignore'`, `'warning'` and `'error'`. Be aware that non-page content (such as images) will set off this response. Flags other than the default will also set off this response.<br>`default='warning';` if flags is not default then `default='ignore';`|
|response|The response variable is a cell array, where each row encodes one sequence of HMTL errors and the appropriate next action. The syntax of each row is as follows:<br>#1 If there is a sequence of failure that fit the first cell,<br>#2 and the HTML error codes of the sequence are equal to the second cell,<br>#3 then respond as per the third cell.<br>The sequence of failures are encoded like this:<br>t1: failed attempt to load, t2: failed attempt to save, tx: either failed to load, or failed to save.<br>The error code list must be HTML status codes. The Matlab timeout error is encoded with 4080 (analogous to the HTTP 408 timeout error code). The error is extracted from the identifier, which is not always possible, especially in the case of Octave.<br>The response in the third cell is either `'load'`, `'save'`, `'exit'`, or `'pause_retry'`. Load and save set the preferred type. If a response is not allowed by 'tries' left, the other response (save or load) is tried, until `sum(tries(1:2))==0`. If the response is set to exit, or there is still no successful download after tries has been exhausted, the output file will be deleted and the script will exit. The pause_retry is intended for use with an error 429. See the err429 parameter for more options.<br>`default={'tx',404,'load';'txtx',[404 404],'save';'tx',403,'save';'t2t2',[403 403],'exit';'tx',429,'pause_retry';'t2t2t2',429,'exit'};`|
|err429|Sometimes the webserver will return a 429 status code. This should trigger a waiting period of a few seconds. If this status code is return 3 times for a save, that probably means the number of saves is exceeded. Disable saves when retrying within 24 hours, as they will keep leading to this error code.<br>This parameter controls the behavior of this function in case of a 429 status code. It is a struct with the following fields:<br>The CountsAsTry field (logical) describes if the attempt should decrease the tries counter.<br>The TimeToWait field (double) contains the time in seconds to wait before retrying.<br>The PrintAtVerbosityLevel field (double) contains the verbosity level at which a text should be printed, showing the user the function did not freeze.<br>`default=struct('CountsAsTry',false,'TimeToWait',15,'PrintAtVerbosityLevel',3);`|
|ignore|The ignore variable is vector with the same type of error codes as in the response variable. Ignored errors will only be ignored for the purposes of the response, they will not prevent the tries vector from decreasing.<br>`default=4080;`|
|flag|The flags can be used to specify an explicit version of the archived page. The options are `''`, `'*'`, `'id'` (identical), `'js'` (Javascript), `'cs'` (CSS), `'im'` (image), `'fw'`/`'if'` (iFrame). An empty flag will only expand the date. Providing `'*'` used to explicitly expand the date and only show the calendar view when using a browser, but it seems to now also load the calendar with websave/urlwrite. With the `'id'` flag the page is show as captured (i.e. without the WBM banner, making it ideal for e.g. exe files). With the `'id'` and `'*'` flags the date check will fail, so the missing date response (m_date_r) will be invoked. For the `'im'` flag you can circumvent this by first loading in the normal mode (`''`), and then extracting the image link from that page. That way you can enforce a date pattern and still get the image. The [Wikipedia page](https://en.wikipedia.org/wiki/Help:Using_the_Wayback_Machine) suggests that a flag syntax requires a full date, but this seems not to be the case, as the date can still auto-expand.<br>`default='';`|
|waittime|This value controls the maximum time that is spent waiting on the internet connection for each call of this function. This does not include the time waiting as a result of a 429 error. The input must be convertible to a scalar `double`. This is the time in seconds.<br>NB: Setting this to inf will cause an infite loop if the internet connection is lost.<br>`default=60;`|
|timeout|This value is the allowed timeout in seconds. It is ignored if it isn't supported. The input must be converitble to a scalar `double`.<br>`default=10;`|
|WBMRequestCounterFile|This must be empty, or a char containing `'read'` or `'reset'`. If it is provided, all other inputs are ignored, except the exception redirection. That means `count=WBM([],[],'WBMRequestCounterFile','read');` is a valid call. For the `'read'` input, the output will contain the number of requests posted to the Wayback Machine. This counter is intended to cover all releases of Matlab and GNU Octave. Using the `'reset'` switch will reset the counter back to 0.<br>`default='';`|
|print_to_con|<i>An attempt is made to also use this parameter for warnings or errors during input parsing.</i> <br>A logical that controls whether warnings and other output will be printed to the command window. Errors can't be turned off. <br>`default=true;` <br>Specifying `print_to_fid`, `print_to_obj`, or `print_to_fcn` will change the default to `false`, unless parsing of any of the other exception redirection options results in an error.|
|print_to_fid|<i>An attempt is made to also use this parameter for warnings or errors during input parsing.</i> <br>The file identifier where console output will be printed. Errors and warnings will be printed including the call stack. You can provide the fid for the command window (`fid=1`) to print warnings as text. Errors will be printed to the specified file before the error is actually thrown. <br>If `print_to_fid`, `print_to_obj`, and `print_to_fcn` are all empty, this will have the effect of suppressing every output except errors. <br>Array inputs are allowed. <br>`default=[];`|
|print_to_obj|<i>An attempt is made to also use this parameter for warnings or errors during input parsing.</i> <br>The handle to an object with a String property, e.g. an edit field in a GUI where console output will be printed. Messages with newline characters (ignoring trailing newlines) will be returned as a cell array. This includes warnings and errors, which will be printed without the call stack. Errors will be written to the object before the error is actually thrown. <br>If `print_to_fid`, `print_to_obj`, and `print_to_fcn` are all empty, this will have the effect of suppressing every output except errors. <br>Array inputs are allowed. <br>`default=[];`|
|print_to_fcn|<i>An attempt is made to also use this parameter for warnings or errors during input parsing.</i> <br>A `struct` with a function handle, anonymous function or inline function in the `'h'` field and optionally additional data in the `'data'` field. The function should accept three inputs: a `char` array (either `'warning'` or `'error'`), a `struct` with the message, id, and stack, and the optional additional data. The function(s) will be run before the error is actually thrown. <br>If `print_to_fid`, `print_to_obj`, and `print_to_fcn` are all empty, this will have the effect of suppressing every output except errors. <br>Array inputs are allowed. <br>`default=[];`|

### Compatibility, version info, and licence
Compatibility considerations:
- HTML error codes are harder to catch on Octave. Depending on the selected verbosity level that means the number of warnings will be larger.
- The duration of a timeout can only be set with websave. This means that for larger files or less stable internet connections, a timeout error will be more likely when using older releases or Octave.

|Test suite result|Windows|Linux|MacOS|
|---|---|---|---|
|Matlab R2024a|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2023b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2023a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2022b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2022a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2021b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2021a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2020b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2020a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2019b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2019a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2018b|<it>W11 : </it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2018a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2017b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2016b|<it>W11 : Pass</it>|<it>ubuntu_22.04 : Pass</it>|<it>Monterey : Pass</it>|
|Matlab R2015a|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2013b|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab R2007b|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Matlab 6.5 (R13)|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Octave 8.4.0|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Octave 7.2.0|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Octave 6.2.0|<it>W11 : Pass</it>|<it>raspbian_11 : Pass</it>|<it>Monterey : Pass</it>|
|Octave 5.2.0|<it>W11 : Pass</it>|<it></it>|<it></it>|
|Octave 4.4.1|<it>W11 : Pass</it>|<it></it>|<it></it>|

    Version: 4.1.0
    Date:    2024-04-10
    Author:  H.J. Wisselink
    Licence: CC by-nc-sa 4.0 ( https://creativecommons.org/licenses/by-nc-sa/4.0 )
    Email = 'h_j_wisselink*alumnus_utwente_nl';
    Real_email = regexprep(Email,{'*','_'},{'@','.'})
### Test suite

The tester is included so you can test if your own modifications would introduce any bugs. These tests form the basis for the compatibility table above. Note that functions may be different between the tester version and the normal function. Make sure to apply any modifications to both.
