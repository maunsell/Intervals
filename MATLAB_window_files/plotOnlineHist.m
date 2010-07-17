function plotOnlineHist(data_struct, input, name)

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
% Performance Values

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
	text(0.00, 1.25, name, 'FontWeight', 'bold', 'FontSize', 14);
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
end			
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hold time histogram

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
% Hold time CDF

axH = subplot(spSz{:},5);
cdfplot([input.holdTimesMs{:}]);
grid off;
set(gca, 'XLim', [0 input.reactTimeMs], 'YLim', [0 1]);
xlabel('time (ms)');
ylabel('hold times < time');
title('hold density function');
hold on;
plotIntervalLines(input, 'vertical');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Percent Correct over trials

axH = subplot(spSz{:},3);
hold on;
plot(smooth1(double(successIx), 'gauss', 3, 10));
lH1 = plot(smooth1(double(successIx), 'gauss', max(1, numTrials / 45), max(numTrials / 15, 1)));
set(lH1, 'Color', 'k', 'LineWidth', 2);
ylabel('Percent correct');
set(gca, 'YLim', [0 1]);
xlabel('Trial number');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Triallength over trials

axH = subplot(spSz{:},9);
hold on;
hSDiffsSec = diff(holdStarts)/1000;
% make outliers a fixed value
largeIx = hSDiffsSec >= 120;
hSDiffsSec(largeIx) = 120;
xs = 1:length(hSDiffsSec);
pH1 = plot(xs,hSDiffsSec);
if sum(largeIx) > 0
  pH2 = plot(xs(largeIx), hSDiffsSec(largeIx), 'r.');   % outliers
end
set(pH1, 'LineStyle', 'none', 'Marker', 'x');
pH2 = plot(smooth1(hSDiffsSec, 'gauss', [2], 3), 'r');

ylabel('Trial duraction (s)');
xLim = get(gca, 'XLim');
lH = plot(xLim, 20 * [1 1], '--k');
set(gca,'YLim', [0 121]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trials per minute

axH = subplot(spSz{:}, 6);
hold on;

trialsPerMin = 60000 ./ diff(holdStarts);
%xs = 1:length(trialsPerMin);
h1 = plot(trialsPerMin);
set(h1, 'LineStyle', 'none', 'Marker', 'x', 'Color', 'b');
hold on;
pH2 = plot(smooth1(trialsPerMin, 'gauss', [8], 16));
set(pH2, 'Color', 'k','LineWidth', 3);

% line
xLim = get(gca, 'XLim');
lH = plot(xLim, 20*[1 1], '--k');

set(gca,'YLim', [0 61]);

xlabel('Trial number');
ylabel('Trials per min');

nDiffs = length(hSDiffsSec);
fN = max(1, nDiffs-5);						% if first 6 trials, start at 1
title(sprintf('Recent trials (s): %s', mat2str(round(hSDiffsSec(fN:end)))));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hold time over trials

axH = subplot(spSz{:}, 8);
hold on;
hH(1) = plot(smooth1(holdV, 'gauss', [2], 3));
hH(2) = plot(smooth1(holdV, 'gauss', [8], 16));
set(hH(2), 'Color', 'k', 'LineWidth', 3);
hRange = [0 prctile(holdV, 95)];
set(gca, 'YLim', hRange);
xlabel('trial number');
ylabel('hold time (ms)');
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


