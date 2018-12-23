clc; clear; close all; 
addpath(genpath('../figures'), genpath('../functions'))
%% Constructing the function 
% file  = 'Fig2_layout.svg';
% svg_file = xml2struct(file);
% file_attr = [svg_file.Attributes];
% attr_map = containers.Map({file_attr.Name},{file_attr.Value});
% width_str = attr_map('width');
% height_str = attr_map('height');
% file_unit = width_str(regexpi(width_str, '[a-z]'));
% max_width = str2double(width_str(regexpi(width_str, '\d')));
% max_height = str2double(height_str(regexpi(height_str, '\d')));
% 
% nonempty_pos = @(c_l) cellfun(@(x) ~isempty(x), c_l, 'UniformOutput', true);
% return_nonempty_obj = @(raw_obj) raw_obj(nonempty_pos({raw_obj.Attributes}));
% return_named_obj = @(parent, name) return_nonempty_obj([parent(strcmp({parent.Name}, name)).Children]);
% return_atrr_val = @(obj, attr) obj.Attributes(strcmp({obj.Attributes.Name},attr)).Value;
% file_children = return_nonempty_obj([svg_file.Children]);
% graphic_obj = return_named_obj(file_children, 'g');
% for i = 1:length(graphic_obj)
%     if strcmp(return_atrr_val(graphic_obj(i),'label'), 'layout')
%         layout_obj = return_nonempty_obj([graphic_obj(i).Children]);
%         break
%     end
% end
% layout_map = containers.Map();
% layout_params = {'x', 'y', 'width', 'height'};
% normz_fun = {@(x) x/max_width, @(x) 1-(x/max_height), @(x) x/max_width, @(x) x/max_height};
% 
% for i = 1:length(layout_obj)
%     ly_i = layout_obj(i);
%     lbl = return_atrr_val(ly_i, 'label');
%     tmp_struct = struct();
%     for j = 1:length(layout_params)
%         normz_j = normz_fun{j};
%         val_j = normz_j(str2double(return_atrr_val(ly_i, layout_params{j}))); 
%         tmp_struct.(layout_params{j}) = val_j; str2double(return_atrr_val(ly_i, layout_params{j}));
%     end
%     tmp_struct.y = tmp_struct.y - tmp_struct.height; 
%     layout_map(lbl) = tmp_struct;
% end

%% Testing the finalized function 
file_name  = 'Fig8_layout_official.svg';
[layout_map, dimensions] = return_figure_layout(file_name);
width = dimensions.width; 
height = dimensions.height; 
unit = dimensions.unit; 
conv_factor = double(unitConversionFactor(str2symunit(unit), str2symunit('cm'))); 
layout_keys = layout_map.keys();
figure; 
set(gcf, 'Units', 'centimeters', 'Position', [0, 0, width, height]*conv_factor, ...
    'PaperUnits', 'centimeters','PaperPosition', [0, 0, width, height]*conv_factor, 'PaperSize', [width, height]*conv_factor);

for i = 1:length(layout_keys)
    pos_i = layout_map(layout_keys{i});
    pos_i = [pos_i.x, pos_i.y, pos_i.width, pos_i.height];
    if contains(layout_keys{i}, 'ann') || contains(layout_keys{i}, 'text') || ...
            contains(layout_keys{i}, 'colorbar') ||  contains(layout_keys{i}, 'fig') 
        annotation('textbox', 'Units', 'normalized', 'Position', pos_i, ...
            'LineStyle', '-', 'String', layout_keys{i}); 
    else 
        ax = axes('Units', 'normalized', 'Position', pos_i); 
        title(ax, layout_keys{i}, 'FontWeight', 'normal', 'interpreter', 'none');
        
        xlabel('x');
        ylabel('y');
        colorbar;
    end
end
% print -besfit -painters -dpdf Fig5_layout
%%
width = dimensions.width; 
height = dimensions.height; 
unit = dimensions.unit; 
conv_factor = 1/10; 
a1 = layout.A.sub1.figure.normz_pos; 
a2 = layout.A.sub2.figure.normz_pos; 
b1 = layout.B.sub1.figure.normz_pos; 
b2 = layout.B.sub2.figure.normz_pos; 
figure; hold on; 
set(gcf, 'Units', 'centimeters', 'Position', [0, 0, width, height]*conv_factor, ...
    'PaperUnits', 'centimeters','PaperPosition', [0, 0, width, height]*conv_factor, 'PaperSize', [width, height]*conv_factor);

axes('Units', 'normalized', 'Position', a1); 
axes('Units', 'normalized', 'Position', a2); 
axes('Units', 'normalized', 'Position', b1); 
axes('Units', 'normalized', 'Position', b2); 
