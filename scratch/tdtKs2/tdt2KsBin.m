% convert tdt _Wav1_ or _RSn1_ .sev files into a kssort type binary
% interleaved data format
sess=dir('/scratch/ksData/Rig029/Joule*');

for f = 1:size(sess)
    ds = fullfile(sess(f).folder,sess(f).name,'*_Wav1_*.sev');
    T = interface.IDataAdapter.newDataAdapter('sev',ds,'rawDataScaleFactor',1E3);
    nsamp = T.writeBinary();
end

