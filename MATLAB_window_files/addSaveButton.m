function addSaveButton(figureNum, subjectNum)

%% Add a save button

outName = sprintf('/Users/histed/behav-output/%s-behav-i%03d.pdf', datestr(now, 'yymmdd'), subjectNum)
epParams = {figureNum, outName, 'FileFormat', 'pdf', 'Size', [12 12], 'PrintUI', false };
bH = uicontrol(figureNum, 'Style', 'pushbutton', 'String', sprintf('Save PDF figure : %s', outName), ...
               'Units', 'pixels', 'Position', [5 5 450 20], 'Callback', {@saveButtonCb, epParams});

function saveButtonCb(hObject, eventdata, epParamsIn) 

exportfigPrint(epParamsIn{:});
display(epParamsIn)


