clc
clear
close all
set(0,'DefaultAxesFontSize',15)
%%


%verify decoded state against RTXI's 

%%
%average FR usually 5-10 spks/s

basePath='~/Documents/Research/Data/rtxi_spike_mb/';
endPath = 'testing123_take2';channelID = 5;


%endPath = 'OP1_3715_b3_CL1';channelID = 7;

%no compression + viterbi training works!, OR
%5x compression + BW training

doSubsample = true;
clipLength = -1;%3e4;% (set to -1 to not clip)

readFun = @() h5read( [basePath,endPath,'.h5'], "/Trial1/Synchronous Data/Channel Data");

%ignore channel key for OP1_3715 etc.
channelKey = {'plant.x',...
    'ref',...
    'hmm1',...
    'hmm2',...
    'decode state',...
    'X_{est}',...
    'comp',...
    'rt per'};
    

%%


D=readFun();
if clipLength>0
    spks=D(channelID,1:clipLength); %check this!
else
    spks=D(channelID,:);
end
%states=D(6,:);

%plot(D(channelID,:),'r','LineWidth',2);
%return

%%

cMod = 100;

%ad-hoc way to map 0-.5-1 data to 0-1
spks_clipped = double(spks>.4);

if doSubsample
    %represents subsampling, @MB
    spks_clipped(1:2:end) = 0; 
end


figure(1)
clf
plot(spks_clipped,'LineWidth',1)
xlim([0,5e5])

% guess params
n_states = 2;

%ptr0 = (1e-3)*10;
%pfr = (1e-6);
%pfr2 = (1e-3);


% MB prior
ptr0 = 5e-4;%1e-2;
pfr = (5e-3/10);
pfr2= 5e-2/10;

%pfr = 0.05;
%pfr2 = 0.1;


EYE = eye(n_states);

To = (1-EYE)*ptr0 + EYE*(1-ptr0*(n_states-1));
Eo = zeros(n_states,2);
Eo(1,:) = [1-pfr, pfr];
Eo(2,:) = [1-pfr2, pfr2];


dt_ID = 1e-3;
dt_Decode = 1e-3;
cFactor = dt_ID / dt_Decode; %20?


spkc = compressSpks(spks_clipped,cMod*cFactor);%cFactor

tic
[Te,Ee] = hmmtrain(spkc+1,To,Eo);
qp_guess = hmmdecode(spkc+1,Te,Ee);
q_guess = hmmviterbi(spkc+1,Te,Ee);
toc
%
%%

figure(1)
clf
hold on
plot(spkc,'k','LineWidth',1)
plot(q_guess-.8,'g','LineWidth',2)
%plot(qp_guess(2,:),'m','LineWidth',2)
%xlim([0,1e5]+1e4)

hold off
set(gcf,'Position',[          64         225        1349         188]);

