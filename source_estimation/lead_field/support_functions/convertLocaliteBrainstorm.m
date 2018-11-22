

% function convertLocaliteBrainstorm(EegPosFile,BSPosFile,OutputFile)
function convertLocaliteBrainstorm(filePath,ID,EegPosFile,fileNameSave)

% Imports EEG marker file as text string
EEGtext = importEEGposLocalite([filePath,ID,EegPosFile]);

% Converts string file to cells
EEGtext = cellstr(EEGtext);

% Find cells beginning with '<Marker color'
chanInfo = EEGtext(strncmp('<Marker color',EEGtext,13));

% Remove text other than electrode name
chanNameLocalite = [];
for x = 1:length(chanInfo)
    temp = strsplit(chanInfo{x,1},{'<Marker color="#808080" description="','" drawAura="false"'});
    chanNameLocalite{x,1} = temp{1,2};
end

% Find cells beginning with '<ColVec3D'
chanInfo = EEGtext(strncmp('<ColVec3D',EEGtext,9));

% Check that each cell has the correct text. If not, find the missing text
% and concatenate
chanInfoError = EEGtext(strncmp('data1',EEGtext,5));
idx = 0;
for x = 1:length(chanInfo)
    if isempty(strfind(chanInfo{x,1},'data1'))
        idx = idx+1;
        chanInfo{x,1} = [chanInfo{x,1},' ',chanInfoError{idx,1}];
    end
end


% Remove text other than electrode position
chanLocLocalite = [];
for x = 1:length(chanInfo)
    temp = strsplit(chanInfo{x,1},{'<ColVec3D data0="','" data1="','" data2="','"/>'});
    chanLocLocalite(x,1) = str2num(temp{1,2});
    chanLocLocalite(x,2) = str2num(temp{1,3});
    chanLocLocalite(x,3) = str2num(temp{1,4});
end

%Scale the electrode positions to better fit brainstorm
chanLocLocalite = chanLocLocalite*0.001;

% Generate text file
fid = fopen([filePath,ID,fileNameSave],'w');

% fprintf(fid,'%d\n',62);

for i = 1:length(chanNameLocalite)
    
    if isempty(chanLocLocalite(i,1)) || isempty(chanLocLocalite(i,2)) || isempty(chanLocLocalite(i,3))
        fprintf('Electrode %s is missing, skipped\n',chanNameLocalite{i});
    else
        eName = chanNameLocalite{i};
    end
    
    
    % Flip the z value
    fprintf(fid,'%s\t%d\t%d\t%d\n',eName,chanLocLocalite(i,1),...
        chanLocLocalite(i,2),chanLocLocalite(i,3));
end

fclose(fid);

% % Load existing channel file
% load(BSPosFile);
% 
% % Re-set Brainstorm .mat channel file defaults
% Comment = 'Individual EEG positions from Localite';
% MegRefCoef = [];
% Projector = struct([]);
% TransfMeg = [];
% TransfMegLabels = [];
% TransfEeg = [];
% TransfEegLabels = [];
% HeadPoints.Loc = [];
% HeadPoints.Label = [];
% HeadPoints.Type = [];
% SCS.Nas = [];
% SCS.LPA = [];
% SCS.RPA = [];
% SCS.R = [];
% SCS.L= [];
% 
% % Find the names of the channels in the data
% EEGName = {Channel.Name};
% 
% % Create the channel file
% % Find matching channels between data and registration and remove missing
% % channels
% chanLog = ismember(upper(chanNameLocalite),upper(EEGName));
% chanName = chanNameLocalite(chanLog);
% chanLoc = chanLocLocalite(:,chanLog);
% 
% %Re-order electrode names and electrode positions
% [~,chanOrd] = ismember(upper(EEGName),upper(chanName));
% NameCorrect = chanName(chanOrd);
% LocCorrect = chanLoc(:,chanOrd);
% 
% %Scale the electrode positions to better fit brainstorm
% LocCorrect = LocCorrect*0.001;
% 
% %Create structure
% ChannelA = struct([]);
% for x = 1:size(Channel,2)
%     ChannelA(x).Name = NameCorrect{x,1};
%     ChannelA(x).Comment = [];
%     ChannelA(x).Type = 'EEG';
%     ChannelA(x).Loc = LocCorrect(:,x);
%     ChannelA(x).Orient = [];
%     ChannelA(x).Weight = [];
% end
% 
% %Replace old Channel structure with new structure
% Channel = ChannelA;
% 
% %Save structure
% save(OutputFile,'Comment','MegRefCoef','Projector','TransfMeg','TransfMegLabels','TransfEeg','TransfEegLabels','HeadPoints','SCS','Channel');