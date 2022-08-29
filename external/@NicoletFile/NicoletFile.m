classdef NicoletFile < handle
    % NICOLETFILE  Reading Nicolet .e files.
    %
    %   GETTING DATA
    %   You can load data from the .e file using the GETDATA method. The
    %   inputs to the method are the object, the segment of the data file
    %   that you want to load data from, the min, and max index you want to
    %   retrieve, and a vector of channels that you want to retrieve.
    %
    %   Example:
    %     OUT = GETDATA(OBJ, 1, [1 1000], 1:10) will return the first 1000
    %     values on the first 10 channels of the first segment of the file.
    %
    %   GETTING Nr OF SAMPLES
    %     Use the GETNRSAMPLES method to find the number of samples per
    %     channel in each data segment.
    %
    %   WARNING!
    %   The .e format allows for changes in the TimeSeries map during the
    %   recording. This results in multiple TSINFO structures. Depending on
    %   where these structures are located in the .e file, the appropriate
    %   TSINFO structure should be used. However, there seems to be a bug in
    %   the Nicolet .e file writer which sometimes renders the TSINFO structures
    %   unreadable on disk (verify with hex-edit). Therefore, this class only
    %   uses the first TSINFO structure found in the .e file.
    %
    %
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright 2013 Trustees of the University of Pennsylvania
    %
    % Licensed under the Apache License, Version 2.0 (the "License");
    % you may not use this file except in compliance with the License.
    % You may obtain a copy of the License at
    %
    % http://www.apache.org/licenses/LICENSE-2.0
    %
    % Unless required by applicable law or agreed to in writing, software
    % distributed under the License is distributed on an "AS IS" BASIS,
    % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    % See the License for the specific language governing permissions and
    % limitations under the License.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Joost Wagenaar, Jan 2015
    % Cristian Donos, Dec 2015
    % Jan Brogger, Jun 2016
    
    properties
        fileName
        patientInfo
        segments
        eventMarkers
    end
    
    properties (Hidden)
        sections
        index
        sigInfo
        tsInfo
        chInfo
        notchFreq
        montage
        Qi
        Qii
        allIndexIDs
        useTSinfoIdx = 1
    end
    
    properties (Constant, Hidden)
        LABELSIZE = 32
        TSLABELSIZE = 64
        UNITSIZE = 16
        ITEMNAMESIZE  = 64
    end
    
    methods
        function obj = NicoletFile(filename)
            
            % validate filename input
            [folder,~,ext] = fileparts(filename);
            assert(strcmp(ext,'.e'), 'File extention must be .e');
            if isempty(folder)
                filename = fullfile(pwd,filename);
            end
            assert(exist(filename,'file')==2,'Could not find file "%s"',filename);
            obj.fileName = filename;
            h = fopen(filename,'r','ieee-le');
            try
                
                % Read out byte location of main index
                fseek(h,24,'bof');
                indexByteLocation = fread(h,1,'uint32');
                
                % Get TAGS structure and Channel IDS
                fseek(h,172,'bof');
                nrTags = fread(h,1,'uint32');
                obj.sections = struct();
                for ii=1:nrTags
                    obj.sections(ii).tag = NicoletFile.getchars(h,40,'uint16');
                    obj.sections(ii).index = fread(h,1,'uint32');
                    switch obj.sections(ii).tag
                        case 'ExtraDataTags'
                            obj.sections(ii).IDStr = 'ExtraDataTags';
                        case 'SegmentStream'
                            obj.sections(ii).IDStr = 'SegmentStream';
                        case 'DataStream'
                            obj.sections(ii).IDStr = 'DataStream';
                        case 'InfoChangeStream'
                            obj.sections(ii).IDStr = 'InfoChangeStream';
                        case 'InfoGuids'
                            obj.sections(ii).IDStr = 'InfoGuids';
                        case '{A271CCCB-515D-4590-B6A1-DC170C8D6EE2}'
                            obj.sections(ii).IDStr = 'TSGUID';
                        case '{8A19AA48-BEA0-40D5-B89F-667FC578D635}'
                            obj.sections(ii).IDStr = 'DERIVATIONGUID';
                        case '{F824D60C-995E-4D94-9578-893C755ECB99}'
                            obj.sections(ii).IDStr = 'FILTERGUID';
                        case '{02950361-35BB-4A22-9F0B-C78AAA5DB094}'
                            obj.sections(ii).IDStr = 'DISPLAYGUID';
                        case '{8E94EF21-70F5-11D3-8F72-00105A9AFD56}'
                            obj.sections(ii).IDStr = 'FILEINFOGUID';
                        case '{E4138BC0-7733-11D3-8685-0050044DAAB1}'
                            obj.sections(ii).IDStr = 'SRINFOGUID';
                        case '{C728E565-E5A0-4419-93D2-F6CFC69F3B8F}'
                            obj.sections(ii).IDStr = 'EVENTTYPEINFOGUID';
                        case '{D01B34A0-9DBD-11D3-93D3-00500400C148}'
                            obj.sections(ii).IDStr = 'AUDIOINFOGUID';
                        case '{BF7C95EF-6C3B-4E70-9E11-779BFFF58EA7}'
                            obj.sections(ii).IDStr = 'CHANNELGUID';
                        case '{2DEB82A1-D15F-4770-A4A4-CF03815F52DE}'
                            obj.sections(ii).IDStr = 'INPUTGUID';
                        case '{5B036022-2EDC-465F-86EC-C0A4AB1A7A91}'
                            obj.sections(ii).IDStr = 'INPUTSETTINGSGUID';
                        case '{99A636F2-51F7-4B9D-9569-C7D45058431A}'
                            obj.sections(ii).IDStr = 'PHOTICGUID';
                        case '{55C5E044-5541-4594-9E35-5B3004EF7647}'
                            obj.sections(ii).IDStr = 'ERRORGUID';
                        case '{223A3CA0-B5AC-43FB-B0A8-74CF8752BDBE}'
                            obj.sections(ii).IDStr = 'VIDEOGUID';
                        case '{0623B545-38BE-4939-B9D0-55F5E241278D}'
                            obj.sections(ii).IDStr = 'DETECTIONPARAMSGUID';
                        case '{CE06297D-D9D6-4E4B-8EAC-305EA1243EAB}'
                            obj.sections(ii).IDStr = 'PAGEGUID';
                        case '{782B34E8-8E51-4BB9-9701-3227BB882A23}'
                            obj.sections(ii).IDStr = 'ACCINFOGUID';
                        case '{3A6E8546-D144-4B55-A2C7-40DF579ED11E}'
                            obj.sections(ii).IDStr = 'RECCTRLGUID';
                        case '{D046F2B0-5130-41B1-ABD7-38C12B32FAC3}'
                            obj.sections(ii).IDStr = 'GUID TRENDINFOGUID';
                        case '{CBEBA8E6-1CDA-4509-B6C2-6AC2EA7DB8F8}'
                            obj.sections(ii).IDStr = 'HWINFOGUID';
                        case '{E11C4CBA-0753-4655-A1E9-2B2309D1545B}'
                            obj.sections(ii).IDStr = 'VIDEOSYNCGUID';
                        case '{B9344241-7AC1-42B5-BE9B-B7AFA16CBFA5}'
                            obj.sections(ii).IDStr = 'SLEEPSCOREINFOGUID';
                        case '{15B41C32-0294-440E-ADFF-DD8B61C8B5AE}'
                            obj.sections(ii).IDStr = 'FOURIERSETTINGSGUID';
                        case '{024FA81F-6A83-43C8-8C82-241A5501F0A1}'
                            obj.sections(ii).IDStr = 'SPECTRUMGUID';
                        case '{8032E68A-EA3E-42E8-893E-6E93C59ED515}'
                            obj.sections(ii).IDStr = 'SIGNALINFOGUID';
                        case '{30950D98-C39C-4352-AF3E-CB17D5B93DED}'
                            obj.sections(ii).IDStr = 'SENSORINFOGUID';
                        case '{F5D39CD3-A340-4172-A1A3-78B2CDBCCB9F}'
                            obj.sections(ii).IDStr = 'DERIVEDSIGNALINFOGUID';
                        case '{969FBB89-EE8E-4501-AD40-FB5A448BC4F9}'
                            obj.sections(ii).IDStr = 'ARTIFACTINFOGUID';
                        case '{02948284-17EC-4538-A7FA-8E18BD65E167}'
                            obj.sections(ii).IDStr = 'STUDYINFOGUID';
                        case '{D0B3FD0B-49D9-4BF0-8929-296DE5A55910}'
                            obj.sections(ii).IDStr = 'PATIENTINFOGUID';
                        case '{7842FEF5-A686-459D-8196-769FC0AD99B3}'
                            obj.sections(ii).IDStr = 'DOCUMENTINFOGUID';
                        case '{BCDAEE87-2496-4DF4-B07C-8B4E31E3C495}'
                            obj.sections(ii).IDStr = 'USERSINFOGUID';
                        case '{B799F680-72A4-11D3-93D3-00500400C148}'
                            obj.sections(ii).IDStr = 'EVENTGUID';
                        case '{AF2B3281-7FCE-11D2-B2DE-00104B6FC652}'
                            obj.sections(ii).IDStr = 'SHORTSAMPLESGUID';
                        case '{89A091B3-972E-4DA2-9266-261B186302A9}'
                            obj.sections(ii).IDStr = 'DELAYLINESAMPLESGUID';
                        case '{291E2381-B3B4-44D1-BB77-8CF5C24420D7}'
                            obj.sections(ii).IDStr = 'GENERALSAMPLESGUID';
                        case '{5F11C628-FCCC-4FDD-B429-5EC94CB3AFEB}'
                            obj.sections(ii).IDStr = 'FILTERSAMPLESGUID';
                        case '{728087F8-73E1-44D1-8882-C770976478A2}'
                            obj.sections(ii).IDStr = 'DATEXDATAGUID';
                        case '{35F356D9-0F1C-4DFE-8286-D3DB3346FD75}'
                            obj.sections(ii).IDStr = 'TESTINFOGUID';
                        otherwise
                            if all(isstrprop(obj.sections(ii).tag, 'digit'))
                                obj.sections(ii).IDStr = obj.sections(ii).tag;
                            else
                                obj.sections(ii).IDStr = 'UNKNOWN';
                            end
                    end
                end
                
                %% QI index
                fseek(h, 172208,'bof');
                obj.Qi = struct();
                obj.Qi.nrEntries = fread(h,1,'uint32');
                obj.Qi.misc1 = fread(h,1,'uint32');
                obj.Qi.indexIdx = fread(h,1,'uint32');
                obj.Qi.misc3 = fread(h,1,'uint32');
                obj.Qi.LQi = fread(h,1,'uint64')';
                obj.Qi.firstIdx = fread(h,nrTags,'uint64');
                
                % Don't know what this index is for... Not required to get data and
                % can be huge...
                
                %       fseek(h, 188664,'bof');
                %       Qindex  = struct();
                %       for i = 1:obj.Qi.LQi
                %         Qindex(i).ftel = ftell(h);
                %         Qindex(i).index = fread(h,2,'uint16')';  %4
                %         Qindex(i).misc1 = fread(h,1,'uint32');   %8
                %         Qindex(i).indexIdx = fread(h,1,'uint32'); %12
                %         Qindex(i).misc2 = fread(h,3,'uint32')'; %24
                %         Qindex(i).sectionIdx = fread(h,1,'uint32');%28
                %         Qindex(i).misc3 = fread(h,1,'uint32'); %32
                %         Qindex(i).offset = fread(h,1,'uint64'); % 40
                %         Qindex(i).blockL = fread(h,1,'uint32');%44
                %         Qindex(i).dataL = fread(h,1,'uint32')';%48
                %       end
                %       obj.Qi.index = Qindex;
                
                %% Get Main Index:
                % Index consists of multiple blocks, after each block is the pointer
                % to the next block. Total number of entries is in obj.Qi.nrEntries
                %obj.index = struct('sectionIdx',{},'offset',{},'blockL',{},'sectionL',{});
                numIndexProcessed = 0;
                currByteLocation = indexByteLocation;
                curr=1;
                localIndex = cell(1,1000);
                while numIndexProcessed < obj.Qi.nrEntries
                    
                    % read out as uint32s and use typecast/cast
                    % this approach tested faster against (1) reading blocks of
                    % uint64, uint32 and doing separate conversions; (2)
                    % reading out uint64s and doing the typecast/cast
                    fseek(h,currByteLocation,'bof');
                    numIndexInBlock = fread(h,1, 'uint64');
                    bytes = fread(h,[6 numIndexInBlock],'*uint32');
                    sectionIdx = double(typecast(reshape(bytes(1:2,:),1,[]),'uint64'));
                    offset = double(typecast(reshape(bytes(3:4,:),1,[]),'uint64'));
                    blockL = double(bytes(5,:));
                    sectionL = double(bytes(6,:));
                    
                    % convert to cell arrays
                    sectionIdx = num2cell(sectionIdx);
                    offset = num2cell(offset);
                    blockL = num2cell(blockL);
                    sectionL = num2cell(sectionL);
                    
                    % create struct
                    assert(size(bytes,2)==numIndexInBlock,'Insufficient data (found %d entries but expected %d entries)',size(bytes,2),numIndexInBlock);
                    localIndex{curr} = struct(...
                        'sectionIdx',sectionIdx,...
                        'offset',offset,...
                        'blockL',blockL,... % pull out lower 32-bit uint from uint64 value
                        'sectionL',sectionL); % pull out upper 32-bit uint from uint64 value
                    
                    % update cell array pointer, and allocate more if needed
                    curr = curr+1;
                    if curr>1000,localIndex{curr+1000}=[];end
                    
                    % read out next byte location
                    currByteLocation = fread(h,1, 'uint64');
                    numIndexProcessed = numIndexProcessed + numIndexInBlock;
                end
                obj.index = cat(2,localIndex{:});
                obj.allIndexIDs = [obj.index.sectionIdx];
                
                %---READ DYNAMIC PACKETS---%
                % this section is weird! we find multiple index entries that
                % match the GUID of the dynamic packet, and supposedly treat
                % them as a contiguous block of data, but then end up reading
                % out less than one index's worth of data?
                dynamicPackets = struct();
                idxSection = strcmp({obj.sections.IDStr},'InfoChangeStream');
                assert(nnz(idxSection)==1,'Could not identify InfoChangeStream section (found %d matches)',nnz(idxSection));
                idxIndex = obj.sections(idxSection).index;
                offset = obj.index(idxIndex).offset;
                numDynamicPackets = obj.index(idxIndex).sectionL / 48;
                fseek(h, offset, 'bof');
                
                % Read first only the dynamic packets structure without actual data
                idx_guid_ordered = [4 3 2 1 6 5 8 7 9 10 11 12 13 14 15 16];
                for ii=1:numDynamicPackets
                    dynamicPackets(ii).offset = offset+ii*48; %warning('should this be (ii-1)?');
                    guid = fread(h,16, 'uint8')';
                    guid = guid(idx_guid_ordered);
                    dynamicPackets(ii).guid = num2str(guid, '%02X');
                    dynamicPackets(ii).guidAsStr = sprintf('{%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X}', guid);
                    dynamicPackets(ii).date = datenum(1899,12,31) + fread(h,1,'double');
                    dynamicPackets(ii).datefrac = fread(h,1,'double');
                    dynamicPackets(ii).internalOffsetStart = fread(h,1, 'uint64')';
                    dynamicPackets(ii).packetSize = fread(h,1, 'uint64')';
                    dynamicPackets(ii).data = zeros(0, 1,'uint8');
                    
                    switch dynamicPackets(ii).guid
                        case 'BF7C95EF6C3B4E709E11779BFFF58EA7'
                            dynamicPackets(ii).IDStr = 'CHANNELGUID';
                        case '8A19AA48BEA040D5B89F667FC578D635'
                            dynamicPackets(ii).IDStr = 'DERIVATIONGUID';
                        case 'F824D60C995E4D949578893C755ECB99'
                            dynamicPackets(ii).IDStr = 'FILTERGUID';
                        case '0295036135BB4A229F0BC78AAA5DB094'
                            dynamicPackets(ii).IDStr = 'DISPLAYGUID';
                        case '782B34E88E514BB997013227BB882A23'
                            dynamicPackets(ii).IDStr = 'ACCINFOGUID';
                        case 'A271CCCB515D4590B6A1DC170C8D6EE2'
                            dynamicPackets(ii).IDStr = 'TSGUID';
                        case 'D01B34A09DBD11D393D300500400C148'
                            dynamicPackets(ii).IDStr = 'AUDIOINFOGUID';
                        otherwise
                            dynamicPackets(ii).IDStr = 'UNKNOWN';
                    end
                end
                
                % read the actual data from the pointers above
                for ii=1:numDynamicPackets
                    
                    % get main index corresponding to GUID of dynamic packet
                    idxSection = strcmp({obj.sections.tag},dynamicPackets(ii).guidAsStr);
                    assert(nnz(idxSection)==1,'Could not identify section for GUID "%s" (found %d matching sections)',dynamicPackets(ii).guidAsStr,nnz(idxSection));
                    idxIndex = obj.allIndexIDs == obj.sections(idxSection).index;
                    assert(nnz(idxIndex)>0,'Could not find any index matching dynamic packet %d',ii);
                    localIndex = obj.index(idxIndex);
                    
                    % treat these sections as contiguous memory block
                    internalOffset = 0;
                    remainingDataToRead = dynamicPackets(ii).packetSize;
                    currentTargetStart = dynamicPackets(ii).internalOffsetStart;
                    for jj=1:length(localIndex)
                        currentInstance = localIndex(jj);
                        
                        if (internalOffset <= currentTargetStart) && (internalOffset+currentInstance.sectionL) >= currentTargetStart
                            
                            startAt = currentTargetStart;
                            stopAt =  min(startAt+remainingDataToRead, internalOffset+currentInstance.sectionL);
                            readLength = stopAt-startAt;
                            
                            filePosStart = currentInstance.offset+startAt-internalOffset;
                            fseek(h,filePosStart, 'bof');
                            dataPart = fread(h,readLength,'*uint8');
                            dynamicPackets(ii).data = cat(1, dynamicPackets(ii).data, dataPart);
                            
                            remainingDataToRead = remainingDataToRead-readLength;
                            currentTargetStart = currentTargetStart + readLength;
                        end
                        internalOffset = internalOffset + currentInstance.sectionL;
                    end
                end
                
                %% Get PatientGUID
                obj.patientInfo = struct();
                
                infoProps = { 'patientID', 'firstName','middleName','lastName',...
                    'altID','mothersMaidenName','DOB','DOD','street','sexID','phone',...
                    'notes','dominance','siteID','suffix','prefix','degree','apartment',...
                    'city','state','country','language','height','weight','race','religion',...
                    'maritalStatus'};
                
                idxSection = strcmp({obj.sections.IDStr},'PATIENTINFOGUID');
                assert(nnz(idxSection)==1,'Could not identify PATIENTINFOGUID section (found %d matching sections)',nnz(idxSection));
                idxIndex = obj.allIndexIDs==obj.sections(idxSection).index;
                assert(nnz(idxIndex)==1,'Could not identify index for patient information (found %d matching sections)',nnz(idxIndex));
                fseek(h,obj.index(idxIndex).offset,'bof');
                guid = fread(h, 16, 'uint8'); %#ok<NASGU>
                lSection = fread(h, 1, 'uint64'); %#ok<NASGU>
                nrValues = fread(h,1,'uint64');
                nrBstr = fread(h,1,'uint64');
                
                for ii = 1:nrValues
                    id = fread(h,1,'uint64');
                    switch id
                        case {7,8}
                            unix_time = (fread(h,1, 'double')*(3600*24)) - 2209161600;% 2208988800; %8
                            obj.segments(ii).dateStr = datestr(unix_time/86400 + datenum(1970,1,1));
                            value = datevec( obj.segments(ii).dateStr );
                            value = value([3 2 1]);
                        case {23,24}
                            value = fread(h,1,'double');
                        otherwise
                            value = 0;
                    end
                    obj.patientInfo.(infoProps{id}) = value;
                end
                strSetup = fread(h,nrBstr*2,'uint64');
                
                for ii=1:2:(nrBstr*2)
                    id  = strSetup(ii);
                    obj.patientInfo.(infoProps{id}) = NicoletFile.getchars(h,strSetup(ii+1)+1,'uint16');
                end
                
                %% Get INFOGUID
                % % Ignoring - just a list of GUIDS in file.
                % idxIndex = obj.sections(find(strcmp({obj.sections.IDStr},'InfoGuids'),1)).index;
                % indexInstance = obj.index(find([obj.index.sectionIdx]==idxIndex,1));
                % fseek(h, indexInstance.offset,'bof');
                
                %% Get SignalInfo (SIGNALINFOGUID): One per file
                idxSection = strcmp({obj.sections.IDStr},'SIGNALINFOGUID');
                assert(nnz(idxSection)==1,'Could not find SIGNALINFOGUID section (found %d matches)',nnz(idxSection));
                idxIndex = obj.allIndexIDs==obj.sections(idxSection).index;
                assert(nnz(idxIndex)>0,'Could not find any signal info indexes');
                indexInstance = obj.index(idxIndex);
                localSigInfo = cell(1,length(indexInstance));
                emptySigStruct = struct('sensorName',{},'transducer',{},'guid',{},'bBiPolar',{},'bAC',{},'bHighFilter',{},'color',{});
                for kk=1:length(indexInstance)
                    fseek(h,indexInstance(kk).offset,'bof');
                    
                    % not sure why we read these since they're never used...
                    SIG_struct = struct();
                    guid = fread(h, 16, '*uint8');
                    SIG_struct.guid = num2str(guid(:)','%02X');
                    SIG_struct.name = NicoletFile.getchars(h,obj.ITEMNAMESIZE,'char');
                    
                    % get signal info
                    unkown = NicoletFile.getchars(h,152,'char'); %#ok<NASGU>
                    fseek(h, 512, 'cof');
                    numIndexInBlock = fread(h,1, 'uint16');  %783
                    if numIndexInBlock<=0,continue;end
                    misc1 = fread(h,3, 'uint16'); %#ok<NASGU>
                    localSigInfo{kk} = emptySigStruct;
                    localSigInfo{kk}(numIndexInBlock).bAC = nan;
                    for ii=1:numIndexInBlock
                        localSigInfo{kk}(ii).sensorName = NicoletFile.getchars(h,obj.LABELSIZE,'uint16');
                        localSigInfo{kk}(ii).transducer = NicoletFile.getchars(h,obj.UNITSIZE,'uint16');
                        guid = fread(h,16,'*uint8');
                        localSigInfo{kk}(ii).guid = num2str(guid(:)','%02X');
                        localSigInfo{kk}(ii).bBiPolar = logical(fread(h,1,'uint32'));
                        localSigInfo{kk}(ii).bAC = logical(fread(h,1,'uint32'));
                        localSigInfo{kk}(ii).bHighFilter = logical(fread(h,1,'uint32'));
                        localSigInfo{kk}(ii).color =  fread(h,1,'uint32');
                        reserved = NicoletFile.getchars(h,256,'char'); %#ok<NASGU>
                    end
                end
                localSigInfo(cellfun(@isempty,localSigInfo)) = [];
                if length(localSigInfo)>1
                    len = cellfun(@length,localSigInfo);
                    idx_keep = len>1;
                    if any(~idx_keep),warning('Removing %d SIGINFOGUID datasets with length 1',nnz(~idx_keep));end
                    localSigInfo(~idx_keep) = [];
                end
                assert(length(localSigInfo)==1,'Found %d SIGINFOGUID datasets (expected 1)',length(localSigInfo));
                obj.sigInfo = localSigInfo{1};
                
                %% Get CHANNELINFO (CHANNELGUID)
                % what exactly is this information used for and how does it
                % relate to channel informaton read out in the segments?
                idxSection = strcmp({obj.sections.IDStr},'CHANNELGUID');
                assert(nnz(idxSection)==1,'Could not identify CHANNELGUID section (found %d matches)',nnz(idxSection));
                idxIndex = obj.allIndexIDs==obj.sections(idxSection).index;
                assert(nnz(idxIndex)>0,'Could not find any indexes matching the sensor section');
                indexInstance = obj.index(idxIndex);
                localChInfo = cell(1,length(indexInstance));
                for kk=1:length(indexInstance)
                    fseek(h, indexInstance(kk).offset,'bof');
                    CH_struct = struct();
                    guid = fread(h, 16, 'uint8');
                    CH_struct.guid = num2str(guid(:)','%02X');
                    CH_struct.name = NicoletFile.getchars(h,obj.ITEMNAMESIZE,'char');
                    fseek(h, 152, 'cof');
                    CH_struct.reserved = fread(h, 16, 'uint8');
                    CH_struct.deviceID = fread(h, 16, 'uint8');
                    fseek(h, 488, 'cof');
                
                    numIndexInBlock = fread(h,2, 'uint32');  %783
                    if numIndexInBlock(2)>2^12
                        warning('Processing only %d/%d CHANNELGUID entries for index %d/%d',2^12,numIndexInBlock(2),kk,length(indexInstance));
                        numIndexInBlock(2) = 2^12;
                    end
                    localChInfo{kk} = struct();
                    for ii=1:numIndexInBlock(2)
                        localChInfo{kk}(ii).sensor = NicoletFile.getchars(h,obj.LABELSIZE,'uint16');
                        localChInfo{kk}(ii).samplingRate = fread(h,1,'double');
                        localChInfo{kk}(ii).bOn = logical(fread(h,1,'uint32'));
                        localChInfo{kk}(ii).lInputID = fread(h,1,'uint32');
                        localChInfo{kk}(ii).lInputSettingID = fread(h,1,'uint32');
                        localChInfo{kk}(ii).reserved = NicoletFile.getchars(h,4,'char');
                        fseek(h, 128, 'cof');
                    end
                
                    numIndexProcessed = 0;
                    for ii=1:length(localChInfo{kk})
                        if localChInfo{kk}(ii).bOn
                            localChInfo{kk}(ii).indexID = numIndexProcessed;
                            numIndexProcessed = numIndexProcessed+1;
                        else
                            localChInfo{kk}(ii).indexID = -1;
                        end
                    end
                    if all([localChInfo{kk}.indexID]==-1)
                        localChInfo{kk} = [];
                    end
                end
                localChInfo(cellfun(@isempty,localChInfo)) = [];
                assert(~isempty(localChInfo),'No channel info remaining');
                warning('Found %d CHANNELGUID datasets (ignoring everything except the first one)',length(localChInfo));
                obj.chInfo = localChInfo{1};
                
                %% Get Segments
                % NOTE FROM ORIGINAL FILE: Get TS info (TSGUID):(One per segment, last used if no new for segment)
                tsPackets = dynamicPackets(strcmp({dynamicPackets.IDStr},'TSGUID'));
                idxSection = strcmp({obj.sections.IDStr}, 'SegmentStream');
                assert(nnz(idxSection)==1,'Could not identify SegmentStream section (found %d matches)',nnz(idxSection));
                idxIndex = obj.allIndexIDs == obj.sections(idxSection).index;
                assert(nnz(idxIndex)==1,'Could not identify index (found %d matches)',nnz(idxIndex));
                localIndex = obj.index(idxIndex);
                numSegments = localIndex.sectionL/152;
                fseek(h, localIndex.offset,'bof');
                obj.segments = struct();
                for ii=1:numSegments
                    
                    % pull out date/time info
                    dateOLE = fread(h,1, 'double');
                    obj.segments(ii).dateOLE = dateOLE;
                    unix_time = (dateOLE*(3600*24)) - 2209161600;% 2208988800; %8
                    obj.segments(ii).dateStr = datestr(unix_time/86400 + datenum(1970,1,1));
                    datev = datevec( obj.segments(ii).dateStr );
                    obj.segments(ii).startDate = datev(1:3);
                    obj.segments(ii).startTime = datev(4:6);
                    fseek(h, 8 , 'cof'); %16
                    obj.segments(ii).duration = fread(h,1, 'double');%24
                    fseek(h, 128 , 'cof'); %152
                    
                    % process TSINFO packets
                    if ii <= length(tsPackets)
                        tsPacket = tsPackets(ii);
                    else
                        tsPacket = tsPackets(end);
                    end
                    obj.tsInfo = struct();
                    elems = typecast(tsPacket.data(753:756),'uint32');
                    alloc = typecast(tsPacket.data(757:760),'uint32');
                    
                    offset = 761;
                    for nn=1:elems
                        internalOffset = 0;
                        obj.tsInfo(nn).label = deblank(char(typecast(tsPacket.data(offset:(offset+obj.TSLABELSIZE-1))','uint16')));
                        internalOffset = internalOffset + obj.TSLABELSIZE*2;
                        obj.tsInfo(nn).activeSensor = deblank(char(typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+obj.LABELSIZE))','uint16')));
                        internalOffset = internalOffset + obj.TSLABELSIZE;
                        obj.tsInfo(nn).refSensor = deblank(char(typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','uint16')));
                        internalOffset = internalOffset + 8;
                        internalOffset = internalOffset + 56;
                        obj.tsInfo(nn).dLowCut = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','double');
                        internalOffset = internalOffset + 8;
                        obj.tsInfo(nn).dHighCut = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','double');
                        internalOffset = internalOffset + 8;
                        obj.tsInfo(nn).dSamplingRate = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','double');
                        %warning('Should sampling rate be 512? (#2)');
                        % if ~any(strcmpi(obj.tsInfo(nn).label,{'EKG','Rate'}))
                        %     obj.tsInfo(nn).dSamplingRate = 512; % hard-code to 512 based on feedback from Angela at Rancho Los Amigos National Rehabilitation Center
                        % end
                        internalOffset = internalOffset + 8;
                        obj.tsInfo(nn).dResolution = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','double');
                        internalOffset = internalOffset + 8;
                        obj.tsInfo(nn).bMark = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+2))','uint16');
                        internalOffset = internalOffset + 2;
                        obj.tsInfo(nn).bNotch = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+2))','uint16');
                        internalOffset = internalOffset + 2;
                        obj.tsInfo(nn).dEegOffset = typecast(tsPacket.data(offset+internalOffset:(offset+internalOffset-1+8))','double');
                        offset = offset + 552;
                    end
                    
                    % Add Channel Names to segments
                    obj.segments(ii).chName = {obj.tsInfo.label};
                    obj.segments(ii).refName = {obj.tsInfo.refSensor};
                    obj.segments(ii).samplingRate = [obj.tsInfo.dSamplingRate];
                    obj.segments(ii).scale = [obj.tsInfo.dResolution];
                end
                
                %% Get events  - Andrei Barborica, Dec 2015
                % header information
                ePktLen = 272;    % Event packet length, see EVENTPACKET definition
                eMrkLen = 240;    % Event marker length, see EVENTMARKER definition
                evtPktGUID = hex2dec({'80','F6','99','B7','A4','72','D3','11','93','D3','00','50','04','00','C1','48'}); % GUID for event packet header
                HCEVENT_ANNOTATION = '{A5A95612-A7F8-11CF-831A-0800091B5BDA}';
                HCEVENT_SEIZURE    =  '{A5A95646-A7F8-11CF-831A-0800091B5BDA}';
                HCEVENT_FORMATCHANGE      =  '{08784382-C765-11D3-90CE-00104B6F4F70}';
                HCEVENT_PHOTIC            =  '{6FF394DA-D1B8-46DA-B78F-866C67CF02AF}';
                HCEVENT_POSTHYPERVENT     =  '{481DFC97-013C-4BC5-A203-871B0375A519}';
                HCEVENT_REVIEWPROGRESS    =  '{725798BF-CD1C-4909-B793-6C7864C27AB7}';
                HCEVENT_EXAMSTART         =  '{96315D79-5C24-4A65-B334-E31A95088D55}';
                HCEVENT_HYPERVENTILATION  =  '{A5A95608-A7F8-11CF-831A-0800091B5BDA}';
                HCEVENT_IMPEDANCE         =  '{A5A95617-A7F8-11CF-831A-0800091B5BDA}';
                DAYSECS = 86400.0;  % From nrvdate.h
                
                % Find sequence of events, that are stored in the section tagged 'Events'
                idxSection = strcmp('Events',{obj.sections.tag});
                assert(nnz(idxSection)==1,'Could not identify Events section (found %d matches)',nnz(idxSection));
                indexByteLocation = obj.allIndexIDs == obj.sections(idxSection).index;
                offset = obj.index(indexByteLocation).offset;
                
                % read out event data
                fseek(h,offset,'bof');
                pktGUID = fread(h,16,'uint8');
                pktLen  = fread(h,1,'uint64');
                obj.eventMarkers = struct();
                ii = 0;    % Event counter
                while (pktGUID == evtPktGUID)
                    ii = ii + 1;
                    % Please refer to EVENTMARKER structure in the Nervus file documentation
                    fseek(h,8,'cof'); % Skip eventID, not used
                    evtDate = fread(h,1,'double');
                    evtDateFraction = fread(h,1,'double');
                    obj.eventMarkers(ii).dateOLE = evtDate;
                    obj.eventMarkers(ii).dateFraction = evtDateFraction;
                    evtPOSIXTime = evtDate*DAYSECS + evtDateFraction - 2209161600;% 2208988800; %8
                    obj.eventMarkers(ii).dateStr = datestr(evtPOSIXTime/DAYSECS + datenum(1970,1,1),'dd-mmmm-yyyy HH:MM:SS.FFF'); % Save fractions of seconds, as well
                    obj.eventMarkers(ii).duration  = fread(h,1,'double');
                    fseek(h,48,'cof');
                    obj.eventMarkers(ii).user = NicoletFile.getchars(h,12,'uint16');
                    evtTextLen = fread(h,1,'uint64');
                    evtGUID = fread(h,16,'uint8');
                    obj.eventMarkers(ii).GUID = sprintf('{%.2X%.2X%.2X%.2X-%.2X%.2X-%.2X%.2X-%.2X%.2X-%.2X%.2X%.2X%.2X%.2X%.2X}',evtGUID([4 3 2 1 6 5 8 7 9:16]));
                    fseek(h,16,'cof'); % Skip Reserved4 array
                    evtLabel = fread(h,32,'uint16'); % LABELSIZE = 32;
                    evtLabel = NicoletFile.getchars(h,32,'uint16'); % Not used
                    obj.eventMarkers(ii).label = evtLabel;
                    
                    % Only a subset of all event types are dealt with
                    switch obj.eventMarkers(ii).GUID
                        case HCEVENT_SEIZURE
                            obj.eventMarkers(ii).IDStr = 'Seizure';
                            %disp(' Seizure event');
                        case HCEVENT_ANNOTATION
                            obj.eventMarkers(ii).IDStr = 'Annotation';
                            fseek(h,32,'cof');    % Skip Reserved5 array
                            obj.eventMarkers(ii).annotation = NicoletFile.getchars(h,evtTextLen,'uint16');
                            %disp(sprintf(' Annotation:%s',evtAnnotation));
                        case HCEVENT_FORMATCHANGE
                            obj.eventMarkers(ii).IDStr = 'Format change';
                        case HCEVENT_PHOTIC
                            obj.eventMarkers(ii).IDStr = 'Photic';
                        case HCEVENT_POSTHYPERVENT
                            obj.eventMarkers(ii).IDStr = 'Posthyperventilation';
                        case HCEVENT_REVIEWPROGRESS
                            obj.eventMarkers(ii).IDStr = 'Review progress';
                        case HCEVENT_EXAMSTART
                            obj.eventMarkers(ii).IDStr = 'Exam start';
                        case HCEVENT_HYPERVENTILATION
                            obj.eventMarkers(ii).IDStr = 'Hyperventilation';
                        case HCEVENT_IMPEDANCE
                            obj.eventMarkers(ii).IDStr = 'Impedance';
                        otherwise
                            obj.eventMarkers(ii).IDStr = 'UNKNOWN';
                    end
                    
                    % Next packet
                    offset = offset + pktLen;
                    fseek(h,offset,'bof');
                    pktGUID = fread(h,16,'uint8');
                    pktLen  = fread(h,1,'uint64');
                end
                
                % %% Get montage  - Andrei Barborica, Dec 2015
                % % Derivation (montage)
                % idxSection = strcmp({obj.sections.IDStr},'DERIVATIONGUID');
                % assert(nnz(idxSection)==1,'Could not identify DERIVATIONGUID section (found %d matches)',nnz(idxSection));
                % idxIndex = obj.allIndexIDs==obj.sections(idxSection).index;
                % assert(nnz(idxIndex)>0,'Could not identify any montage indexes');
                % localInstance = obj.index(idxIndex);
                % mtgInfo = cell(1,length(localInstance));
                % for kk=1:length(localInstance)
                %     fseek(h,localInstance(kk).offset + 40,'bof'); % Beginning of current montage name
                %     mtgName = NicoletFile.getchars(h,32,'uint16');
                %     fseek(h,640,'cof'); % Number of traces in the montage
                %     numDerivations = fread(h,2,'uint32');
                %     if numDerivations(1)==0,continue;end
                %     if numDerivations(1)>128
                %         warning('Will process only 128/%d reported derivations for montage %d/%d (name "%s")',numDerivations(1),kk,length(localInstance),mtgName);
                %         numDerivations(1) = 128;
                %     end
                % 
                %     mtgInfo{kk} = struct();
                %     for ii=1:numDerivations(1)
                %         mtgInfo{kk}(ii).derivationName = NicoletFile.getchars(h,64,'uint16');
                %         mtgInfo{kk}(ii).signalName1 = NicoletFile.getchars(h,32,'uint16');
                %         mtgInfo{kk}(ii).signalName2 = NicoletFile.getchars(h,32,'uint16');
                %         fseek(h,264,'cof'); % Skip additional info
                %     end
                % end
                % mtgInfo(cellfun(@isempty,mtgInfo)) = [];
                % assert(length(mtgInfo)==1,'Found %d montage indexes, but expected only 1',length(mtgInfo));
                % obj.montage = mtgInfo{1};
                % 
                % %% Display properties
                % idxSection = strcmp({obj.sections.IDStr},'DISPLAYGUID');
                % assert(nnz(idxSection)==1,'Could not identify DISPLAYGUID section (found %d matches)',nnz(idxSection));
                % idxIndex = obj.allIndexIDs==obj.sections(idxSection).index;
                % assert(nnz(idxIndex)>0,'Could not find any indexes matching DISPLAYGUID section',nnz(idxIndex));
                % localInstance = obj.index(idxIndex);
                % mtgInfo = cell(1,length(localInstance));
                % for kk=1:length(localInstance)
                %     fseek(h,localInstance(kk).offset + 40,'bof'); % Beginning of current montage name
                %     displayName = NicoletFile.getchars(h,32,'uint16');
                %     fseek(h,640,'cof'); % Number of traces in the montage
                %     numTraces = fread(h,1,'uint32');
                %     numTraces2 = fread(h,1,'uint32');
                %     if numTraces==0,continue;end
                %     assert(numTraces==length(obj.montage),'Could not match montage derivations with display color table');
                % 
                %     mtgInfo{kk} = struct();
                %     for ii = 1:numTraces
                %         fseek(h,32,'cof');
                %         mtgInfo{kk}(ii).color = fread(h,1,'uint32'); % Use typecast(uint32(montage(i).color),'uint8') to convert to RGB array
                %         fseek(h,136-4,'cof');
                %     end
                % end
                % mtgInfo(cellfun(@isempty,mtgInfo)) = [];
                % assert(length(mtgInfo)==1,'Found %d color tables but expected only 1',length(mtgInfo));
                % for kk=1:length(obj.montage)
                %     obj.montage(kk).color = mtgInfo{1}(kk).color;
                % end
            catch ME
                fclose(h);
                rethrow(ME);
            end
            
            %% Close File
            fclose(h);
        end
        
        function out = getNrSamples(obj, segment)
            % GETNRSAMPLES  Returns the number of samples per channel in segment.
            %
            %   OUT = GETNRSAMPLES(OBJ, SEGMENT) returns a 1xn array of values
            %   indicating the number of samples for each of the channels in the
            %   associated SEGMENT, where SEGMENT is the index of the
            %   OBJ.segments array.
            
            assert(length(obj.segments)>= segment, ...
                'Incorrect SEGMENT argument; must be integer representing segment index.');
            
            out = obj.segments(segment).samplingRate .* obj.segments(segment).duration;
            
        end
        
        function out = getdata(this, segment, range, chIdx)
            % GETDATA  Returns data from Nicolet file.
            %
            %   OUT = GETDATA(OBJ, SEGMENT, RANGE, CHIDX) returns data in an nxm array of
            %   doubles where n is the number of datapoints and m is the number
            %   of channels. RANGE is a 1x2 array with the [StartIndex EndIndex]
            %   and CHIDX is a vector of channel indeces.
            
            try
                % Assert range is 1x2 vector
                assert(length(range) == 2, 'Range is [firstIndex lastIndex]');
                assert(length(segment) == 1, 'Segment must be single value.');
                
                % make sure chIdx is numerical, not logical
                if islogical(chIdx),chIdx=find(chIdx);end
                
                % make sure valid channel indices
                chIsValid = checkValidChannels(this,segment,chIdx);
                assert(all(chIsValid),'Only %d out of %d channels are valid',nnz(chIsValid),numel(chIsValid));
                unique_fs = unique(this.segments(segment).samplingRate(chIdx));
                assert(numel(unique_fs)==1,'Found multiple sampling rates: %s',util.vec2str(unique_fs));
                
                % Find sectionID for channels
                lChIdx = length(chIdx);
                sectionIdx = zeros(lChIdx,1);
                for ii=1:lChIdx
                    tmp = find(strcmp(num2str(chIdx(ii)-1),{this.sections.tag}),1);
                    sectionIdx(ii) = this.sections(tmp).index;
                end
                
                % Reopen .e file.
                h = fopen(this.fileName,'r','ieee-le');
                try
                    
                    % Iterate over all requested channels and populate array.
                    out = zeros(range(2) - range(1) + 1, lChIdx);
                    for ii=1:lChIdx
                        
                        % Get sampling rate for current channel
                        fs = this.segments(segment).samplingRate(chIdx(ii));
                        mult = this.segments(segment).scale(chIdx(ii));
                        
                        % Find segments containing this channel
                        idxInSegment = arrayfun(@(x)ismember(this.segments(segment).chName(chIdx(ii)),x.chName),this.segments);
                        segmentList = 1:length(this.segments);
                        segmentList = segmentList(idxInSegment);
                        newSegment = segmentList==segment;
                        
                        % Get cumulative sum segments.
                        cumulativeSegmentDuration = cumsum([this.segments(idxInSegment).duration]);
                        segmentStartSeconds = [0 cumulativeSegmentDuration(1:end-1)];
                        
                        % Find all sections
                        allSectionIdx = this.allIndexIDs == sectionIdx(ii);
                        allSections = find(allSectionIdx);
                        
                        % segment start/end info
                        segmentStartSamples = fs*segmentStartSeconds+1;
                        segmentEndSamples = fs*cumulativeSegmentDuration;
                        
                        % identify sections for the requested segment
                        % require both beginning and end of segment to be covered
                        % within the available sections
                        sectionLengthsInSamples = [this.index(allSections).sectionL]./2;
                        sectionStartSamples = [1 cumsum(sectionLengthsInSamples(1:end-1))+1];
                        sectionEndSamples = cumsum(sectionLengthsInSamples);
                        firstSectionForSegment = segmentStartSamples(newSegment)>=sectionStartSamples & segmentStartSamples(newSegment)<=sectionEndSamples;
                        lastSectionForSegment = segmentEndSamples(newSegment)>=sectionStartSamples & segmentEndSamples(newSegment)<=sectionEndSamples;
                        assert(nnz(firstSectionForSegment)==1 && nnz(lastSectionForSegment)==1, 'Could not identify section range for channel %d, segment %d',chIdx(ii),find(newSegment));
                        
                        % identify sections in that range for requested data
                        offsetSectionStartSamples = sectionStartSamples - sectionStartSamples(firstSectionForSegment) + 1;
                        assert(range(1)>=offsetSectionStartSamples(1),'Requested range starts prior to beginning of segment');
                        assert(range(2)<=(offsetSectionStartSamples(end)+sectionLengthsInSamples(end)),'Requested range ends after the end of the segment');
                        idxSections = find(offsetSectionStartSamples>=range(1) & offsetSectionStartSamples<=range(2));
                        assert(~isempty(idxSections),'Could not identify any sections containing the requested range %s for channel %d, segment %d',range,chIdx(ii),find(newSegment));
                        assert((diff(idxSections([1 end]))+1)<=(find(lastSectionForSegment)-find(firstSectionForSegment)+1),'Requested more sections than are available in the segment');
                        useSections = allSections(idxSections);
                        useSectionL = sectionLengthsInSamples(idxSections);
                        
                        % first (possibly partial) segment
                        fseek(h,this.index(useSections(1)).offset,'bof');
                        sampleStart = range(1) - offsetSectionStartSamples(idxSections(1)) + 1;
                        sampleEnd = min([range(2) useSectionL(1)]);
                        numSamplesToRead = sampleEnd-sampleStart + 1;
                        fseek(h,2*(sampleStart-1),'cof'); % 2 bytes each sample
                        tmp = fread(h,numSamplesToRead,'int16')*mult;
                        out(1:numSamplesToRead,ii) = tmp;
                        curIdx = 1;
                        curIdx = curIdx +  numSamplesToRead;
                        
                        % full segments
                        for jj=2:(length(useSections)-1)
                            curSec = this.index(useSections(jj));
                            %fprintf('Channel %d, bytes %d:%d\n',chIdx(ii),curSec.offset,curSec.offset+useSectionL(jj));
                            fseek(h, curSec.offset,'bof');
                            tmp = fread(h, useSectionL(jj), 'int16')*mult;
                            out(curIdx:(curIdx+useSectionL(jj)-1),ii) = tmp;
                            curIdx = curIdx+useSectionL(jj);
                        end
                        
                        % final partial segment
                        if length(useSections)>1
                            fseek(h, this.index(useSections(end)).offset,'bof');
                            tmp = fread(h,size(out,1)-curIdx + 1, 'int16')*mult;
                            out(curIdx:(curIdx+length(tmp)-1),ii) = tmp;
                        end
                    end
                catch ME
                    fclose(h);
                    rethrow(ME);
                end
                
                % Close the .e file.
                fclose(h);
            catch ME
                util.errorMessage(ME);
                keyboard
            end
        end % END function getdata
        
        function out = getdataQ(obj, segment, range, chIdx)
            % GETDATAQ  Returns data from Nicolet file. This is a "QUICK" version of getdata,
            % that uses more memory but operates faster on large datasets by reading
            % a single block of data from disk that contains all data of interest.
            %
            %   OUT = GETDATAQ(OBJ, SEGMENT, RANGE, CHIDX) returns data in an nxm array of
            %   doubles where n is the number of datapoints and m is the number
            %   of channels. RANGE is a 1x2 array with the [StartIndex EndIndex]
            %   and CHIDX is a vector of channel indeces.
            %
            % Andrei Barborica, Dec 2015
            %
            
            % Assert range is 1x2 vector
            assert(length(range) == 2, 'Range is [firstIndex lastIndex]');
            assert(length(segment) == 1, 'Segment must be single value.');
            
            % Get cumulative sum segments.
            cSumSegments = [0 cumsum([obj.segments.duration])];
            
            % Reopen .e file.
            h = fopen(obj.fileName,'r','ieee-le');
            
            % Find sectionID for channels
            lChIdx = length(chIdx);
            sectionIdx = zeros(lChIdx,1);
            for i = 1:lChIdx
                tmp = find(strcmp(num2str(chIdx(i)-1),{obj.sections.tag}),1);
                sectionIdx(i) = obj.sections(tmp).index;
            end
            
            usedIndexEntries = zeros(size([obj.index.offset]));
            
            % Iterate over all requested channels and populate array.
            out = zeros(range(2) - range(1) + 1, lChIdx);
            for i = 1 : lChIdx
                
                % Get sampling rate for current channel
                curSF = obj.segments(segment).samplingRate(chIdx(i));
                mult = obj.segments(segment).scale(chIdx(i));
                
                % Find all sections
                allSectionIdx = obj.allIndexIDs == sectionIdx(i);
                allSections = find(allSectionIdx);
                
                % Find relevant sections
                %warning('Should this be divided by 2 given that we doubled the sampling frequency (#2)?')
                sectionLengths = [obj.index(allSections).sectionL]./2;
                cSectionLengths = [0 cumsum(sectionLengths)];
                
                skipValues = cSumSegments(segment) * curSF;
                firstSectionForSegment = find(cSectionLengths > skipValues, 1) - 1 ;
                lastSectionForSegment = firstSectionForSegment + ...
                    find(cSectionLengths > curSF*obj.segments(segment).duration,1) - 2 ;
                
                if isempty(lastSectionForSegment)
                    lastSectionForSegment = length(cSectionLengths);
                end
                
                offsetSectionLengths = cSectionLengths - cSectionLengths(firstSectionForSegment);
                
                firstSection = find(offsetSectionLengths < range(1) ,1,'last');
                lastSection = find(offsetSectionLengths >= range(2),1)-1;
                
                if isempty(lastSection)
                    lastSection = length(offsetSectionLengths);
                end
                
                if lastSection > lastSectionForSegment
                    error('Index out of range for current section: %i > %i, on channel: %i', ...
                        range(2), cSectionLengths(lastSectionForSegment+1), chIdx(i));
                end
                
                useSections = allSections(firstSection: lastSection) ;
                useSectionL = sectionLengths(firstSection: lastSection) ;
                
                % First Partial Segment
                usedIndexEntries(useSections(1)) = 1;
                
                if length(useSections) > 1
                    % Full Segments
                    for j = 2: (length(useSections)-1)
                        usedIndexEntries(useSections(j)) = 1;
                    end
                    
                    % Final Partial Segment
                    usedIndexEntries(useSections(end)) = 1;
                end
                
            end
            
            % Read a big chunk of the file, containing data of interest.
            ix = find(usedIndexEntries);
            fseek(h, obj.index(ix(1)).offset,'bof');
            dsize =  obj.index(ix(end)).offset - obj.index(ix(1)).offset + obj.index(ix(end)).sectionL;
            tmp = fread(h,dsize/2,'int16').';
            
            % Close the .e file.
            fclose(h);
            
            baseOffset = obj.index(ix(1)).offset;
            
            % Extract specified channels
            for i = 1 : lChIdx
                
                % Get sampling rate for current channel
                curSF = obj.segments(segment).samplingRate(chIdx(i));
                mult = obj.segments(segment).scale(chIdx(i));
                
                % Find all sections
                allSectionIdx = obj.allIndexIDs == sectionIdx(i);
                allSections = find(allSectionIdx);
                
                % Find relevant sections
                %warning('Should this be divided by 2 given that we doubled the sampling frequency (#3)?')
                sectionLengths = [obj.index(allSections).sectionL]./2;
                cSectionLengths = [0 cumsum(sectionLengths)];
                
                skipValues = cSumSegments(segment) * curSF;
                firstSectionForSegment = find(cSectionLengths > skipValues, 1) - 1 ;
                lastSectionForSegment = firstSectionForSegment + ...
                    find(cSectionLengths > curSF*obj.segments(segment).duration,1) - 2 ;
                
                if isempty(lastSectionForSegment)
                    lastSectionForSegment = length(cSectionLengths);
                end
                
                offsetSectionLengths = cSectionLengths - cSectionLengths(firstSectionForSegment);
                
                firstSection = find(offsetSectionLengths < range(1) ,1,'last');
                lastSection = find(offsetSectionLengths >= range(2),1)-1;
                
                if isempty(lastSection)
                    lastSection = length(offsetSectionLengths);
                end
                
                if lastSection > lastSectionForSegment
                    error('Index out of range for current section: %i > %i, on channel: %i', ...
                        range(2), cSectionLengths(lastSectionForSegment+1), chIdx(i));
                end
                
                useSections = allSections(firstSection: lastSection) ;
                useSectionL = sectionLengths(firstSection: lastSection) ;
                
                % First Partial Segment
                curIdx = 1;
                curSec = obj.index(useSections(1));
                %fseek(h, curSec.offset,'bof');
                
                firstOffset = range(1) - offsetSectionLengths(firstSection);
                lastOffset = min([range(2) useSectionL(1)]);
                lsec = lastOffset-firstOffset + 1;
                
                out(1 : lsec,i) = tmp( (curSec.offset - baseOffset)/2 + (firstOffset-1) + (1:lsec) ) * mult;
                curIdx = curIdx +  lsec;
                
                if length(useSections) > 1
                    % Full Segments
                    for j = 2: (length(useSections)-1)
                        curSec = obj.index(useSections(j));
                        out(curIdx : (curIdx + useSectionL(j) - 1),i) = ...
                            tmp( (curSec.offset - baseOffset)/2 + (1:useSectionL(j)) ) * mult;
                        curIdx = curIdx +  useSectionL(j);
                    end
                    
                    % Final Partial Segment
                    curSec = obj.index(useSections(end));
                    out(curIdx : end,i) = tmp( (curSec.offset - baseOffset)/2 + (1:(length(out)-curIdx + 1)) ) * mult; % length(out) ??????
                end
            end
        end % END function getdataQ
        
        function labels = getlabels(obj,str)
            % Returns annotations containing specified string
            %
            % Cristian Donos, Dec 2015
            %
            labels=[]; counter = 1;
            for i = 1:length(obj.eventMarkers)
                if strfind(lower(obj.eventMarkers(i).annotation),lower(str))
                    labels{counter,1} = obj.eventMarkers(i).annotation;  % annotation string
                    labels{counter,2} = i;  % annotation index in obj.eventMarkers
                    % identify segment
                    time_vector = [];
                    for j = 1:length(obj.segments)
                        time_vector = [time_vector etime(datevec(obj.eventMarkers(i).dateStr),datevec(obj.segments(j).dateStr))];
                    end
                    labels{counter,3}= find(time_vector==min(time_vector(time_vector>0)));  % annotation part of this segment
                    labels{counter,4}= min(time_vector(time_vector>0));  % annotation offset in seconds, relative to its segment start
                    counter = counter+1;
                end
            end
        end
        
        function chIsValid = checkValidChannels(this,segment,chIdx)
            if islogical(chIdx),chIdx=find(chIdx);end
            
            % NOTE
            % I *think* that if a channel only appears in some segments,
            % then it's likely that we should only be counting time for the
            % segments in which it appears. Right now we count time
            % absolutely for all channels as though they should all be in
            % every segment.
            %
            % i.e. if a channel appears only in segment 12, then it
            % probably has enough sections to cover segment 12, not the
            % entire duration from segments 1-12.
            
            % Find sectionID for channels
            lChIdx = length(chIdx);
            
            % make sure valid channel indices
            chIsValid = true(1,lChIdx);
            for ii=1:lChIdx
                
                % Find segments containing this channel
                idxInSegment = arrayfun(@(x)ismember(this.segments(segment).chName(chIdx(ii)),x.chName),this.segments);
                segmentList = 1:length(this.segments);
                segmentList = segmentList(idxInSegment);
                newSegment = segmentList==segment;
                
                % Get cumulative sum segments.
                cumulativeSegmentDuration = cumsum([this.segments(idxInSegment).duration]);
                segmentStartSeconds = [0 cumulativeSegmentDuration(1:end-1)];
                
                % Find all sections
                idxTag = strcmp(num2str(chIdx(ii)-1),{this.sections.tag});
                assert(nnz(idxTag)==1,'Could not identify single match for channel %d in section tags (found %d matches)',chIdx(ii),nnz(idxTag));
                idx = this.allIndexIDs==this.sections(idxTag).index;
                
                % Get sampling rate for current channel
                fs = this.segments(segment).samplingRate(chIdx(ii));
                segmentStartSample = fs*segmentStartSeconds(newSegment)+1;
                segmentEndSample = fs*cumulativeSegmentDuration(newSegment);
                
                % identify sections for the requested segment
                % require both beginning and end of segment to be covered
                % within the available sections
                sectionLengthsInSamples = [this.index(idx).sectionL]./2;
                sectionStartSamples = [1 cumsum(sectionLengthsInSamples(1:end-1))+1];
                sectionEndSamples = cumsum(sectionLengthsInSamples);
                firstSectionForSegment = segmentStartSample>=sectionStartSamples & segmentStartSample<=sectionEndSamples;
                lastSectionForSegment = segmentEndSample>=sectionStartSamples & segmentEndSample<=sectionEndSamples;
                if nnz(firstSectionForSegment)==0 || nnz(lastSectionForSegment)==0
                    chIsValid(ii) = false;
                end
            end
        end % END function checkValidChannels
    end % END methods
    
    methods(Static)
        function c = getchars(h,num,type)
            c = '';
            try
                bytes = fread(h,num,sprintf('%s=>char',type))';
                idx_firstnonzero = find(bytes~=0,1,'first');
                idx_lastnonzero = find(bytes~=0,1,'last');
                if ~isempty(idx_firstnonzero) && ~isempty(idx_lastnonzero)
                    c = bytes(idx_firstnonzero:idx_lastnonzero);
                end
            catch ME
                util.errorMessage(ME);
            end
            if ~isempty(regexpi(c,'MOTOR'))
                %fprintf('%s\n',c);
            end
            if strcmpi(c,'1147D94E2101C1489D368A7BEA693701')
                %fprintf('Found GUI\n');
            end
        end % END function getchars
    end % END methods(Static)
end % END classdef NicoletFile
