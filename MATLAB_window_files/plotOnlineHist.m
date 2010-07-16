function plotOnlineHist(data_struct, input)

figNum = 4;

%% draw figure
figH = figure(figNum);
clf;

switch hostname
 case 'MaunsellMouse1'
  figPos = [1111 338 806 768];
 otherwise
  figPos = [930 270 780 750];
end
set(figH, 'Position', figPos);
spSz = {3,3};

numPoints = length(input.holdTimesMs);
numTrials = length(input.trialOutcomeCell);

% sometimes on client restart we have empty elements here; pad with
% NaN and hope they match up; I should figure out why they are missing

emptyIx = cellfun(@isempty, input.holdTimesMs); 
if sum(emptyIx) > 0
	input.holdTimesMs{emptyIx} = NaN; 
end
holdV = [input.holdTimesMs{:}];

successIx = strcmp(input.trialOutcomeCell, 'success');
failureIx = strcmp(input.trialOutcomeCell, 'failure');
ignoreIx = strcmp(input.trialOutcomeCell, 'ignore');
nCorr = sum(successIx);
nFail = sum(failureIx);
nIg = sum(ignoreIx);
holdStarts = [input.holdStartsMs{:}];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 - Performance Values

if length(holdStarts) > 2
	holdTimeMS = input.holdTimesMs{end};
	switch input.trialOutcomeCell{end}
	case 'success'
		outcomeString = 'correct';
	case 'failure'
		outcomeString = 'early';
	case 'ignore'
		outcomeString = 'failed'
	end
	axH = subplot(spSz{:}, 1);						% default axes are 0 to 1
	set(axH, 'Visible', 'off');
	text(0.00, 1.0, {'Subject:', 'Time working:', 'Reward volume:'});
	text(0.60, 1.0, {sprintf('%d', input.subjectNum), ...
		sprintf('%.0d m', ...
		round((input.holdStartsMs{end} - input.holdStartsMs{1})/60000)),...
		sprintf('%.1f s', ...
		sum(cat(2,input.juiceTimesMsCell{:})) / 1000)});
	text(0.00, 0.6, {'Trials:', 'Correct:', 'Early:', 'Failed:'});
	text(0.40, 0.6, {sprintf('%d', numTrials), sprintf('%d', nCorr), ...
				sprintf('%d', nFail), sprintf('%d', nIg)});
	text(0.60, 0.6, {' ', sprintf('%.0f%%', nCorr / numTrials * 100.0), ...
				sprintf('%.0f%%', nFail / numTrials * 100.0), ...
				sprintf('%.0f%%', nIg / numTrials * 100.0)});
	text(0, 0.3, {sprintf('Interval 1: %d - %d ms', input.react1TimeMS, ...
				input.react1TimeMS + input.react1DurMS), ...
				sprintf('Interval 2: %d - %d ms', input.react2TimeMS, ...
						input.react2TimeMS + input.react2DurMS)});

%	if strcmp(outcomeString, 'correct')
%		if holdTimeMS > input.react2TimeMS && ...
%							holdTimeMS <= input.react2TimeMS + input.react2DurMS
%			text(0, 0.22, 'Hit interval 2');
%		elseif holdTimeMS > input.react1TimeMS && ...
%						holdTimeMS <= input.react1TimeMS + input.react1DurMS
%			text(0, 0.22, 'Hit interval 2');
%		end
%	end
end			
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 - total hold time histogram

axH = subplot(spSz{:}, 2);
maxFail = max(holdV(find(failureIx)));
if maxFail > 2000
  maxX = 3000;
elseif maxFail > 2500
  maxX = 2500;
else
  maxX = 2000;
end
visIx = holdV <= maxX;
nVisPts = sum(visIx);
if nVisPts > 50
  binWidth = iqr(holdV(visIx)) ./ nVisPts.^(1/3);	% robust version of std
  nBins = ceil(maxX ./ binWidth);
else
  nBins = 10;
end
edges = linspace(0, maxX, nBins);
Ns = histc(holdV(find(successIx)), edges);
Nf = histc(holdV(find(failureIx)), edges);
if sum(Ns) + sum(Nf) > 0
  bH = bar(edges, [Ns(:),Nf(:)], 'stacked');
  set(bH, 'BarWidth', 1, 'LineStyle', 'none');
