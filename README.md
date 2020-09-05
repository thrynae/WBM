[![View Wayback Machine API on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/64746-wayback-machine-api)

This functions acts as an API for the Wayback Machine (web.archive.org).

With this function you can download captures to the Internet Archive (archive.org) that matches a date pattern. If the current time matches the pattern and there is no valid capture, a capture will be generated.  
This code enables you to use a specific web page in your processing, without the need to check if the page has changed its structure or is not available at all.  
You can redirect warnings, displayed messages and the contents of an error message to a GUI element or log file.  
This script should work on all Matlab releases and on Octave (test file included), as well as every OS (tested on Windows, Ubuntu and MacOS).

For non-text captures (images, javascript, CSS files, etc), the flags can be used (see the help text for details).

At some point (probably midway 2019), it became possible that this script would download a file that looks as if it was a capture, while it actually was a copy of the live page (without a save being triggered). The reason behind this is some change in how archive.org handles requests, although it is not clear to me what this change is. An attempt is being made to prevent this and trigger a save explicitly.

The date-time pattern of the Wayback Machine is in UTC. A switch is included that allows to provide the pattern in local time. The pattern is parsed to an upper and lower bound, which are then shifted by the difference between UTC and the local time.

Licence: CC by-nc-sa 4.0