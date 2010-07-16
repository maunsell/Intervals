function [retval] = Intervals(data_struct, input)

% This function processes event data and saves variables in input.
% Then it calls plot functions in a
% try-catch block so that errors in plot functions don't affect
% variable saving.
%  MH 100115
% $Id$

beep off;  % otherwise played through speakers to animal!
format compact; 

ds = data_struct;

% debug
%dumpEvents(ds); 

warning off MATLAB:dispatcher:nameConflict;

% First call after pressing "play" in client

if nargin == 1 || ~isfield(input, 'trialSinceReset')	% initialize on first pass
	disp('First trial, initializing');
	addpath('~/Library/Application Support/MWorks/MatlabToolbox/tools-mh');
	addpath('~/Library/Application Support/MWorks/MatlabToolbox');
    input.trialSinceReset = 1;
    input.reactionTimesMS = {};
    input.holdTimesMs = {};
    input.tooFastTimeMs = [];
    input.trialOutcomeCell = {};
    input.holdStartsMs = {};
    input.juiceTimesMsCell = {};
else
  input.trialSinceReset = input.trialSinceReset+1;
  assert(all(input.tooFastTimeMs > 1));
end

%% quick path check 
if ~exist('mwGetEventValue')
  error('Missing mwGetEventValue - is path correct?');
end

%% process constants; should be non-empty only on first trial and
%when changed
input.constList = { 'tooFastTimeMs', 'subjectNum', 'doWaitForUp', ...
                    'doAuditoryWaitingForStim', 'doLeverSolenoid', ...
                    'doHoldTone', 'reactTimeMs', 'randReqHoldMaxMs', ...
                    'fixedReqHoldTimeMs', 'earlyTimeoutMs', ...
                    'itiTimeMs', 'postRewardMs', ...
                    'minRewardUs', 'maxRewardUs', ...
                    'maxConsecCorrects', 'jackpotProb', ...
                    'jackpotRewardSizeUs', 'doLever', 'react1TimeMS', ...
					'react1DurMS', 'react2TimeMS', 'react2DurMS', ...
					};
nConsts = length(input.constList);
for iC = 1:nConsts
  tCN = input.constList{iC};
  tV = mwGetEventValue(ds.events, ds.event_codec, tCN, [], 'ignoremissing');
  if ~isempty(tV), 
    input.(tCN) = tV;
  end
end

%disp(input.reactTimeMs);

%% process corrects
if ~isempty(mwGetEventValue(ds.events, ds.event_codec, ...
                             'success', [], 'ignoreMissing'))
  input.trialOutcomeCell{input.trialSinceReset} = 'success';
elseif ~isempty(mwGetEventValue(ds.events, ds.event_codec, ...
                               'failure', [], 'ignoreMissing'))
  input.trialOutcomeCell{input.trialSinceReset} = 'failure';  
elseif ~isempty(mwGetEventValue(ds.events, ds.event_codec, ...
                               'ignore', [], 'ignoreMissing'))  
  input.trialOutcomeCell{input.trialSinceReset} = 'ignore';    
else
  disp('Error!  Missing trial outcome variable this trial');
  input.trialOutcomeCell{input.trialSinceReset} = 'error-missing';      
end

thisTrialN = input.trialSinceReset;%length(input.trialOutcomeCell);

%% process reaction times for this trial
codes = [ds.events.event_code];

stimOnUs = mwGetEventTime(ds.events, ds.event_codec, 'stimulusOn', 1);
totalHoldTimeMs = mwGetEventValue(ds.events, ds.event_codec, 'tTotalReqHoldTimeMs');
%trialStartUs = mwGetEventTime(ds.events, ds.event_codec, 'trialStart', 1);
leverDownUs = mwGetEventTime(ds.events, ds.event_codec, 'leverResult', 1, 1);
leverUpUs = mwGetEventTime(ds.events, ds.event_codec, 'leverResult', 2, 0);

%reactTimeMs = (leverUpUs - stimOnUs) / 1000;
holdTimeMs = (leverUpUs - leverDownUs) / 1000;
%reactTimeMs = (holdTimeMs - totalHoldTimeMs);
reactTimeMs = holdTimeMs;

% add to array
input.holdStartsMs{input.trialSinceReset} = leverDownUs/1000;
input.holdTimesMs{input.trialSinceReset} = holdTimeMs;
input.reactionTimesMS{input.trialSinceReset} = reactTimeMs;

% total reward times
juiceAmtsUs = mwGetEventValue(ds.events, ds.event_codec, 'juice', 'all');
juiceAmtsMs = juiceAmtsUs(juiceAmtsUs~=0)/1000;
input.juiceTimesMsCell{thisTrialN} = juiceAmtsMs;

%% run subfunctions
try
  input = saveMatlabState(data_struct, input);
  tic
  if mod(input.trialSinceReset, 3) == 0
    plotOnlineHist(data_struct, input);
  end
  toc
%%  input = testUpload(data_struct, input);
catch ex
  disp('??? Error in subfunction; still saving variables for next trial')
  printErrorStack(ex);
end

%% save variables for next trial
retval = input;

return