end
hold on;
xLim = [0 maxX + 50];
%set(gca, 'XLim', xLim);
set(gca, 'XLim', [0 input.reactTimeMs]);
yLim = get(gca, 'YLim');

title(sprintf('median hold %4.0f ms', median([input.holdTimesMs{:}])));
xlabel('time (ms)');

plotIntervalLines(input, 'vertical');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 - react time CDF

axH = subplot(spSz{:},5);
cdfplot([input.holdTimesMs{:}]);
grid off;
set(gca, 'XLim', [0 input.reactTimeMs], 'YLim', [0 1]);
xlabel('time (ms)');
ylabel('hold times < time');
title('hold density function');
hold on;
plotIntervalLines(input, 'vertical');

%%%%%%%%%%%%%%%%

%% 3 - react time PDF
%axH = subplot(spSz{:},7);
%numPoints = length(input.reactionTimesMS);
%reactV = [input.reactionTimesMS{:}];
%visIx = reactV<=maxX;
%nVisPts = sum(visIx);
%if nVisPts > 50
%  binWidth = iqr(reactV(visIx))./nVisPts.^(1/3); % robust version of std
%  nBins = ceil(2000./binWidth);
%else
%  nBins = 10;
%end
%edges = linspace(-1000, 1000, nBins);
%binSize = edges(2)-edges(1);

%emptyIx = cellfun(@isempty, input.reactionTimesMS);   % see above holdTimesM
%if sum(emptyIx) > 0, input.reactionTimesMS{emptyIx} = NaN; end
%rV = [input.reactionTimesMS{:}];

%Ns = histc(rV(successIx), edges);
%Nf = histc(rV(failureIx), edges);
%if sum(Ns)+sum(Nf) > 0
%  bH = bar(edges+binSize/2, [Nf(:),Ns(:)], 'stacked');
%  set(bH, 'BarWidth', 1, ...
%          'LineStyle', 'none');
%  cMap = get(gcf, 'Colormap');
%  % flip colors, keep blue on top of red, note flipped in bar.m above
%  set(bH(1), 'FaceColor', [0.6 0 0]);
%  set(bH(2), 'FaceColor', [0 0 0.6]);      
%end

%hold on;
%yLim = get(gca, 'YLim');
%plot([0 0], yLim, 'k');
%set(gca, 'XLim', [0 input.reactTimeMs]);
%title('reaction times');
%%%%%%%%%%%%%%%%

%% 4 - smoothed perf curve
axH = subplot(spSz{:},3);
hold on;
%plot(smooth(double(successIx), ceil(nTrial/10), 'lowess'));
plot(smooth1(double(successIx), 'gauss', [2], 3));
lH = plot(smooth1(double(successIx), 'gauss', [8], 16));
set(lH, 'Color', 'r', 'LineWidth', 3);
lH2 = plot(smooth1(double(successIx), 'gauss', [16], 32));
set(lH2, 'Color', 'k', 'LineWidth', 2);
ylabel('pct correct');
set(gca, 'YLim', [0 1]);

%%%%%%%%%%%%%%%%

%% 6 - trial length plot
axH = subplot(spSz{:},9);
hold on;
%pH=semilogy(diff(holdStarts)/1000);
hSDiffsSec = diff(holdStarts)/1000;
% make outliers a fixed value
largeIx = hSDiffsSec >= 120;
hSDiffsSec(largeIx) = 120;
xs = 1:length(hSDiffsSec);
pH1=plot(xs,hSDiffsSec);
if sum(largeIx) > 0
  pH2 = plot(xs(largeIx),hSDiffsSec(largeIx),'r.');  % outliers
end
set(pH1, 'LineStyle', 'none', ...
        'Marker', 'x');
%pH2 = plot(smooth(hSDiffsSec, 5, 'lowess'), 'r');
pH2 = plot(smooth1(hSDiffsSec, 'gauss', [2], 3), 'r');

