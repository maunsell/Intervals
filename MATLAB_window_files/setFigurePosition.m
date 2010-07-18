function figureHandle = setFigurePosition(figureNum, widthPix, heightPix, location)

screenMarginPix = 25;
screenMenuPix = 22;

figureHandle = figure(figureNum);
clf;
screen = get(0, 'ScreenSize');
leftPix = screen(1) + screenMarginPix;
bottomPix = screen(2) + screenMarginPix;
rightPix = screen(3) - screenMarginPix;
topPix = screen(4) - screenMarginPix - screenMenuPix;
centerWidthPix = leftPix + (rightPix - leftPix) / 2;
centerHeightPix = bottomPix + (topPix - bottomPix) / 2;

% set the origin (lower left window corner)

location = lower(location);
figurePos = [centerWidthPix - widthPix / 2, centerHeightPix - heightPix / 2];
if strcmp(location, 'north')
	figurePos = [centerWidthPix - widthPix / 2, topPix - heightPix];
elseif strcmp(location, 'northeast')
	figurePos = [rightPix - widthPix, topPix - heightPix];
elseif strcmp(location, 'east')
	figurePos = [rightPix - widthPix, centerHeightPix - heightPix / 2];
elseif strcmp(location, 'southeast')
	figurePos = [rightPix - widthPix, bottomPix];
elseif strcmp(location, 'south')
	figurePos = [centerWidthPix - widthPix / 2, bottomPix];
elseif strcmp(location, 'southwest')
	figurePos = [leftPix, bottomPix];
elseif strcmp(location, 'west')
	figurePos = [leftPix, centerHeightPix - heightPix / 2];
elseif strcmp(location, 'northwest')
	figurePos = [leftPix, topPix - heightPix];
elseif strcmp(location, 'center')
	figurePos = [centerWidthPix - widthPix / 2, centerHeightPix - heightPix / 2];
end
figurePos = [figurePos widthPix heightPix];
set(figureHandle, 'OuterPosition', figurePos);
