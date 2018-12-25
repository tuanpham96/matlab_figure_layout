clc; close all; clear;
addpath('../code');
%% Parse the svg  
file_prefix = 'layout_test_1'; 
file_name = [file_prefix, '.svg']; 
svg_parsed = FigureLayout(file_name); 
dimensions = svg_parsed.dimensions; 
layout = svg_parsed.layout; 
%% Figure dimensions and general set up 
width = dimensions.width; 
height = dimensions.height; 
unit = dimensions.unit; 
conv_factor = 1/10; 

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
    xlabel(ax, label, 'fontsize', 8); 
end

print(gcf, [file_prefix '_resultwithlabels'], '-dpdf'); 
