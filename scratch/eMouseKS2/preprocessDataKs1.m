function [rez, DATA, uproj] = preprocessData(ops)
    tic;
    uproj = [];
    ops.nt0 	= getOr(ops, {'nt0'}, 61);

    % Channel map nChannels, connectedness, xcord, ycoord, kcoords
    % for each recording session:
    % Generate by calling configFiles/createChannelMap
    ops  = updateOpsWithChannelMap(ops);

    dataTypeBytes = ops.dataTypeBytes; %2; %int16 4=single
    dataTypeString = ops.dataTypeString; %'int16'; % int16,

    rez.ops = ops;
    rez.xc = ops.xc;
    rez.yc = ops.yc;
    rez.xcoords = ops.xcoords;
    rez.ycoords = ops.ycoords;
    rez.connected   = ops.connected;
    rez.ops.chanMap = ops.chanMap;
    rez.ops.kcoords = ops.kcoords;

    dataAdapter = DataAdapter.newDataAdapter(ops.recordingType, ops.fbinary);
    ops.sampsToRead = dataAdapter.getSampsToRead(ops.NchanTOT);
    ops.maxSampsToRead = ops.sampsToRead;

    if isfield(ops,'percentSamplesToUse') && ops.percentSamplesToUse > 0.0 && ops.percentSamplesToUse < 100.0
        ops.sampsToRead = ceil(ops.sampsToRead * ops.percentSamplesToUse / 100.0) ;
        fprintf('Using only %0.2f percent [%d] of max samples per channel [%d] for [%d] connected channels of [%d] total channels\n', ops.percentSamplesToUse, ops.sampsToRead, ops.maxSampsToRead, ops.Nchan, ops.NchanTOT);
    end

    if ispc
        dmem         = memory;
        memfree      = dmem.MemAvailableAllArrays/8;
        memallocated = min(ops.ForceMaxRAMforDat, dmem.MemAvailableAllArrays) - memfree;
        memallocated = max(0, memallocated);
    else
        memallocated = ops.ForceMaxRAMforDat;
    end
    nint16s      = memallocated/dataTypeBytes;

    NTbuff      = ops.NT + 4*ops.ntbuff;
    Nbatch      = ceil(ops.sampsToRead /(ops.NT-ops.ntbuff));
    Nbatch_buff = inf;%floor(4/5 * nint16s/rez.ops.Nchan /(ops.NT-ops.ntbuff)); % factor of 4/5 for storing PCs of spikes
    Nbatch_buff = min(Nbatch_buff, Nbatch);

    chOffset = ops.chOffset;
    
    %% load data into patches, filter, compute covariance
    if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
        [b1, a1] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
    else
        [b1, a1] = butter(3, ops.fshigh/ops.fs*2, 'high');
    end

    fprintf('Time %3.0fs. Loading raw data... \n', toc);
    ibatch = 0;
    if ops.GPU
        CC = gpuArray.zeros( rez.ops.Nchan,  rez.ops.Nchan, 'single');
    else
        CC = zeros( rez.ops.Nchan,  rez.ops.Nchan, 'single');
    end
    if strcmp(ops.whitening, 'noSpikes')
        if ops.GPU
            nPairs = gpuArray.zeros( rez.ops.Nchan,  rez.ops.Nchan, 'single');
        else
            nPairs = zeros( rez.ops.Nchan,  rez.ops.Nchan, 'single');
        end
    end
    if ~exist('DATA', 'var')
        DATA = zeros(ops.NT, rez.ops.Nchan, Nbatch_buff, dataTypeString);
    end
    if ~exist('dataRaw','var')
        dataRaw = zeros(1,1);%NTbuff,rez.ops.Nchan, Nbatch_buff, dataTypeString);
    end

    isproc = zeros(Nbatch, 1);

    myLoopCount = 0;
    while 1
        ibatch = ibatch + ops.nSkipCov;

        offset = max(0, dataTypeBytes*ops.NchanTOT*((ops.NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
        if offset > ops.sampsToRead*dataTypeBytes*ops.NchanTOT
            fprintf('Setting offset to eof after reading %0.2f percent of sample points per channel\n',ops.percentSamplesToUse);
            offset = ops.maxSampsToRead*dataTypeBytes*ops.NchanTOT;
        end

        if ibatch==1
            ioffset = 0;
        else
            ioffset = ops.ntbuff;
        end
        myLoopCount = myLoopCount +1;
        fprintf('Reading spikes into buff while loop count = %d of Nbatch = %d  offset = %d\n',myLoopCount, Nbatch, offset);
        buff = dataAdapter.batchRead(offset, ops.NchanTOT, NTbuff, dataTypeString, chOffset);
        if isempty(buff)
            break;
        end
        nsampcurr = size(buff,2);
        if nsampcurr<NTbuff
            buff(:, nsampcurr+1:NTbuff) = repmat(buff(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
        % Testing if DATA needs to be scaled up
        while ~any(buff(:) > 10)
            buff = buff.*1000;
        end
        
        if ops.GPU
            dataRAW = gpuArray(buff);
        else
            dataRAW = buff;
        end
        dataRAW = dataRAW';
        dataRAW = single(dataRAW);
        dataRAW = dataRAW(:, ops.chanMapConn);

        datr = filter(b1, a1, dataRAW);
        datr = flipud(datr);
        datr = filter(b1, a1, datr);
        datr = flipud(datr);

        switch ops.whitening
            case 'noSpikes'
                smin      = my_min(datr, ops.loc_range, [1 2]);
                sd = std(datr, [], 1);
                peaks     = single(datr<smin+1e-3 & bsxfun(@lt, datr, ops.spkTh * sd));
                blankout  = 1+my_min(-peaks, ops.long_range, [1 2]);
                smin      = datr .* blankout;
                CC        = CC + (smin' * smin)/ops.NT;
                nPairs    = nPairs + (blankout'*blankout)/ops.NT;
            otherwise
                CC        = CC + (datr' * datr)/ops.NT;
        end
        
        if ibatch<=Nbatch_buff
            if strcmp('int16',ops.dataTypeString)
                DATA(:,:,ibatch) = gather_try(int16( datr(ioffset + (1:ops.NT),:)));                
            elseif strcmp('single',ops.dataTypeString)
                DATA(:,:,ibatch) = gather_try(single( datr(ioffset + (1:ops.NT),:)));                
            else
                error('Unknown conversion for gpuArray %s\n',ops.dataTypeString);
            end            
            isproc(ibatch) = 1;
        end
    end
    CC = CC / ceil((Nbatch-1)/ops.nSkipCov);
    switch ops.whitening
        case 'noSpikes'
            nPairs = nPairs/ibatch;
    end
    dataAdapter.closeAll;
    
    if isfield(ops,'percentSamplesToUse') && ops.percentSamplesToUse > 0.0 && ops.percentSamplesToUse < 100.0
        fprintf('Using only %0.2f percent [%d] of max samples per channel [%d]\n', ops.percentSamplesToUse, ops.sampsToRead, ops.maxSampsToRead);
    end

    fprintf('Time %3.0fs. Channel-whitening filters computed. \n', toc);
    switch ops.whitening
        case 'diag'
            CC = diag(diag(CC));
        case 'noSpikes'
            CC = CC ./nPairs;
    end

    if ops.whiteningRange<Inf
        ops.whiteningRange = min(ops.whiteningRange, rez.ops.Nchan);
        Wrot = whiteningLocal(gather_try(CC), ops.yc, ops.xc, ops.whiteningRange);
    else
        %
        [E, D] 	= svd(CC);
        D = diag(D);
        eps 	= 1e-6;
        Wrot 	= E * diag(1./(D + eps).^.5) * E';
    end
    Wrot    = ops.scaleproc * Wrot;

    fprintf('Time %3.0fs. Loading raw data and applying filters... \n', toc);

    dataAdapter = DataAdapter.newDataAdapter(ops.recordingType, ops.fbinary);

    fidW    = fopen(ops.fproc, 'w');

    if strcmp(ops.initialize, 'fromData')
        i0  = 0;
        ixt  = round(linspace(1, size(ops.wPCA,1), ops.nt0));
        wPCA = ops.wPCA(ixt, 1:3);

        rez.ops.wPCA = wPCA; % write wPCA back into the rez structure
        uproj = zeros(1e6,  size(wPCA,2) * rez.ops.Nchan, 'single');
    end
    %
    fprintf('Applying filters...');
    for ibatch = 1:Nbatch
        fprintf('Applying filters: ibatch = %d of Nbatch = %d \n',ibatch, Nbatch);
        if isproc(ibatch) %ibatch<=Nbatch_buff
            if ops.GPU
                datr = single(gpuArray(DATA(:,:,ibatch)));
            else
                datr = single(DATA(:,:,ibatch));
            end
        else
            offset = max(0, dataTypeBytes*ops.NchanTOT*((ops.NT - ops.ntbuff) * (ibatch-1) - dataTypeBytes*ops.ntbuff));
            if offset > ops.sampsToRead*dataTypeBytes*ops.NchanTOT
                offset = ops.maxSampsToRead*dataTypeBytes*ops.NchanTOT;
            end

            if ibatch==1
                ioffset = 0;
            else
                ioffset = ops.ntbuff;
            end
            buff = dataAdapter.batchRead(offset, ops.NchanTOT, NTbuff, dataTypeString);

            if isempty(buff)
                break;
            end
            
            
            
            nsampcurr = size(buff,2);
            if nsampcurr<NTbuff
                buff(:, nsampcurr+1:NTbuff) = repmat(buff(:,nsampcurr), 1, NTbuff-nsampcurr);
            end

            if ops.GPU
                dataRAW = gpuArray(buff);
            else
                dataRAW = buff;
            end
            dataRAW = dataRAW';
            dataRAW = single(dataRAW);
            dataRAW = dataRAW(:, ops.chanMapConn);

            datr = filter(b1, a1, dataRAW);
            datr = flipud(datr);
            datr = filter(b1, a1, datr);
            datr = flipud(datr);

            datr = datr(ioffset + (1:ops.NT),:);
        end

        datr    = datr * Wrot;

        if ops.GPU
            dataRAW = gpuArray(datr);
        else
            dataRAW = datr;
        end
        %         dataRAW = datr;
        dataRAW = single(dataRAW);
        dataRAW = dataRAW / ops.scaleproc;

        if strcmp(ops.initialize, 'fromData') %&& rem(ibatch, 10)==1
            % find isolated spikes
            [row, col, ~] = isolated_peaks(dataRAW, ops.loc_range, ops.long_range, ops.spkTh);

            % find their PC projections
            uS = get_PCproj(dataRAW, row, col, wPCA, ops.maskMaxChannels);

            uS = permute(uS, [2 1 3]);
            uS = reshape(uS,numel(row), rez.ops.Nchan * size(wPCA,2));

            if i0+numel(row)>size(uproj,1)
                uproj(1e6 + size(uproj,1), 1) = 0;
            end

            uproj(i0 + (1:numel(row)), :) = gather_try(uS);
            i0 = i0 + numel(row);
        end

        if ibatch<=Nbatch_buff
            DATA(:,:,ibatch) = gather_try(single(datr));
        else %% Try here....
            datcpu  = gather_try(single(datr));
            fwrite(fidW, datcpu, ops.dataTypeString);
            
        end

    end
%     fprintf('\n');
    if strcmp(ops.initialize, 'fromData')
        uproj(i0+1:end, :) = [];
    end
    Wrot        = gather_try(Wrot);
    rez.Wrot    = Wrot;

    fclose(fidW);
    dataAdapter.closeAll;
    if ops.verbose
        fprintf('Time %3.2f. Whitened data written to disk... \n', toc);
        fprintf('Time %3.2f. Preprocessing complete!\n', toc);
    end


    rez.temp.Nbatch = Nbatch;
    rez.temp.Nbatch_buff = Nbatch_buff;
    end

    function [ ops ] = updateOpsWithChannelMap(ops)
    if ~isempty(ops.chanMap)
        if ischar(ops.chanMap) % chanMap is filename
            chanMapStruct = load(ops.chanMap); % load from file
            % all fields MUST exist in the Channel Map file
            ops.chanMap = chanMapStruct.chanMap;
            ops.chanMapConn = chanMapStruct.chanMap(chanMapStruct.connected>1e-6);
            ops.xc = chanMapStruct.xcoords(chanMapStruct.connected>1e-6);
            ops.yc = chanMapStruct.ycoords(chanMapStruct.connected>1e-6);
            ops.xcoords = chanMapStruct.xcoords;
            ops.ycoords = chanMapStruct.ycoords;
            ops.connected = chanMapStruct.connected;
            ops.Nchan    = getOr(ops, 'Nchan', sum(chanMapStruct.connected>1e-6));
            ops.NchanTOT = getOr(ops, 'NchanTOT', numel(chanMapStruct.connected));
            ops.kcoords = chanMapStruct.kcoords(chanMapStruct.connected>1e-6);
%             ops.fs = chanMapStruct.fs;

        else % ops.chanMap is a numeric array (linear)
            ops.chanMap = ops.chanMap;
            ops.chanMapConn = ops.chanMap;
            ops.xc = zeros(numel(ops.chanMapConn), 1);
            ops.yc = (1:1:numel(ops.chanMapConn))';
            ops.xcoords = ops.xc;
            ops.ycoords = ops.yc;
            ops.Nchan    = numel(ops.connected);
            ops.NchanTOT = numel(ops.connected);
            ops.kcoords = ones(ops.Nchan, 1);
            ops.fs = ops.fs;
        end
    else % is ops.chanMap is empty
        ops.chanMap  = 1:ops.Nchan;
        ops.chanMapConn = 1:ops.Nchan;
        ops.xc = zeros(ops.Nchan, 1);
        ops.yc = (1:ops.Nchan)';
        ops.xcoords = ops.xc;
        ops.ycoords = ops.yc;
        ops.connected = ones(ops.Nchan,1);%true(numel(chOps.chanMap), 1);
        ops.Nchan    = getOr(ops, 'Nchan', numel(ops.connected));
        ops.NchanTOT = getOr(ops, 'NchanTOT', numel(ops.connected));
        ops.kcoords = ones(ops.Nchan, 1);
        ops.fs = ops.fs;
    end

end

