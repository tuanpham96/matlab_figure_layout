clc; close all; clear;
addpath('../code');
%% Parse the svg  
with_labels = false; 
file_id = 'example_1'; 
file_prefix = ['layout_', file_id]; 
file_name = [file_prefix, '.svg']; 
% replacetextstruct = '';
replacetextstruct = struct('pattern', 'sub', 'replacewith', ''); 
svg_parsed = FigureLayout(file_name, replacetextstruct); 
dimensions = svg_parsed.dimensions; 
layout = svg_parsed.layout; 
%% Figure dimensions and general set up 
width = dimensions.width; 
height = dimensions.height; 
unit = dimensions.unit; 
% set manually if your MATLAB version does not have `str2symunit` or `unitConversionFactor`
% if you have both, you can do:
%       conv_factor = double(unitConversionFactor(str2symunit(unit), ...
%                   str2symunit('cm')));
conv_factor = 1/10; % if unit in svg file is milimeters

figure;
set(gcf, 'Units', 'centimeters', ...
    'Position', [0, 0, width, height]*conv_factor, ...
    'PaperUnits', 'centimeters','PaperPosition', [0, 0, width, height]*conv_factor, ...
    'PaperSize', [width, height]*conv_factor, ... 
    'InvertHardcopy', 'off', ...
    'Color', 'w');
%% Plot all the components in the figure according to the layout 
run component_colors.m
possible_labels = comp_color.keys; 
containstr = @(s,x) ~isempty(find(regexp(s, x),1)); 
components = fieldnames(layout); 
 
for i=1:length(components) 
    comp_name = components{i};
    comp = layout.(comp_name); 
    label = []; 
    for j=1:length(possible_labels)
        if containstr(comp_name, possible_labels{j})
            label = possible_labels{j};
            break;
        end
    end
    color = comp_color(label); 
    if ~strcmp(label,'border')
        box_opt = 'off'; 
    else 
        box_opt = 'on'; 
    end
    ax = axes('Units', 'normalized', 'Position', comp.normz_pos);
    set(ax, 'Color', color, 'xtick', '', 'ytick', '', 'box', box_opt);
    if with_labels
        xlabel(ax, label, 'fontsize', 8); 
    end
end
%% Print it out 
if with_labels
    suffix = '_layout_with_labels'; 
else 
    suffix = '_layout_no_labels'; 
end 
print(gcf, [file_id, suffix], '-dpdf'); 