%plot(diff(holdStarts)/1000, 'x');
ylabel('trial start time diff (s)');
xLim = get(gca, 'XLim');
lH = plot(xLim, 20*[1 1], '--k');
set(gca,'YLim', [0 121]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5 - trials per unit time

axH = subplot(spSz{:},6);
hold on;
%edges = linspace(min(holdStarts), max(holdStarts), 100);
%trsPerMin = histc(edges, holdStarts);
hSDiffsSec = diff(holdStarts)/1000;
trsPerSec = 1./hSDiffsSec;
trsPerMin = trsPerSec*60;

xs = 1:length(hSDiffsSec);

h1 = plot(xs, trsPerMin);
set(h1, 'LineStyle', 'none', 'Marker', 'x', 'Color', 'b');
hold on;
%pH2 = plot(smooth(trsPerMin, 50, 'loess'));
pH2 = plot(smooth1(trsPerMin, 'gauss', [8], 16));
set(pH2, 'Color', 'k','LineWidth', 3);


% line
xLim = get(gca, 'XLim');
lH = plot(xLim, 20*[1 1], '--k');

set(gca,'YLim', [0 61]);

xlabel('trial number');
ylabel('Trials per min');

nDiffs = length(hSDiffsSec);
fN = max(1, nDiffs-5);  % if first 6 trials, start at 1
title(sprintf('Last 6 (sec): %s', mat2str(round(hSDiffsSec(fN:end)))));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6 - hold times over time

axH = subplot(spSz{:}, 8);
hold on;
%hH(1) = plot(smooth(holdV, 50, 'loess'));
%hH(2) = plot(smooth(holdV, 250, 'loess'));
hH(1) = plot(smooth1(holdV, 'gauss', [2], 3));
hH(2) = plot(smooth1(holdV, 'gauss', [8], 16));
set(hH(2), 'Color', 'k', 'LineWidth', 3);
hRange = [0 prctile(holdV, 95)];
set(gca, 'YLim', hRange);
xlabel('trial number');
ylabel('hold time (ms)');
if nDiffs > 0
  totalElapsedS = (input.holdStartsMs{end} - input.holdStartsMs{1})/1000;

  %totalRewMs = sum([input.totalRewardTimesMs{successIx}]);
  totalRewMs = sum(cat(2,input.juiceTimesMsCell{:}));
  title(sprintf('Total elapsed: %d min; reward %.1fsec', ...
                round(totalElapsedS/60), totalRewMs/1000));
end
plotIntervalLines(input, 'horizontal');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Add a save button

outName = sprintf('/Users/histed/behav-output/%s-behav-i%03d.pdf', ...
                  datestr(now, 'yymmdd'), input.subjectNum);
epParams = { figNum, outName, 'FileFormat', 'pdf', ...
             'Size', [12 12], 'PrintUI', false };
bH = uicontrol(figNum, 'Style', 'pushbutton', ...
               'String', sprintf ('Save PDF figure : %s', outName), ...
               'Units', 'pixels', 'Position', [5 5 450 20], ...
               'Callback', {@saveButtonCb, epParams});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% subfunctions

function plotIntervalLines(input, orientation)

plotOneIntervalLine(input.tooFastTimeMs, 'k:', orientation);
plotOneIntervalLine(input.react1TimeMS, 'b:', orientation);
plotOneIntervalLine(input.react1TimeMS + input.react1DurMS, 'b:', orientation);
plotOneIntervalLine(input.react2TimeMS, 'r:', orientation);
plotOneIntervalLine(input.react2TimeMS + input.react2DurMS, 'r:', orientation);

function plotOneIntervalLine(value, lineValue, orientation);

if ~isempty(value)
	if strcmp(orientation, 'vertical')
		plot(value * [1 1], get(gca, 'YLim'), lineValue);
	elseif strcmp(orientation, 'horizontal')
		plot(get(gca, 'XLim'), value * [1 1], lineValue);
	else 
		display(sprintf('plotOneIntervalLine: unknow orientation %s'));
	end
end

function saveButtonCb(hObject, eventdata, epParamsIn) 
exportfigPrint(epParamsIn{:});

%%%%%%%%%%%%%%%%


