function data = runsimulation(modelobj, cs)
% RUNSIMULATION simulate SimBiology model, modelobj.

% Restore the configset after the task has run.
originalStopTime    = get(cs, 'StopTime');
originalTimeUnits   = get(cs, 'TimeUnits');

% Define cleanup code.
cleanup = onCleanup(@() restore(cs, originalStopTime, originalTimeUnits));

% Configure task specific StopTime.
set(cs, 'StopTime', 12.0);
set(cs, 'TimeUnits', 'second');

% Run simulation.
data = sbiosimulate(modelobj, cs, [], []);

% Plot the results.
plottype_Time(data, '<all>', 'one axes', '');

% ---------------------------------------------------------
function restore(cs, originalStopTime, originalTimeUnits)

% Restore StopTime.
set(cs, 'StopTime', originalStopTime);
set(cs, 'TimeUnits', originalTimeUnits);

% ----------------------------------------------------------
function plottype_Time(tobj, y, plotStyle, axesStyle)
%TIME Plots states versus time.
%
%    TIME(TOBJ, Y, PLOTSTYLE, PROPS) plots the results of the simulation
%    for the species with the specified Y versus time.
%
%    If PLOTSTYLE is 'one axes' then data from each run is plotted into one
%    axes. If PLOTSTYLE is 'trellis' then data from each run is plotted
%    into its own subplot.
%
%    If Y is '<all>' then all data will be plotted.
%
%    AXESSTYLE is a structure that contains axes property value pairs.
%
%    See also GETDATA, SELECTBYNAME.

if ~isempty(tobj(1).RunInfo.ConfigSet) && tobj(1).RunInfo.ConfigSet.CompileOptions.UnitConversion && all(strcmp({tobj.TimeUnits},tobj(1).TimeUnits)) && ~isempty(tobj(1).TimeUnits)
    labelX = ['Time (' tobj(1).TimeUnits ')'];
else
    labelX = 'Time';
end

% Get the labels for the plot.    
labelArgs = timeGetLabels(axesStyle, 'States versus Time', labelX, 'States');

if (length(tobj) > 1)
    switch (plotStyle)
    case 'one axes'
        haxes = sbioplot(tobj, @timeplotdata, [], y, labelArgs{:});
    case 'trellis'
        htrellis = sbiotrellis(tobj,@timesubplotdata, [], y, labelArgs{:});
        haxes    = htrellis.plots;
    end
    
    % Configure the axes properties.
    if isfield(axesStyle, 'Properties')
        set(haxes, axesStyle.Properties);
    end
else
    % Plot Data.
    handles = timesubplotdata(tobj, [], y);
    
    % Configure the axes properties.
    if isfield(axesStyle, 'Properties') && length(handles)>=1
        haxes = get(handles(1), 'Parent');
        set(haxes, axesStyle.Properties);
    end
    
    % Label the plot.
    title(labelArgs{2});
    xlabel(labelArgs{4});
    ylabel(labelArgs{6});
    
    % If Y is '<all>' get all the data names.
    if strcmpi(y, '<all>')
        [~, ~, names] = getdata(tobj);
    else
        names = y;
    end
    
    % Create legend.
    leg = legend(names, 'Location', 'NorthEastOutside');
    set(leg, 'Interpreter', 'none');
end

%--------------------------------------------------------
function [handles, names] = timeplotdata(tobj, ~, y)

colors    = get(gca, 'ColorOrder');
numColors = length(colors);

% Preallocate handles
if strcmpi(y, '<all>')
    [~, ~, names] = getdata(tobj(1));
else
    [~, ~, names] = selectbyname(tobj(1), y);
end
handles = zeros(length(names), length(tobj));

for i=1:length(tobj)
    % Get the data from the next run.
    nexttobj = tobj(i);

    % Get the data associated with y.
    if strcmpi(y, '<all>')
        [time, data, names] = getdata(nexttobj);
    else
        [time, data, names] = selectbyname(nexttobj, y);
    end

    % Error checking.
    if size(data,2) == 0
        error('Data specified do not exist.');
    end
    set(gca, 'ColorOrderIndex', 1);
    % Plot data. If there is only one state use different colors for runs.
    if(size(data,2) ==1)
        hLine = plot(time, data, 'color',colors(mod(i-1,numColors)+1,:));
    else
        hLine = plot(time, data);
    end
    handles(:,i) = hLine;
end

% ---------------------------------------------------------
function handles = timesubplotdata(tobj, ~, y)

% Get Data to be plotted.
if strcmpi(y, '<all>')                
    [time, data] = getdata(tobj);
else
    [time, data] = selectbyname(tobj, y);
end

% Error checking.
if size(data,2) == 0
    error('Species specified do not exist.');
end

% Plot Data.
handles = plot(time, data);

% ---------------------------------------------------------
function out = timeGetLabels(axesStyle, labelTitle, labelX, labelY)

out = {'title', labelTitle, 'xlabel', labelX, 'ylabel', labelY};

if isfield(axesStyle, 'Labels')
    allLabels = axesStyle.Labels;
    
    if isfield(allLabels, 'Title')
        out{2} = allLabels.Title;
    end
    
    if isfield(allLabels, 'XLabel')
        out{4} = allLabels.XLabel;
    end
    
    if isfield(allLabels, 'YLabel')
        out{6} = allLabels.YLabel;
    end
end

