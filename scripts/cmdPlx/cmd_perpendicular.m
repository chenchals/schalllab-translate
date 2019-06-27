% Hi Chenchal,
% Here are the depths for the 16 perpendicular penetrations. The depths are
% in channel-units the certainty is +/- 0.5 channels. They can also be
% matched to supplementary figure 1a of our paper or Figure 5A of Godlove
% et al., 2014. Note that the depth alignments are slightly off from
% Godlove et al., 2014 because after discussions with Alex Maier, Jeff and
% I decided to approximate depth to the closest channel units rather than
% using the actual depth. 

%session,  file name,  relative depth of the 1st channel (in channel units) from surface
basePath = '/Volumes/schalllab';
baseBinPath = '/scratch/Chenchal/cmdBinaryRepo';
if ~exist(baseBinPath,'dir')
    mkdir(baseBinPath);
end

euPaths={'data/Euler/mat','data/Euler/plx'};
xPaths={'data/Xena/post_2011/mat','data/Xena/post_2011/plx'};

str= {...
 'Eu 1st session|eulsef20120910c-01|channels in gray matter|6:21';
 'Eu 2nd session|eulsef20120911c-01|channels in gray matter|6:21'; 
 'Eu 3rd session|eulsef20120912c-01|channels in gray matter|8:23';
 'Eu 4th session|eulsef20120913c-01|channels in gray matter|9:24';
 'Eu 5th session|eulsef20120914c-01|channels in gray matter|12:24';
 'Eu 6th session|eulsef20120915c-01|channels in gray matter|6:21';
 'X-site1 1st session|xensef20120420a-01|channels in gray matter|13:24';
 'X-site1 2nd session|xensef20120423b-final|channels in gray matter|6:21';
 'X-site1 3rd session|xensef20120424c-final|channels in gray matter|8:23';
 'X-site1 4th session|xensef20120425c-final|channels in gray matter|12:24';
 'X-site1 5th session|xensef20120426c-01|channels in gray matter|12:24';
 'X-site1 6th session|xensef20120427c-01|channels in gray matter|10:24';
 'X-site2 1st session|xensef20120514d-final|channels in gray matter|7:22';
 'X-site2 2nd session|xensef20120515c-final|channels in gray matter|7:22';
 'X-site2 3rd session|xensef20120516c-final|channels in gray matter|8:23';
 'X-site2 4th session|xensef20120517d-final|channels in gray matter|6:21';
};
sess = struct();
for ii = 1:numel(str)
    if startsWith(str{ii},'E')
        paths = euPaths;
    else
        paths = xPaths;
    end
    t=split(str{ii},'|');
    sess(ii).session = t{1};
    sess(ii).plxPath = paths{2};
    sess(ii).matPath = paths{1};   
    sess(ii).filename = t{2};
    sess(ii).channelNos = eval(t{4});
end

sess=struct2table(sess);

for ii=1:size(sess,1)
    mfiles = dir(fullfile(basePath,sess.matPath{ii},[sess.filename{ii} '.mat']));
    if ~isempty(mfiles)
        sess.matFile(ii) = {mfiles.name}';
    end
    % Raw file
    pfiles = dir(fullfile(basePath,sess.plxPath{ii},[sess.filename{ii} '.plx']));
    if ~isempty(pfiles)
        sess.plxFile(ii) = {pfiles.name}';
    else
        % find if base file is present
        b = split(sess.filename{ii},'-');
        pfiles = dir(fullfile(basePath,sess.plxPath{ii},[ b{1} '.plx']));
        if ~isempty(pfiles)
            sess.plxFile(ii) = {pfiles.name}';
        end
    end    
end

for ii = 1:size(sess,1)
    ifile = fullfile(basePath,sess.plxPath{ii},sess.plxFile{ii});
    fprintf('Reading plx file %s ...',ifile)    
    data = readPLXFileC(ifile,'all');
    fprintf('done\n')
    % 17-40 24 channels
    data = [data.ContinuousChannels(17:40).Values]';
    ofile = fullfile(baseBinPath,[sess.filename{ii} '.bin']);
    fidw = fopen(ofile,'w');
    fprintf('Writing file %s ...',ofile)    
    fwrite(fidw,data(:)','int16');
    fclose(fidw);
    fprintf('done\n')
end




