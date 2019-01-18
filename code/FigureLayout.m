classdef FigureLayout < handle
    %% FigureLayout class
    % The object parses an .svg file (created in Inkscape) to create
    % `layout` struct containing the desired normalized positions of
    % your figure's subplots, as well as the page's dimensions and unit
    % in `dimension` struct. 
    % For example:
    %   %% Parsing layout 
    %   % file_name: the location of the .svg file 
    %   % replacetextstruct: struct saves the pattern to be replaced when parsing
    %   %                    OR set replacetextstruct = '' if not what you want 
    %   replacetextstruct = struct('pattern', 'sub', 'replacewith', '');
    %   svg_parsed = FigureLayout(file_name, replacetextstruct);
    %   dimensions = svg_parsed.dimensions;
    %   layout = svg_parsed.layout;
    % 
    %   %% Then set your figure page-related properties 
    %   width = dimensions.width; 
    %   height = dimensions.height; 
    %   unit = dimensions.unit; 
    %
    %   % set manually if your MATLAB version does not have `str2symunit`
    %   %                   or `unitConversionFactor` 
    %   % if you have both, you can do:
    %   %       conv_factor = double(unitConversionFactor(str2symunit(unit), ...
    %   %                   str2symunit('cm')));
    %   conv_factor = 1/10; % if unit in svg file is milimeters 
    % 
    %   figure;
    %   set(gcf, 'Units', 'centimeters', ...
    %           'Position', [0, 0, width, height]*conv_factor, ...
    %           'PaperUnits', 'centimeters', ...
    %           'PaperPosition', [0, 0, width, height]*conv_factor, ...
    %           'PaperSize', [width, height]*conv_factor, ... 
    %           'InvertHardcopy', 'off', ...
    %           'Color', 'w');
    %   %% Then you can set a subplot position like 
    %   A1_figure_pos = layout.A_sub1_figure.normz_pos; % the actual names depend on your set up 
    %   A1_figure = axes('Units', 'normalized', 'Position', A1_figure_pos);
    
    properties (Access=public) 
        % struct saves the parsed dimensions from svg file. It has 3
        % fields: `width`, `height` and `unit` to descibe the dimension of
        % the page set up in the svg file in `Inkscape`. You will need 
        % these variables when setting the figure `Paper*`-related
        % properties in order to print it out with the desired dimensions. 
        dimensions
        % struct saves the parsed layout from the svg file. Each of its
        % field saves the normalized positions that can be used for
        % constructing subplot positions, as well as additional
        % user-defined parameters (given the correct format of the names of
        % the attributes in the svg file). Generally, each field would
        % have these structs `x`, `y`, `width`, `height`, `normz_pos`. You
        % can use `norm_pos` when setting your desired subplot positions.
        % Remeber to to 'Unit' to 'normalized'. 
        layout
        % struct saves the pattern to be replaced when parsing. It needs to
        % have 2 fields `pattern` and `replacewith`. For example, if
        % `replacetextstruct = struct('pattern', 'sub', 'replacewith',
        % '');` means in any pattern `sub` in the svg file will be replaced
        % with an empty string when saving it in `layout`. 
        replacetextstruct
    end
    properties (Constant, Access=private)
        % dimension related fields of a normalized object. 
        dim_fields = {'x', 'y', 'width', 'height', 'normz_pos'};
        % possible fields to look for in the svg file's attributes. These
        % are neccessary fields/attributes in order to parse the identity
        % of the object and it dimensions, as well as any allowed
        % transformation. 
        possible_fields = {'GROUP', 'TEMPLATE', 'LABEL', ...
            'x', 'y', 'width', 'height', 'transform'};
        % possible patterns to look for in the svg file's attributes. These
        % are additional fiels/attributes in order to parse user-defined
        % parameters. For example, you want `layout.A_sub1_figure` to
        % have additional fields called `title` and `fontsize`. In
        % Inkscape, you would need to add the attributes "FigLay_title" and
        % "FigLay_fontsize" along with their values. 
        possible_patterns = {'^FigLay\_*'};
    end
    methods (Access=public)
        %% FigureLayout constructor
        function obj = FigureLayout(file_name, replacetextstruct)
            % Initilize a FigureLayout object and parse the svg file  
            % file_name:            the path for the `.svg` file
            % replacetextstruct:    the struct that saves the pattern to be 
            %                       replaced when parsing.
            svg_file = xml2struct(file_name);
            file_attr = [svg_file.Attributes];
            obj.replacetextstruct = replacetextstruct;
            obj.parse_dimensions(file_attr);
            obj.parse_layout(svg_file);
        end
        %% Set figure 
    end
    
    methods (Access=private)
        %% Parse the page dimensions in the svg file 
        function parse_dimensions(obj, file_attr)
            attr_map = containers.Map({file_attr.Name},{file_attr.Value});
            width_str = attr_map('width');
            height_str = attr_map('height');
            dim_unit = width_str(regexpi(width_str, '[a-z]'));
            max_width = str2double(width_str(regexpi(width_str, '\d')));
            max_height = str2double(height_str(regexpi(height_str, '\d')));
            
            obj.dimensions = struct('width', max_width, 'height', max_height, 'unit', dim_unit);
            
        end
        %% Parse the layout of the xml-parsed object 
        function parse_layout(obj, svg_file)
            file_children = FigureLayout.return_nonempty_obj([svg_file.Children]);
            layout_obj = [];             
            %% Only parse with layer with the attribute-value pair TAG=LAYOUT
            for i = 1:length(file_children)
                if strcmp(FigureLayout.return_atrr_val(file_children(i),'TAG'), 'LAYOUT')
                    layout_obj = FigureLayout.return_nonempty_obj([file_children(i).Children]);
                    break
                end
            end
            if isempty(layout_obj) 
                error('Parsing initialization error: No object with the attribute-value pair TAG=LAYOUT');
            end
            %% Now parse it to the layout struct 
            obj.layout = FigureLayout.return_general_layout(layout_obj, obj.dimensions, obj.replacetextstruct);
        end
    end
    
    methods (Static,Access=private) 
        
        %% GENERAL LAYOUT: apply recursion to 
        % (1) parse fields, 
        % (2) (a) transforms, (b) normalization, (c) template application and 
        % (3) save as a layout struct
        function res = return_general_layout(layout_obj, dimensions, replacetextstruct)
            %% FIRST PARSE of recursion after xml2struct: Parse children fields 
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
            %% SECOND PARSE of recursion after 1st parse: Transform & normalize and apply template
            % The goal is to transform and normalize objects, as well as
            % applying template of GROUP-SPECIFIC to GROUP-TEMPLATE object
            second_parse = first_parse;
            group_names = fieldnames(first_parse);
            for i = 1:length(group_names)
                name_i = group_names{i};
                group_i = first_parse.(name_i);
                second_parse = FigureLayout.recursive_children_second_parse(...
                    second_parse, group_i, dimensions, 0, name_i);
            end
            %% THIRD (FINAL) PARSE of recursion after 2nd parse: Save to a struct
            % Here `obj` is the only parent and if current node (`cur_node`)
            % meets requirement, then it's gonna be the child of `obj`,
            % otherwise recurse to next nodes (`cur_node`'s children)
            res = struct();
            res = FigureLayout.recursive_children_third_parse(res, second_parse, '', replacetextstruct);
        end
        
        %% THIRD PARSE of recursion after 2nd parse: Save to a struct 
        % Here `obj` is the only parent and if current node (`cur_node`)
        % meets requirement, then it's gonna be the child of `obj`,
        % otherwise recurse to next nodes (`cur_node`'s children) 
        function obj = recursive_children_third_parse(obj, cur_node, name, replacetextstruct)
            %% If current node is an actual object with positions 
            % then make a field with the given `name` to the struct `obj` 
            % and assign the current node to `obj` (parent) 
            if isfield(cur_node, 'normz_pos')
                obj.(name) = cur_node;
                return;
            end
            %% Otherwise, recurse to next nodes (children) 
            node_fields = fieldnames(cur_node);
            for i = 1 : length(node_fields)
                field_i = node_fields{i};
                
                % may be a bit redundant since `transform` fields are
                % eradicated in SECOND_PARSE but just in case 
                if strcmp(field_i, 'transform')
                    continue;
                end
                
                next_node = cur_node.(field_i);
                
                % concatenate the name for the next node 
                % modify the name if `replacetextstruct` is valid 
                if isempty(name)
                    next_name = field_i;
                else
                    if isstruct(replacetextstruct)
                        field_i = regexprep(field_i, replacetextstruct.pattern, replacetextstruct.replacewith);
                    end
                    next_name = [name, '_', field_i];
                end
                
                % recurse to next node
                obj = FigureLayout.recursive_children_third_parse(obj, next_node, next_name, replacetextstruct);
            end
        end
        
        %% SECOND PARSE of recursion after 1st parse: Transform & normalize and template
        % The goal is to transform and normalize objects, as well as
        % applying template of GROUP-SPECIFIC to GROUP-TEMPLATE object
        function parent = recursive_children_second_parse(parent, child, dimensions, recurse_lvl, ancestry)
            recurse_lvl = recurse_lvl + 1;
            max_width = dimensions.width;
            max_height = dimensions.height;
            
            [parent, child] = FigureLayout.pass_on_transform(parent, child);
            
            %% Check for validity to parse the object
            % write this like this so as to not having many nested "if"'s
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
                % Check for duplicate labels
                if isfield(parent, lbl)
                    error('%s', sprintf(...
                        ['Parsing error: Duplicate LABEL [%s] for POSITION-SPECIFIC object,' ...
                        '\nTraceback to: %s.%s'], lbl, ancestry, lbl));
                end
                % Add to parent
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
                
                % Cbeck for duplicate group
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
        
        %% TRANSFORMATION AND NORMALIZATION
        %% Pass on transform structs from parent to children
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
        %% Apply all transforms (if any) and normalize
        function obj = apply_transforms_and_normalize(obj, max_width, max_height)
            %% Apply transforms if have any 
            if isfield(obj, 'transform')
                transform_arrays = obj.transform;
                for i = 1:length(transform_arrays)
                    transform_struct = transform_arrays(i);
                    obj = FigureLayout.apply_transform(obj, transform_struct);
                end
                obj = rmfield(obj, 'transform');
            end
            %% Normalize dimensions 
            obj = FigureLayout.normalize_dimensions(obj, max_width, max_height);
            
        end  
        %% Apply a single transform struct on the object 
        % of un-normalized object, following
        % http://tavmjong.free.fr/INKSCAPE/MANUAL/html/Glossary.html#transmatrix
        function obj = apply_transform(obj, transform_struct)
            % assigning variables for easier access instead of a bunch of `obj.`'s 
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
            %% Actual application of transformation 
            % http://tavmjong.free.fr/INKSCAPE/MANUAL/html/Glossary.html#transmatrix
            obj.x = A*x + C*y + E;
            obj.y = B*x + D*y + F;
            obj.width = A*width;
            obj.height = D*height;
        end
        %% Normalize the dimensions of an object
        function obj = normalize_dimensions(obj, max_width, max_height)
            dim_params = {'x', 'y', 'width', 'height'};
            
            if ~all(isfield(obj, dim_params))
                error(['Dimension parsing error: at least one of the dimension'...
                    ' fields is not present in the object']);
            end
            
            obj.x = obj.x/max_width;
            obj.y = 1 - obj.y/max_height - obj.height/max_height; % cuz the way Inkscape lays out the page 
            obj.width = obj.width/max_width;
            obj.height = obj.height/max_height;
            
            % save in this field for easy access when setting fgure pos
            % also the existence of `normz_pos` signifies the object has
            % its position normalized for additional checking
            obj.normz_pos = [obj.x, obj.y, obj.width, obj.height];
        end
        
        %% TEMPLATE APPLICATION 
        %% Copy template from SRC to TGT 
        function tgt = copy_template(src, tgt)
            [src_border, tgt_border, tgt] = FigureLayout.get_borders(src, tgt);
            tgt = FigureLayout.recursive_template(src, tgt, src_border, tgt_border);
        end
        %% Recursive template for all the children of SRC to TGT 
        function tgt_child = recursive_template(src_child, tgt_child, src_border, tgt_border)
            %% Apply template only when reach a POSITION-SPECIFIC object 
            if isfield(src_child, 'normz_pos')
                tgt_child = FigureLayout.apply_template(src_child, src_border, tgt_border);
                return;
            end
            %% Otherwise, recurse to its children 
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
        %% Apply template of a POSITION-SPECIFIC object chidl of SRC to TGT 
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
        %% Get borders of SRC and TGT before application of template 
        % "borders" here basically resemble the coordinate systems for both
        % SRC and TGT. SRC needs to have a POSITION-SPECIFIC object with 
        % its LABEL = "border".  
        function [src_border, tgt_border, tgt] = get_borders(src, tgt)
            if ~isfield(src, 'border')
                error(['The source template object needs to have a POSITION-SPECIFIC' ...
                    ' object with LABEL="border" in order to copy to target object']);
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
                error(['The target object does not have the dimension fields'...
                    ' necessary for creating its "border" to represent its coordinate' ...
                    ' in order to copy the template from source']);
            end
        end

        %% FIRST PARSE of recursion after xml2struct: Parse fields
        % The goal is to parse the children's fields like the ones in
        % `possible_fields` or `possible_patterns` before second parse
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
            %% Recurse to the children
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
        %% Parse the `transform` field into transformation struct
        % the only allowed value of this field in `Inkscape` is either
        % "matrix(A,B,C,D,E,F)" or "translate(E,F)"
        function res = parse_transform_text(transform_text)
            % Get the transform tag: like "matrix", "translate"
            split_str = regexp(transform_text, '[()]', 'split');
            transform_tag = split_str{1};
            
            % Parse the numbers after the tag
            separate_numbers = regexp(transform_text,'[+-]?\d+\.?\d*', 'match');
            parsed_numbers = cellfun(@(x) str2double(x), separate_numbers,'UniformOutput', true);
            len_parse = length(parsed_numbers);
            
            % Initialize the `start_idx` to fill out the struct later on
            % as well as checking for the allowed of `transform_tag`
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
            
            % Initialize the struct
            res = struct();
            fn_vec = ('A':'F')';
            for i = 1:length(fn_vec)
                fn = fn_vec(i);
                res.(fn) = 0;
            end
            res.A = 1; res.D = 1; % default no scaling
            
            % Save the actual numbers
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
        %% Parse the dimension related fields
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
        
        %% Return non-empty position of a cell
        function res = nonempty_pos(c_l)
            res = cellfun(@(x) ~isempty(x), c_l, 'UniformOutput', true);
        end
        %% Return non-empty-atrribute objects after xml2struct parsing
        function res = return_nonempty_obj(raw_obj)
            if isfield(raw_obj, 'Attributes')
                res = raw_obj(FigureLayout.nonempty_pos({raw_obj.Attributes}));
            else
                res = '';
            end
        end
        %% Return object with a particular name after xml2struct parsing
        function res = return_named_obj(parent, name)
            res = FigureLayout.return_nonempty_obj([parent(strcmp({parent.Name}, name)).Children]);
        end
        %% Find the value of attributes that have a pattern
        % in particular, patterns in `possible_patterns`
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
                [parse_i, stat_i] = str2num(val_i); % cuz sometimes matrix
                if stat_i % if it is a num, save it; otherwise just string
                    val_i = parse_i;
                end
                child.(name_i{1}) = val_i;
            end
        end
        %% Find attribute value of a particular attribute
        % particularly in the `possible_fields`
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