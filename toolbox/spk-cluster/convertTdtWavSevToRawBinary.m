function ops = convertTdtWavSevToRawBinary(ops)

    fidout      = fopen(ops.fbinary, 'w');
    nSPikesToUse = 100000;
    %
    clear fs
    for j = 1:ops.Nchan
        fs{j} = dir(fullfile(ops.root, sprintf('*_Wav1_Ch%d.sev', j) ));
    end
    tic
    for ch = 1:ops.Nchan
        fullFn = fullfile(fs{ch}.folder, fs{ch}.name);
        %fid = fopen(fullFn);
        data = SEV2mat(fullFn,'CHANNEL',ch);
        samples = data.Wav1.data(1:nSPikesToUse);
        samples  = samples';
        fwrite(fidout, samples, 'int32');
        %fclose(fid);
    end

    fclose(fidout);

    toc
end