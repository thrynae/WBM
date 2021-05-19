function data = loadjson(string,varargin)
% parse a JSON (JavaScript Object Notation) string
%
% syntax:
%   data=loadjson(str)
%
% original authors:
% Qianqian Fang
% Nedialko Krouchev
% François Glineur
% Joel Feenstra
%
% This is heavily modified from jsonlab 2.0.1.
% The modifications are to ensure this code works on ML6.5 and to remove _some_ unused function
% paths, keeping only the code that will allow parsing of a string.
% Most of the comments have been removed as well.
%
% https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab
%
% http://web.archive.org/web/20210423192107/
%   https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/
%   e581a8a2-4a80-11e4-9553-005056977bd0/4e4f42eb-4861-4dd6-a240-08725362ecd4/packages/zip/
%   jsonlab-2.0.zip

opt=varargin2struct(varargin{:});pos = 1; inputlen = length(string); inputstr = string;
arraytokenidx=find(inputstr=='[' | inputstr==']');arraytoken=inputstr(arraytokenidx);
esc = find(inputstr=='"' | inputstr=='\' ); % comparable to: regexp(inputstr, '["\\]');
index_esc = 1;opt.arraytoken_=arraytoken;opt.arraytokenidx_=arraytokenidx;
opt.simplifycell=jsonopt('SimplifyCell',1,opt);
opt.simplifycellarray=jsonopt('SimplifyCellArray',0,opt);
opt.formatversion=jsonopt('FormatVersion',2,opt);
opt.fastarrayparser=jsonopt('FastArrayParser',1,opt);
opt.parsestringarray=jsonopt('ParseStringArray',0,opt);
opt.usemap=jsonopt('UseMap',0,opt);opt.arraydepth_=1;objid=jsonopt('ObjectID',0,opt);
maxobjid=max(objid);if(maxobjid==0),maxobjid=inf;end,jsoncount=1;
while pos <= inputlen,[cc,pos]=next_char(inputstr, pos);
    switch(cc)
        case '{'
            [data{jsoncount},pos,index_esc]=parse_object(inputstr,pos,esc,index_esc,opt);%#ok<AGROW>
        case '['
            [data{jsoncount},pos,index_esc]=parse_array( inputstr,pos,esc,index_esc,opt);%#ok<AGROW>
        otherwise
            pos=error_pos('Outer level structure must be an object or an array',inputstr,pos);
    end
    if(jsoncount>=maxobjid),break;end,jsoncount=jsoncount+1;
end % while
if(length(objid)>1 || min(objid)>1),data=data(objid(objid<=length(data)));end
jsoncount=length(data);if(jsoncount==1 && iscell(data)),data=data{1};end
if(jsonopt('JDataDecode',1,varargin{:})==1)
    data=jdatadecode(data,'Base64',1,'Recursive',1,varargin{:});
end
if(isfield(opt,'progressbar_')),close(opt.progressbar_);end
end
function [object, pos,index_esc] = parse_array(inputstr, pos, esc, index_esc, varargin)
% JSON array is written in row-major order
pos=parse_char(inputstr, pos, '[');object = cell(0, 1);arraydepth=varargin{1}.arraydepth_;pbar=-1;
if(isfield(varargin{1},'progressbar_')),pbar=varargin{1}.progressbar_;end
format=varargin{1}.formatversion;[cc,pos]=next_char(inputstr,pos);endpos=[];
if cc ~= ']'
    try
        if (varargin{1}.fastarrayparser)>=1 && arraydepth>=varargin{1}.fastarrayparser
            [endpos,maxlevel]=fast_match_bracket(...
                varargin{1}.arraytoken_,varargin{1}.arraytokenidx_,pos);
            if(~isempty(endpos))
                arraystr=['[' inputstr(pos:endpos)]; arraystr=sscanf_prep(arraystr);
                if(isempty(find(arraystr=='"', 1)))
                    % handle 1D array first
                    if(maxlevel==1)
                        astr=arraystr(2:end-1); astr(astr==' ')='';
                        [obj, count, errmsg, nextidx]=sscanf(astr,'%f,',[1,inf]); %#ok<ASGLU>
                        if(nextidx>=length(astr)-1)
                            object=obj; pos=endpos; pos=parse_char(inputstr, pos, ']'); return;
                        end
                    end
                    % next handle 2D array, these are most common ones
                    if(maxlevel==2 && ~isempty(regexp(arraystr(2:end),'^\s*\[','once')))
                        rowstart=find(arraystr(2:end)=='[',1)+1;
                        if(rowstart)
                            [obj, nextidx]=parse2darray(inputstr,pos+rowstart,arraystr);
                            if(nextidx>=length(arraystr)-1)
                                object=obj;if(format>1.9),object=object.';end,pos=endpos;
                                pos=parse_char(inputstr, pos, ']');
                                if(pbar>0),waitbar(pos/length(inStr),pbar,'loading ...');end
                                return;
                            end
                        end
                    end
                    % for N-D packed array in a nested array construct,
                    % in the future can replace 1d and 2d cases
                    if(maxlevel>2 && ~isempty(regexp(arraystr(2:end),'^\s*\[\s*\[','once')))
                        astr=arraystr;dims=nestbracket2dim(astr);
                        if(any(dims==0) || all(mod(dims(:),1) == 0))
                            astr=arraystr;astr(astr=='[')='';astr(astr==']')='';
                            astr=regexprep(astr,'\s*,',',');astr=regexprep(astr,'\s*$','');
                            [obj, count, errmsg, nextidx]=sscanf(astr,'%f,',inf); %#ok<ASGLU>
                            if(nextidx>=length(astr)-1)
                                object=reshape(obj,dims);
                                if(format>1.9),object=permute(object,ndims(object):-1:1);end
                                pos=endpos;pos=parse_char(inputstr, pos, ']');
                                if(pbar>0),waitbar(pos/length(inStr),pbar,'loading ...');end
                                return;
                            end
                        end
                    end
                end
            end
        end
        if(isempty(regexp(arraystr,':','once')))
            arraystr=regexprep(arraystr,'\[','{');arraystr=regexprep(arraystr,'\]','}');
            if(varargin{1}.parsestringarray==0),arraystr=regexprep(arraystr,'\"','''');end
            object=eval(arraystr);
            if iscell(object),for n=1:numel(object),object{n}=unescapejsonstring(object{n});end,end
            pos=endpos;
        end
    catch
    end
    if(isempty(endpos) || pos~=endpos)
        while 1
            varargin{1}.arraydepth_=arraydepth+1;
            [val, pos,index_esc] = parse_value(inputstr, pos, esc, index_esc,varargin{:});
            object{end+1} = val;[cc,pos]=next_char(inputstr,pos); %#ok<AGROW>
            if cc == ']',break;end,pos=parse_char(inputstr, pos, ',');
        end
    end
end
if(varargin{1}.simplifycell)
    if(iscell(object) && ~isempty(object) && isnumeric(object{1}))
        L=true;for n=2:numel(object),L=L&&isequal(size(object{1}), size(object{n}));end
        if L
            try
                oldobj=object;
                if(iscell(object) && length(object)>1 && ndims(object{1})>=2)
                    catdim=size(object{1});catdim=ndims(object{1})-(catdim(end)==1)+1;
                    object=cat(catdim,object{:});object=permute(object,ndims(object):-1:1);
                else,object=cell2mat(object')';
                end
                if iscell(oldobj)&&isstruct(object)&&numel(object)>1&&...
                        varargin{1}.simplifycellarray==0,  object=oldobj;
                end
            catch
            end
        end
    end
    if(~iscell(object) && size(object,1)>1 && ndims(object)==2),object=object';end %#ok<ISMAT>
end
pos=parse_char(inputstr, pos, ']');if(pbar>0),waitbar(pos/length(inputstr),pbar,'loading ...');end
end
function pos=parse_char(inputstr, pos, c)
pos=skip_whitespace(pos, inputstr);
if pos > length(inputstr) || inputstr(pos) ~= c
    pos=error_pos(sprintf('Expected %c at position %%d', c),inputstr,pos);
else,pos = pos + 1;pos=skip_whitespace(pos, inputstr);
end
end
function [c, pos] = next_char(inputstr, pos)
pos=skip_whitespace(pos, inputstr);if pos > length(inputstr),c = [];else,c = inputstr(pos);end
end
function [str, pos,index_esc] = parseStr(inputstr, pos, esc, index_esc, varargin)
if inputstr(pos) ~= '"'
    pos =error_pos('String starting with " expected at position %d',inputstr,pos);
else,pos=pos + 1;
end
str = '';
while pos <= length(inputstr)
    while index_esc <= length(esc) && esc(index_esc) < pos , index_esc = index_esc + 1;end
    if index_esc > length(esc)
        str = [str inputstr(pos:end)];pos = length(inputstr) + 1;break; %#ok<AGROW>
    else,str= [str inputstr(pos:esc(index_esc)-1)];pos = esc(index_esc); %#ok<AGROW>
    end
    nstr = length(str);
    switch inputstr(pos)
        case '"'
            pos = pos + 1;
            if(~isempty(str))
                if(strcmp(str,'_Inf_'))     ,str=Inf;
                elseif(strcmp(str,'-_Inf_')),str=-Inf;
                elseif(strcmp(str,'_NaN_')) ,str=NaN;
                end
            end
            return;
        case '\'
            if pos+1 > length(inputstr)
                pos=error_pos('End of file reached right after escape character',inputstr,pos);
            end
            pos = pos + 1;
            switch inputstr(pos)
                case {'"' '\' '/'},        str(nstr+1)=             inputstr(pos);  pos = pos + 1;
                case {'b' 'f' 'n' 'r' 't'},str(nstr+1)=sprintf(['\' inputstr(pos)]);pos = pos + 1;
                case 'u'
                    if pos+4 > length(inputstr),pos=error_pos(...
                            'End of file reached in escaped unicode character',inputstr,pos);
                    end,str(nstr+(1:6)) = inputstr(pos-1:pos+4); pos = pos + 5;
            end
        otherwise % should never happen
            str(nstr+1) = inputstr(pos);keyboard;pos = pos + 1;
    end
end
str=unescapejsonstring(str);
pos=error_pos('End of file while expecting end of inputstr',inputstr,pos);
end
function [num, pos] = parse_number(inputstr, pos, varargin)
currstr=inputstr(pos:min(pos+30,end));[num,one,err,delta]=sscanf(currstr,'%f',1); %#ok<ASGLU>
if ~isempty(err),pos=error_pos('Error reading number at position %d',inputstr,pos);end
pos = pos + delta-1;
end
function [val, pos,index_esc] = parse_value(inputstr, pos, esc, index_esc, varargin)
len=length(inputstr);
if(isfield(varargin{1},'progressbar_')),waitbar(pos/len,varargin{1}.progressbar_,'loading ...');end
switch(inputstr(pos))
    case '"',[val,pos,index_esc] = parseStr(inputstr, pos, esc, index_esc,varargin{:});     return;
    case '[',[val,pos,index_esc] = parse_array(inputstr, pos, esc, index_esc, varargin{:}); return;
    case '{',[val,pos,index_esc] = parse_object(inputstr, pos, esc, index_esc, varargin{:});return;
    case {'-','0','1','2','3','4','5','6','7','8','9'}
        [     val,pos          ] = parse_number(inputstr, pos,                 varargin{:});return;
    case 't',if pos+3 <= len && strcmpi(inputstr(pos:pos+3), 'true'),val= true;pos=pos+4;return;end
    case 'f',if pos+4 <= len && strcmpi(inputstr(pos:pos+4),'false'),val=false;pos=pos+5;return;end
    case 'n',if pos+3 <= len && strcmpi(inputstr(pos:pos+3), 'null'),val=   [];pos=pos+4;return;end
end
pos=error_pos('Value expected at position %d',inputstr,pos);
end
function [object, pos, index_esc] = parse_object(inputstr, pos, esc, index_esc, varargin)
pos=parse_char(inputstr, pos, '{');usemap=varargin{1}.usemap;
if(usemap),object = eval('containers.Map()');else,object = [];end
[cc,pos]=next_char(inputstr,pos);
if cc ~= '}'
    while 1
        [str, pos, index_esc] = parseStr(inputstr, pos, esc, index_esc, varargin{:});
        if isempty(str),pos=error_pos('Name of value at position %d cannot be empty',inputstr,pos);
        end
        pos=parse_char(inputstr, pos, ':');
        [val, pos,index_esc] = parse_value(inputstr, pos, esc, index_esc, varargin{:});
        if(usemap),object(str)=val;else,object.(encodevarname(str,varargin{:}))=val;end
        [cc,pos]=next_char(inputstr,pos);if cc == '}',break;end,pos=parse_char(inputstr,pos,',');
    end
end
pos=parse_char(inputstr, pos, '}');
end
function pos=error_pos(msg, inputstr, pos)
poShow = max(min([pos-15 pos-1 pos pos+20],length(inputstr)),1);
if poShow(3) == poShow(2),poShow(3:4) = poShow(2)+[0 -1];end % display nothing after
msg=[sprintf(msg, pos) ': ' inputstr(poShow(1):poShow(2)) '<error>' inputstr(poShow(3):poShow(4))];
error( ['JSONLAB:JSON:InvalidFormat: ' msg] );
end
function newpos=skip_whitespace(pos, inputstr)
newpos=pos;while newpos <= length(inputstr) && isspace(inputstr(newpos)),newpos = newpos + 1;end
end
function newstr=unescapejsonstring(str)
newstr=str;
if(iscell(str))
    try c=cell(numel(str),1);for n=1:numel(c),c{n}=cell2mat(str{n});end,newstr=cell2mat(c);
    catch,end
end
if(~ischar(str)),return;end,escapechars={'\\','\"','\/','\a','\b','\f','\n','\r','\t','\v'};
for i=1:length(escapechars)
    newstr=regexprep(newstr,regexprep(escapechars{i},'\\','\\\\'), escapechars{i});
end
newstr=regexprep(newstr,'\\u([0-9A-Fa-f]{4})', '${char(base2dec($1,16))}');
end
function arraystr=sscanf_prep(str)
arraystr=str;
if(regexp(str,'"','once'))
    arraystr=regexprep(arraystr,'"_NaN_"','NaN');
    arraystr=regexprep(arraystr,'"([-+]*)_Inf_"','$1Inf');
end
arraystr(arraystr==sprintf('\n'))=[];arraystr(arraystr==sprintf('\r'))=[]; %#ok<SPRINTFN>
end
function [obj, nextidx,nextdim]=parse2darray(inputstr,startpos,arraystr)
rowend=match_bracket(inputstr,startpos);rowstr=sscanf_prep(inputstr(startpos-1:rowend));
[vec1, nextdim, errmsg, nextidx]=sscanf(rowstr,'%f,',[1 inf]); %#ok<ASGLU>
if(nargin==2),obj=nextdim;return;end
astr=arraystr;astr(astr=='[')='';astr(astr==']')='';astr=regexprep(deblank(astr),'\s+,',',');
[obj, count, errmsg, nextidx]=sscanf(astr,'%f,',inf); %#ok<ASGLU>
if(nextidx>=length(astr)-1)
    obj=reshape(obj,nextdim,numel(obj)/nextdim);nextidx=length(arraystr)+1;
end
end
function opt=varargin2struct(varargin)
len=length(varargin);opt=struct;if(len==0),return;end
i=1;
while(i<=len)
    if(isstruct(varargin{i})),opt=mergestruct(opt,varargin{i});
    elseif(ischar(varargin{i}) && i<len),opt.(lower(varargin{i}))=varargin{i+1};i=i+1;
    else,error('input must be in the form of ...,''name'',value,... pairs or structs');
    end
    i=i+1;
end
end
function val=jsonopt(key,default,varargin)
val=default;if(nargin<=2),return;end,key0=lower(key);opt=varargin{1};
if isstruct(opt),if isfield(opt,key0),val=opt.(key0);elseif isfield(opt,key),val=opt.(key);end,end
end
function str = encodevarname(str,varargin)
if(~isvarname(str(1))),str=sprintf('x0x%X_%s',char(str(1))+0,str(2:end));end
if(isvarname(str)),return;end
if(exist('unicode2native','builtin'))
    str=regexprep(str,'([^0-9A-Za-z_])','_0x${sprintf(''%X'',unicode2native($1))}_');
else
    cpos=regexp(str,'[^0-9A-Za-z_]');if(isempty(cpos)),return;end
    str0=str;pos0=[0 cpos(:)' length(str)];str='';
    for i=1:length(cpos)
        str=[str str0(pos0(i)+1:cpos(i)-1) sprintf('_0x%X_',str0(cpos(i))+0)]; %#ok<AGROW>
    end
    if(cpos(end)~=length(str)),str=[str str0(pos0(end-1)+1:pos0(end))];end
end
end
function newdata=jdatadecode(data,varargin)
newdata=data;opt=struct;
if(nargin==2),opt=varargin{1};elseif(nargin>2),opt=varargin2struct(varargin{:});end
opt.fullarrayshape=jsonopt('FullArrayShape',0,opt);
% process non-structure inputs
if(~isstruct(data))
    if(iscell(data))
        newdata=cell(size(data));for n=1:numel(data),newdata{n}=jdatadecode(data{n},opt);end
    elseif(isa(data,'containers.Map'))
        newdata=containers.Map('KeyType',data.KeyType,'ValueType','any');names=data.keys;
        for i=1:length(names),newdata(names{i})=jdatadecode(data(names{i}),opt);end
    end
    return;
end
% assume the input is a struct below
fn=fieldnames(data);len=length(data);needbase64=jsonopt('Base64',0,opt);
format=jsonopt('FormatVersion',2,opt);
persistent isOctave,if isempty(isOctave),isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;end
if(isOctave),prefix(jsonopt('Prefix','',opt));
else        ,prefix(jsonopt('Prefix','x0x5F',opt));
end
if(~isfield(data,N_('_ArrayType_'))&&isfield(data,'x_ArrayType_')),prefix('x');opt.prefix='x';end
% recursively process subfields
if(jsonopt('Recursive',1,opt)==1)
    for i=1:length(fn) % depth-first
        for j=1:len
            if(isstruct(data(j).(fn{i})) || isa(data(j).(fn{i}),'containers.Map'))
                newdata(j).(fn{i})=jdatadecode(data(j).(fn{i}),opt);
            elseif(iscell(data(j).(fn{i}))),x=newdata(j).(fn{i});
                for n=1:numel(x),x{n}=jdatadecode(x{n},opt);end,newdata(j).(fn{i})=x;
            end
        end
    end
end
% handle array data
if isfield(data,N_('_ArrayType_'))&&(isfield(data,N_('_ArrayData_'))||...
        isfield(data,N_('_ArrayZipData_'))),   newdata=cell(len,1);
    for j=1:len
        if(isfield(data,N_('_ArrayZipSize_')) && isfield(data,N_('_ArrayZipData_')))
            zipmethod='zip';
            if(isstruct(data(j).(N_('_ArrayZipSize_'))))
                data(j).(N_('_ArrayZipSize_'))=jdatadecode(data(j).(N_('_ArrayZipSize_')),opt);
            end
            dims=data(j).(N_('_ArrayZipSize_'))(:)';
            if(length(dims)==1),dims=[1 dims];end %#ok<AGROW>
            if(isfield(data,N_('_ArrayZipType_'))),zipmethod=data(j).(N_('_ArrayZipType_'));end
            if(ismember(zipmethod,{'zlib','gzip','lzma','lzip','lz4','lz4hc'}))
                decompfun=str2func([zipmethod 'decode']);arraytype=data(j).(N_('_ArrayType_'));
                chartype=0;
                if(strcmp(arraytype,'char') || strcmp(arraytype,'logical'))
                    chartype=1;arraytype='uint8';
                end
                x=data(j).(N_('_ArrayZipData_'));
                if(needbase64),ndata=reshape(typecast(decompfun(base64decode(x)),arraytype),dims);
                else,          ndata=reshape(typecast(decompfun(             x ),arraytype),dims);
                end,if(chartype),ndata=char(ndata);end
            else,error('compression method is not supported');
            end
        else
            d=data(j).(N_('_ArrayData_'));if(isstruct(d)),d=jdatadecode(d,opt);end
            if(isstruct(d)&&isfield(d,N_('_ArrayType_'))),d=jdatadecode(d,varargin{:});end
            if(iscell(d)),x=d;for n=1:numel(x),x{n}=double(x{n}(:));end,d=cell2mat(x).';end
            ndata=cast_wrapper(d,char(data(j).(N_('_ArrayType_'))));
        end
        if(isfield(data,N_('_ArrayZipSize_')))
            z=data(j).(N_('_ArrayZipSize_'));if(isstruct(z)),z=jdatadecode(z,opt);end
            data(j).(N_('_ArrayZipSize_'))=z;dims=z(:)';if(iscell(dims)),dims=cell2mat(dims);end
            if(length(dims)==1),dims=[1 dims];end %#ok<AGROW>
            ndata=reshape(ndata(:),fliplr(dims));ndata=permute(ndata,ndims(ndata):-1:1);
        end
        iscpx=0;
        if(isfield(data,N_('_ArrayIsComplex_')) && isstruct(data(j).(N_('_ArrayIsComplex_'))) )
            data(j).(N_('_ArrayIsComplex_'))=jdatadecode(data(j).(N_('_ArrayIsComplex_')),opt);
        end
        if(isfield(data,N_('_ArrayIsComplex_')) && data(j).(N_('_ArrayIsComplex_')) ),iscpx=1;end
        iscol=0;
        if(isfield(data,N_('_ArrayOrder_')))
            arrayorder=data(j).(N_('_ArrayOrder_'));
            if(~isempty(arrayorder) && (arrayorder(1)=='c' || arrayorder(1)=='C')),iscol=1;end
        end
        if(isfield(data,N_('_ArrayIsSparse_')) && isstruct(data(j).(N_('_ArrayIsSparse_'))) )
            data(j).(N_('_ArrayIsSparse_'))=jdatadecode(data(j).(N_('_ArrayIsSparse_')),opt);
        end
        if(isfield(data,N_('_ArrayIsSparse_')) && data(j).(N_('_ArrayIsSparse_')))
            if(isfield(data,N_('_ArraySize_')))
                if(isstruct(data(j).(N_('_ArraySize_'))))
                    data(j).(N_('_ArraySize_'))=jdatadecode(data(j).(N_('_ArraySize_')),opt);
                end
                dim=data(j).(N_('_ArraySize_'))(:)';if(iscell(dim)),dim=cell2mat(dim);end
                dim=double(dim);if(length(dim)==1),dim=[1 dim];end %#ok<AGROW>
                if(iscpx),ndata(end-1,:)=complex(ndata(end-1,:),ndata(end,:));end
                if isempty(ndata),ndata=sparse(dim(1),prod(dim(2:end)));
                elseif dim(1)==1,ndata=sparse(1,ndata(1,:),ndata(2,:),dim(1),prod(dim(2:end)));
                elseif dim(2)==1,ndata=sparse(ndata(1,:),1,ndata(2,:),dim(1),prod(dim(2:end)));
                else,ndata=sparse(ndata(1,:), ndata(2,:),  ndata(3,:),dim(1),prod(dim(2:end)));
                end
            else
                if(iscpx && size(ndata,2)==4),ndata(3,:)=complex(ndata(3,:),ndata(4,:));end
                ndata=sparse(ndata(1,:),ndata(2,:),ndata(3,:));
            end
        elseif(isfield(data,N_('_ArrayShape_')))
            if(isstruct(data(j).(N_('_ArrayShape_'))))
                data(j).(N_('_ArrayShape_'))=jdatadecode(data(j).(N_('_ArrayShape_')),opt);
            end
            if(iscpx)
                if(size(ndata,1)==2),dim=size(ndata);dim(end+1)=1; %#ok<AGROW>
                    arraydata=reshape(complex(ndata(1,:),ndata(2,:)),dim(2:end));
                else,error('The first dimension must be 2 for complex-valued arrays');
                end
            else,arraydata=data.(N_('_ArrayData_'));
            end
            shapeid=data.(N_('_ArrayShape_'));
            if(isfield(data,N_('_ArrayZipSize_')))
                datasize=data.(N_('_ArrayZipSize_'));
                if(iscell(datasize)),datasize=cell2mat(datasize);end,datasize=double(datasize);
                if(iscpx),datasize=datasize(2:end);end
            else,datasize=size(arraydata);
            end
            if(isstruct(data(j).(N_('_ArraySize_'))))
                data(j).(N_('_ArraySize_'))=jdatadecode(data(j).(N_('_ArraySize_')),opt);
            end
            arraysize=data.(N_('_ArraySize_'));
            
            if(iscell(arraysize)),arraysize=cell2mat(arraysize);end,arraysize=double(arraysize);
            if(ischar(shapeid)),shapeid={shapeid};end,arraydata=double(arraydata).';
            if(strcmpi(shapeid{1},'diag'))
                ndata=spdiags(arraydata(:),0,arraysize(1),arraysize(2));
            elseif(strcmpi(shapeid{1},'upper') || strcmpi(shapeid{1},'uppersymm'))
                ndata=zeros(arraysize);ndata(triu(true(size(ndata)))')=arraydata(:);
                if(strcmpi(shapeid{1},'uppersymm')),ndata(triu(true(size(ndata))))=arraydata(:);end
                ndata=ndata.';
            elseif(strcmpi(shapeid{1},'lower') || strcmpi(shapeid{1},'lowersymm'))
                ndata=zeros(arraysize);ndata(tril(true(size(ndata)))')=arraydata(:);
                if(strcmpi(shapeid{1},'lowersymm')),ndata(tril(true(size(ndata))))=arraydata(:);end
                ndata=ndata.';
            elseif(strcmpi(shapeid{1},'upperband') || strcmpi(shapeid{1},'uppersymmband'))
                if(length(shapeid)>1 && isvector(arraydata))
                    datasize=double([shapeid{2}+1, prod(datasize)/(shapeid{2}+1)]);
                end
                ndata=spdiags(reshape(arraydata,min(arraysize),datasize(1)),-datasize(1)+1:0,arraysize(2),arraysize(1)).';
                if(strcmpi(shapeid{1},'uppersymmband'))
                    diagonal=diag(ndata);ndata=ndata+ndata.';ndata(1:arraysize(1)+1:end)=diagonal;
                end
            elseif(strcmpi(shapeid{1},'lowerband') || strcmpi(shapeid{1},'lowersymmband'))
                if(length(shapeid)>1 && isvector(arraydata))
                    datasize=double([shapeid{2}+1, prod(datasize)/(shapeid{2}+1)]);
                end
                ndata=spdiags(reshape(arraydata,min(arraysize),datasize(1)),0:datasize(1)-1,arraysize(2),arraysize(1)).';
                if(strcmpi(shapeid{1},'lowersymmband'))
                    diagonal=diag(ndata);ndata=ndata+ndata.';ndata(1:arraysize(1)+1:end)=diagonal;
                end
            elseif(strcmpi(shapeid{1},'band'))
                if(length(shapeid)>1 && isvector(arraydata)),datasize=double(...
                        [shapeid{2}+shapeid{3}+1,prod(datasize)/(shapeid{2}+shapeid{3}+1)]);
                end
                ndata=spdiags(reshape(arraydata,min(arraysize),datasize(1)),...
                    double(shapeid{2}):-1:-double(shapeid{3}),arraysize(1),arraysize(2));
            elseif(strcmpi(shapeid{1},'toeplitz'))
                arraydata=reshape(arraydata,flipud(datasize(:))');
                ndata=toeplitz(arraydata(1:arraysize(1),2),arraydata(1:arraysize(2),1));
            end
            if(opt.fullarrayshape && issparse(ndata))
                ndata=cast_wrapper(full(ndata),data(j).(N_('_ArrayType_')));
            end
        elseif(isfield(data,N_('_ArraySize_')))
            if(isstruct(data(j).(N_('_ArraySize_'))))
                data(j).(N_('_ArraySize_'))=jdatadecode(data(j).(N_('_ArraySize_')),opt);
            end
            if(iscpx),ndata=complex(ndata(1,:),ndata(2,:));end
            if(format>1.9 && iscol==0)
                data(j).(N_('_ArraySize_'))=data(j).(N_('_ArraySize_'))(end:-1:1);
            end
            dims=data(j).(N_('_ArraySize_'))(:)';if(iscell(dims)),dims=cell2mat(dims);end
            if(length(dims)==1),dims=[1 dims];end,ndata=reshape(ndata(:),dims(:)'); %#ok<AGROW>
            if(format>1.9 && iscol==0),ndata=permute(ndata,ndims(ndata):-1:1);end
        end
        newdata{j}=ndata;
    end
    if(len==1),newdata=newdata{1};end
end
% handle table data
if(isfield(data,N_('_TableRecords_')))
    newdata=cell(len,1);
    for j=1:len
        ndata=data(j).(N_('_TableRecords_'));
        if(iscell(ndata))
            if iscell(ndata{1}),rownum=length(ndata);colnum=length(ndata{1});nd=cell(rownum,colnum);
                for i1=1:rownum,for i2=1:colnum,nd{i1,i2}=ndata{i1}{i2};end,end
                newdata{j}=cell2table(nd);
            else,newdata{j}=cell2table(ndata);
            end
        else,newdata{j}=array2table(ndata);
        end
        if(isfield(data(j),N_('_TableRows_'))&& ~isempty(data(j).(N_('_TableRows_'))))
            newdata{j}.Properties.RowNames=data(j).(N_('_TableRows_'))(:);
        end
        if(isfield(data(j),N_('_TableCols_')) && ~isempty(data(j).(N_('_TableCols_'))))
            newdata{j}.Properties.VariableNames=data(j).(N_('_TableCols_'));
        end
    end
    if(len==1),newdata=newdata{1};end
end
% handle map data
if(isfield(data,N_('_MapData_')))
    newdata=cell(len,1);
    for j=1:len
        key=cell(1,length(data(j).(N_('_MapData_'))));val=cell(size(key));
        for k=1:length(data(j).(N_('_MapData_')))
            key{k}=data(j).(N_('_MapData_')){k}{1};
            val{k}=jdatadecode(data(j).(N_('_MapData_')){k}{2},opt);
        end
        ndata=containers.Map(key,val);newdata{j}=ndata;
    end
    if(len==1),newdata=newdata{1};end
end

% handle graph data
if(isfield(data,N_('_GraphNodes_')) && exist('graph','file') && exist('digraph','file'))
    newdata=cell(len,1);isdirected=1;
    for j=1:len
        nodedata=data(j).(N_('_GraphNodes_'));
        if(isstruct(nodedata))                ,nodetable=struct2table(nodedata);
        elseif(isa(nodedata,'containers.Map')),nodetable=[keys(nodedata);values(nodedata)];
            if(strcmp(nodedata.KeyType,'char'))
                nodetable=table(nodetable(1,:)',nodetable(2,:)','VariableNames',{'Name','Data'});
            else,nodetable=table(nodetable(2,:)','VariableNames',{'Data'});
            end
        else,nodetable=table;
        end
        edgedata_doesnt_exist=false;
        if(isfield(data,N_('_GraphEdges_')))     ,edgedata=data(j).(N_('_GraphEdges_'));
        elseif(isfield(data,N_('_GraphEdges0_'))),edgedata=data(j).(N_('_GraphEdges0_'));
            isdirected=0;
        elseif(isfield(data,N_('_GraphMatrix_')))
            edgedata=jdatadecode(data(j).(N_('_GraphMatrix_')),varargin{:});
        else,edgedata_doesnt_exist=true;
        end
        if(edgedata_doesnt_exist)
            if(iscell(edgedata))
                endnodes=edgedata(:,1:2);endnodes=reshape([endnodes{:}],size(edgedata,1),2);
                weight=cell2mat(edgedata(:,3:end));
                edgetable=table(endnodes,[weight.Weight]','VariableNames',{'EndNodes','Weight'});
                if(isdirected),newdata{j}=digraph(edgetable,nodetable);
                else,          newdata{j}=  graph(edgetable,nodetable);
                end
            elseif(ndims(edgedata)==2 && isstruct(nodetable)) %#ok<ISMAT>
                newdata{j}=digraph(edgedata,fieldnames(nodetable));
            end
        end
    end
    if(len==1),newdata=newdata{1};end
end
% handle bytestream and arbitrary matlab objects
if(isfield(data,N_('_ByteStream_')) && isfield(data,N_('_DataInfo_'))==2)
    newdata=cell(len,1);
    for j=1:len
        if(isfield(data(j).(N_('_DataInfo_')),'MATLABObjectClass'))
            if(needbase64)
                newdata{ j}=getArrayFromByteStream(base64decode(data(j).(N_('_ByteStream_'))));
            else,newdata{j}=getArrayFromByteStream(             data(j).(N_('_ByteStream_')));
            end
        end
    end
    if(len==1),newdata=newdata{1};end
end
end
function escaped=N_(str),escaped=[prefix str];end
function prefix_=prefix(set_value),persistent prefix__,if nargin>0,prefix__=[];end
if isempty(prefix__) && isa(prefix__,'double'),prefix__=set_value;end,prefix_=prefix__;
end
function out=cast_wrapper(data,type)
try tf=isempty(which(func2str(@cast)));catch,tf=true;end
if tf,out=eval([type '(' loadjson_local_var2str(data) ')']);else ,out=cast(data,type);end
end
function out=loadjson_local_var2str(varargin),out=inputname(1);end