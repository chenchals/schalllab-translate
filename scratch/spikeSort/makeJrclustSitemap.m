nChan = 32;
chanSpacing = 150;

% 
siteMap = 1:nChan;
shankMap = ones(1,nChan);
siteLocs = [zeros(1,nChan); siteMap.*150];

% paste the output strings in master_jrclust.prm
fprintf('\n********Copy and paste the output strings into')
fprintf('********master_jrclust.prm file\n');
temp = num2str(shankMap,'%i,');
fprintf('shankMap = [%s]\n', temp(1:end-1));
temp = num2str(siteLocs(:)','%i,%i;');
fprintf('siteLoc = [%s]\n',temp(1:end-1));
temp = num2str(siteMap,'%i,');
fprintf('siteMap = [%s]\n', temp(1:end-1));
fprintf('*********\n')