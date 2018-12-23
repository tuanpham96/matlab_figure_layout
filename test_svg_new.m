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
layout_params = {'x', 'y', 'width', 'height'};
normz_fun = {@(x) x/max_width, @(x) 1-(x/max_height), @(x) x/max_width, @(x) x/max_height};
possible_fields = {'GROUP', 'TEMPLATE', 'LABEL', ...
    'x', 'y', 'width', 'height'}; 
layout = SVG_STRUCT.return_general_layout(layout_obj, dimensions, possible_fields);

