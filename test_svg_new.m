file_name = 'layout_test.svg'; 
svg_file = xml2struct(file_name);
file_attr = [svg_file.Attributes];
attr_map = containers.Map({file_attr.Name},{file_attr.Value});
width_str = attr_map('width');
height_str = attr_map('height');
dim_unit = width_str(regexpi(width_str, '[a-z]'));
max_width = str2double(width_str(regexpi(width_str, '\d')));
max_height = str2double(height_str(regexpi(height_str, '\d')));

dimensions = struct('width', max_width, 'height', max_height, 'unit', dim_unit); 

file_children = SVG_STRUCT.return_nonempty_obj([svg_file.Children]);
graphic_obj = SVG_STRUCT.return_named_obj(file_children, 'g');

for i = 1:length(file_children)
    if strcmp(SVG_STRUCT.return_atrr_val(file_children(i),'TAG'), 'LAYOUT')
        layout_obj = SVG_STRUCT.return_nonempty_obj([file_children(i).Children]);
        break
    end
end

possible_fields = {'GROUP', 'TEMPLATE', 'LABEL', ...
    'x', 'y', 'width', 'height'}; 
layout = SVG_STRUCT.return_general_layout(layout_obj, dimensions, possible_fields);
%%
width = dimensions.width; 
height = dimensions.height; 
unit = dimensions.unit; 
conv_factor = 1/10; 

figure;
set(gcf, 'Units', 'centimeters', 'Position', [0, 0, width, height]*conv_factor, ...
    'PaperUnits', 'centimeters','PaperPosition', [0, 0, width, height]*conv_factor, 'PaperSize', [width, height]*conv_factor);
%%
comp_color = containers.Map(); 
possible_labels = {'figure', 'annotation', 'inset', 'colorbar', 'legend', 'border', 'text'}; 
possible_colors = rand(length(possible_labels),3); 
for i = 1:length(possible_labels) 
    comp_color(possible_labels{i}) = possible_colors(i,:);
end

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
        ax = axes('Units', 'normalized', 'Position', comp.normz_pos);
        set(ax, 'Color', color, 'xtick', '', 'ytick', '', 'box', 'off');
        alpha 0.2;
        title(ax, label); 
    end
    
end

