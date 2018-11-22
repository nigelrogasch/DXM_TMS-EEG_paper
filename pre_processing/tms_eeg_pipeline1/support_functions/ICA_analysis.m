function [EEG]=ICA_analysis(EEG,dataAVGref,Cpca)
tmpdata=reshape(dataAVGref,[size(dataAVGref,1) size(dataAVGref,2)*size(dataAVGref,3)]); %concatenazione dei trials
tmpdata=tmpdata-repmat(mean(tmpdata,2),[1,size(dataAVGref,2)*size(dataAVGref,3)]);%zero mean
% 
% for j=1:size(event,2)
%     EEG.epoch(j).event=j;
%     EEG.epoch(j).eventlatency=event(j).latency;
%     EEG.epoch(j).eventtype=event(j).type;
%     EEG.epoch(j).eventurevent=j;
%     EEG.event(j).epoch=j;
%     EEG.urevent(j).epoch=j;
% end
% EEG.epoch=EEG.epoch(goodtriggers);
% 
% EEG.nbchan=size(dataAVGref,1);
% EEG.data=dataAVGref;
% EEG.srate=srate; clear srate
% EEG.chanlocs=chanlocs;
% EEG.trials=size(dataAVGref,3);
% EEG.pnts=size(dataAVGref,2);
% EEG.ref='averef';

[EEG.icaweights,EEG.icasphere,EEG.compvars] = runica( tmpdata, 'lrate', 0.001, 'pca', Cpca);
EEG.compvars=EEG.compvars/sum(EEG.compvars)*100;
EEG.icaact = (EEG.icaweights*EEG.icasphere)*reshape(tmpdata, EEG.nbchan, size(dataAVGref,3)*EEG.pnts); %S=A_trasp*X
EEG.icaact = reshape( EEG.icaact, size( EEG.icaact,1), EEG.pnts, size(dataAVGref,3));            
EEG.icawinv = pinv( EEG.icaweights*EEG.icasphere );

