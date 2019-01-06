classdef FigureLayout < handle
    properties
        dimensions
        layout
        replacetextstruct
    end
    properties (Constant)
        dim_fields = {'x', 'y', 'width', 'height', 'normz_pos'};
        possible_fields = {'GROUP', 'TEMPLATE', 'LABEL', ...
            'x', 'y', 'width', 'height', 'transform'};
        possible_patterns = {'^FigLay\_*'};
    end
    methods
        function obj = FigureLayout(file_name, replacetextstruct)
            svg_file = xml2struct(file_name);
            file_attr = [svg_file.Attributes];
            obj.replacetextstruct = replacetextstruct; 
            obj.parse_dimensions(file_attr);
            obj.parse_layout(svg_file);
        end
        
        function parse_dimensions(obj, file_attr)
            attr_map = containers.Map({file_attr.Name},{file_attr.Value});
            width_str = attr_map('width');
            height_str = attr_map('height');
            dim_unit = width_str(regexpi(width_str, '[a-z]'));
            max_width = str2double(width_str(regexpi(width_str, '\d')));
            max_height = str2double(height_str(regexpi(height_str, '\d')));
            
            obj.dimensions = struct('width', max_width, 'height', max_height, 'unit', dim_unit);
            
        end
        function parse_layout(obj, svg_file)
            file_children = FigureLayout.return_nonempty_obj([svg_file.Children]);
            for i = 1:length(file_children)
                if strcmp(FigureLayout.return_atrr_val(file_children(i),'TAG'), 'LAYOUT')
                    layout_obj = FigureLayout.return_nonempty_obj([file_children(i).Children]);
                    break
                end
            end
            obj.layout = FigureLayout.return_general_layout(layout_obj, obj.dimensions, obj.replacetextstruct);
        end
    end
    methods (Static)
        
        function res = return_general_layout(layout_obj, dimensions, replacetextstruct)
            first_parse = struct();
            for i = 1:length(layout_obj)
                ly_i = layout_obj(i);
                tmp_struct = FigureLayout.recursive_children_first_parse(ly_i);
                group_name = tmp_struct.GROUP;
                if isfield(first_parse, group_name) 
                    error('Parsing error: Duplicate GROUP [%s] in first parse', group_name);
                end
                first_parse.(group_name) = tmp_struct;
            end
            
            second_parse = first_parse;
            group_names = fieldnames(first_parse);
            for i = 1:length(group_names)
                name_i = group_names{i};
                group_i = first_parse.(name_i);
                second_parse = FigureLayout.recursive_children_second_parse(...
                    second_parse, group_i, dimensions, 0, name_i);
            end
            res = struct();
            res = FigureLayout.recursive_children_third_parse(res, second_parse, '', replacetextstruct);
        end
        function obj = recursive_children_third_parse(obj, cur_node, name, replacetextstruct)
            if isfield(cur_node, 'normz_pos')
                obj.(name) = cur_node;
                return;
            end
            
            node_fields = fieldnames(cur_node);
            for i = 1 : length(node_fields)
                field_i = node_fields{i};
                if strcmp(field_i, 'transform')
                    continue;
                end
                next_node = cur_node.(field_i);
                if isempty(name)
                    next_name = field_i;
                else
                    if isstruct(replacetextstruct) 
                        field_i = regexprep(field_i, replacetextstruct.pattern, replacetextstruct.replacewith); 
                    end
                    next_name = [name, '_', field_i];
                end
                obj = FigureLayout.recursive_children_third_parse(obj, next_node, next_name, replacetextstruct);
            end
        end
        
        function res = apply_template(src_child, src_border, tgt_border)
            scale_x = tgt_border.width/src_border.width;
            scale_y = tgt_border.height/src_border.height;
            translate_x = src_child.x - src_border.x;
            translate_y = src_child.y - src_border.y;
            
            res = src_child; % for anything other than dimensions
            res.x = tgt_border.x + translate_x * scale_x;
            res.y = tgt_border.y + translate_y * scale_y;
            res.width = src_child.width * scale_x;
            res.height = src_child.height * scale_y;
            res.normz_pos = [res.x, res.y, res.width, res.height];
        end
        function [src_border, tgt_border, tgt] = get_borders(src, tgt)
            if ~isfield(src, 'border')
                error('The source template needs to have a border in order to copy for target object');
            end
            src_border = src.border;
            try
                tgt_border = struct();
                dim_params = FigureLayout.dim_fields;
                for i = 1:length(dim_params);
                    field = dim_params{i};
                    tgt_border.(field) = tgt.(field);
                end
                tgt = rmfield(tgt, dim_params);
            catch
                error('The target object does not have the fields necessary for creating a border');
            end
        end
        function tgt = copy_template(src, tgt)
            [src_border, tgt_border, tgt] = FigureLayout.get_borders(src, tgt);
            tgt = FigureLayout.recursive_template(src, tgt, src_border, tgt_border);
        end
        function tgt_child = recursive_template(src_child, tgt_child, src_border, tgt_border)
            if isfield(src_child, 'normz_pos')
                tgt_child = FigureLayout.apply_template(src_child, src_border, tgt_border);
                return;
            end
            components = fieldnames(src_child);
            for i = 1:length(components)
                comp_name = components{i};
                tgt_child.(comp_name) = src_child.(comp_name);
                
                if strcmp(comp_name, 'transform')
                    continue;
                end
                tgt_child.(comp_name) = FigureLayout.recursive_template(...
                    src_child.(comp_name), tgt_child.(comp_name), src_border, tgt_border);
                
            end
        end
        function [parent, child] = pass_on_transform(parent, child)
            if ~isfield(parent, 'transform')
                return;
            end
            if ~isfield(child, 'transform')
                child.transform = [];
            end
            add_on = parent.transform;
            child.transform = [child.transform, add_on];
        end
        function obj = apply_transform(obj, transform_struct)
            try
                x = obj.x;
                y = obj.y;
                width = obj.width;
                height = obj.height;
            catch
                error(['The struct object to be transformed does not have ' ...
                    'all the required dimension fields']);
            end
            try
                A = transform_struct.A;
                B = transform_struct.B;
                C = transform_struct.C;
                D = transform_struct.D;
                E = transform_struct.E;
                F = transform_struct.F;
            catch
                error(['The transformation struct does not have all the' ...
                    'required fields for a transformation matrix']);
            end
            % http://tavmjong.free.fr/INKSCAPE/MANUAL/html/Glossary.html#transmatrix
            obj.x = A*x + C*y + E;
            obj.y = B*x + D*y + F;
            obj.width = A*width;
            obj.height = D*height;
            obj.normz_pos = [obj.x, obj.y, obj.width, obj.height];
        end
        function obj = apply_transforms_and_normalize(obj, max_width, max_height)
            if isfield(obj, 'transform')
                transform_cell = obj.transform;
                for i = 1:length(transform_cell)
                    transform_struct = transform_cell(i);
                    obj = FigureLayout.apply_transform(obj, transform_struct);
                end
                obj = rmfield(obj, 'transform');
            end
            obj = FigureLayout.normalize_dimensions(obj, max_width, max_height);
            
        end
        function parent = recursive_children_second_parse(parent, child, dimensions, recurse_lvl, ancestry)
            recurse_lvl = recurse_lvl + 1; 
            max_width = dimensions.width;
            max_height = dimensions.height;
            
            [parent, child] = FigureLayout.pass_on_transform(parent, child);
            if ~isfield(child, 'LABEL') && ~isfield(child, 'GROUP')         
                fprintf('The child below throws and error:\n');
                disp(child); 
                error('%s',...
                    sprintf(['The child needs to be having either:\n'...
                    '\t  (i) a LABEL attribute (POSITION-SPECIFIC) or \n'...
                    '\t (ii) a GROUP attribute (GROUP-SPECIFIC) or \n' ...
                    '\t(iii) a GROUP and TEMPLATE attribute (GROUP-TEMPLATE) \n' ...
                    'Trace back to %s'], ancestry));
            end
            %% POSITION-SPECIFIC
            if isfield(child, 'LABEL')
                lbl = child.LABEL;
                child = FigureLayout.apply_transforms_and_normalize(child, max_width, max_height);
                child = rmfield(child, 'LABEL');
                if isfield(parent, lbl)
                    error('%s', sprintf(...
                        ['Parsing error: Duplicate LABEL [%s] for POSITION-SPECIFIC object,' ...
                        '\nTraceback to: %s.%s'], lbl, ancestry, lbl));
                end
                parent.(lbl) = child;
                return;
            end
            
            %% GROUP-TEMPLATE or GROUP-SPECIFIC 
            if isfield(child, 'GROUP') 
                %% Get GROUP and TEMPLATE, assess if have children
                group = child.GROUP;
                if recurse_lvl > 1
                    ancestry = [ancestry ' -> ' group];
                end
                has_children = isfield(child, 'Children');
                if isfield(parent, group) && recurse_lvl > 1
                    fprintf('The child and parent below caused the program to throw and error\n'); 
                    disp(child); 
                    disp(parent); 
                    error('%s', sprintf(...
                        ['Parsing error: Duplicate GROUP [%s] for GROUP-*objects,' ...
                        '\nTraceback to: %s'], group, ancestry));
                end
                
                if isfield(child, 'TEMPLATE')
                    tmplt = child.TEMPLATE;
                    raw_template = strcmp(tmplt, 'none');
                    child = rmfield(child, 'TEMPLATE');
                else
                    raw_template = true;
                end
                
                %% GROUP-SPECIFIC 
                if has_children && raw_template
                    for kid = child.Children
                        child = FigureLayout.recursive_children_second_parse(child, kid{:}, dimensions, recurse_lvl, ancestry);
                    end
                    child = rmfield(child, 'Children');
                end
                
                if ~has_children && raw_template
                    error('%s', sprintf(...
                        ['The GROUP-SPECIFIC object [%s] needs to have children,'...
                        '\nTraceback to : %s'], group, ancestry)) ;
                end
                
                %% GROUP-TEMPLATE
                if ~has_children && ~raw_template
                    if ~isfield(parent, tmplt)
                        error('%s', sprintf(...
                            ['There is no corresonding template named [%s] ' ...
                            'that has already been parsed in the parent to parse ' ...
                            'GROUP-TEMPLATE object [%s],\n Traceback to %s'], ...
                            tmplt, group, ancestry));
                    end
                    if isfield(parent.(tmplt), 'transform')
                        parent.(tmplt) = rmfield(parent.(tmplt), 'transform');
                    end
                    template_obj = parent.(tmplt);
                    child = FigureLayout.apply_transforms_and_normalize(child, max_width, max_height);
                    child = FigureLayout.copy_template(template_obj, child);
                end
                
                if has_children && ~raw_template
                    error('%s', sprintf(...
                        ['The GROUP-TEMPLATE object [%s] cannot have children, '...
                        '\nTraceback to: %s'], group, ancestry));
                end
                
                %% Add the child to parent 
                if isfield(child, 'GROUP')
                    child = rmfield(child, 'GROUP');
                end
                
                parent.(group) = child;
                return;
                
            end
            
        end
        function child = recursive_children_first_parse(parent)
            child = struct();
            %% Store possible fields in the child 
            for i_field = 1:length(FigureLayout.possible_fields)
                field = FigureLayout.possible_fields{i_field};
                val = FigureLayout.return_atrr_val(parent,field);
                if isnan(val)
                    continue;
                end               
                % if it's the transform field, parse it first 
                if strcmp(field, 'transform')
                    val = FigureLayout.parse_transform_text(val);
                end
                child.(field) = val;
            end
            %% Store fields with a certain pattern in child 
            for i_pat = 1:length(FigureLayout.possible_patterns)
                pat = FigureLayout.possible_patterns{i_pat};
                child = FigureLayout.return_attrpattern_val(child, parent, pat);
            end
            %% Parse dimension-related fields {x,y,width,height} 
            % they usually come with each other, if not, the function would
            % throw and error just in case 
            if isfield(child, 'x') % meaning have dimension-related params
                child = FigureLayout.parse_dimension_text(child);
            end
            
            if ~isfield(parent, 'Children')
                return;
            end
            
            children = FigureLayout.return_nonempty_obj([parent.Children]);
            if isempty(children)
                return;
            end
            for i_child = 1:length(children)
                child_i = children(i_child);
                child.Children(i_child) = ...
                    { FigureLayout.recursive_children_first_parse(child_i) };
            end
        end
        
        function res = parse_transform_text(transform_text)
            split_str = regexp(transform_text, '[()]', 'split');
            transform_tag = split_str{1};
            
            separate_numbers = regexp(transform_text,'[+-]?\d+\.?\d*', 'match');
            parsed_numbers = cellfun(@(x) str2double(x), separate_numbers,'UniformOutput', true);
            len_parse = length(parsed_numbers);
            
            switch lower(transform_tag)
                case 'matrix'
                    start_idx = 1;
                    if len_parse > 6
                        error('The length of the ''matrix'' value cannot exceed 6');
                    end
                case 'translate'
                    start_idx = 5;
                    if len_parse > 2
                        error('The length of the ''translate'' value cannot exceed 2');
                    end
                otherwise
                    error(['The ''transform'' attribute in ''%s'' can only be' ...
                        ' either ''matrix'' or ''translate'', not ''%s'''], ...
                        transform_text, transform_tag);
            end
            
            res = struct();
            fn_vec = ('A':'F')';
            for i = 1:length(fn_vec)
                fn = fn_vec(i);
                res.(fn) = 0;
            end
            res.A = 1; res.D = 1; % default no scaling
            
            for i = 1:len_parse
                fn = fn_vec(start_idx + i - 1);
                res.(fn) = parsed_numbers(i);
            end
            
            if res.B ~= 0 && res.C ~=0 
                fprintf('The transformation struct below caused a warning\n'); 
                disp(res); 
                warning('%s', sprintf(...
                    ['The allowed transformations are translation ' ...
                    'and scaling, the values B,C~=0 means something else. \n '...
                    'Hence the result would not mirror the desired layout']));
            end
        end
        function obj = parse_dimension_text(obj)
            dim_params = {'x', 'y', 'width', 'height'};
            if ~all(isfield(obj, dim_params))
                error(['Dimension parsing error: at least one of the dimension'...
                    ' fields is not present in the object']);
            end
            for i = 1:length(dim_params)
                obj.(dim_params{i}) = str2double(obj.(dim_params{i}));
            end
        end
        
        function obj = normalize_dimensions(obj, max_width, max_height)
            dim_params = {'x', 'y', 'width', 'height'};
            if ~all(isfield(obj, dim_params))
                error(['Dimension parsing error: at least one of the dimension'...
                    ' fields is not present in the object']);
            end
            
            obj.x = obj.x/max_width; 
            obj.y = 1 - obj.y/max_height - obj.height/max_height;
            obj.width = obj.width/max_width;
            obj.height = obj.height/max_height; 
            % save in this field for easy access when setting fgure pos 
            obj.normz_pos = [obj.x, obj.y, obj.width, obj.height];
            
        end
        
        function res = nonempty_pos(c_l)
            res = cellfun(@(x) ~isempty(x), c_l, 'UniformOutput', true);
        end
        
        function res = return_nonempty_obj(raw_obj)
            if isfield(raw_obj, 'Attributes')
                res = raw_obj(FigureLayout.nonempty_pos({raw_obj.Attributes}));
            else
                res = '';
            end
        end
        function res = return_named_obj(parent, name)
            res = FigureLayout.return_nonempty_obj([parent(strcmp({parent.Name}, name)).Children]);
        end
        function child = return_attrpattern_val(child, parent, attr_pat)
            attr_names = {parent.Attributes.Name};
            idx = find(FigureLayout.nonempty_pos(regexp(attr_names, attr_pat)));
            if isempty(idx)
                return;
            end
            for i = idx
                name_i = regexp(attr_names{i}, attr_pat, 'split');
                name_i = name_i(FigureLayout.nonempty_pos(name_i));
                if length(name_i) ~= 1
                    error(['The pattern attribute %s, after parsing should '...
                        ' result in one and only one name from %s'], attr_pat, attr_names{i});
                end
                val_i = parent.Attributes(i).Value;
                [parse_i, stat_i] = str2num(val_i);
                if stat_i % if it is a num, save it; otherwise just string
                    val_i = parse_i;
                end
                child.(name_i{1}) = val_i;
            end
        end
        function res = return_atrr_val(obj, attr)
            idx = find(strcmp({obj.Attributes.Name},attr));
            if isempty(idx)
                res = NaN;
            else
                res = obj.Attributes(idx).Value;
            end
        end
        
    end
    
end