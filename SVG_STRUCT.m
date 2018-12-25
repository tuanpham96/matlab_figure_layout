classdef SVG_STRUCT
    methods (Static)
        
        function res = nonempty_pos(c_l)
            res = cellfun(@(x) ~isempty(x), c_l, 'UniformOutput', true);
        end
        function res = return_nonempty_obj(raw_obj)
            if isfield(raw_obj, 'Attributes')
                res = raw_obj(SVG_STRUCT.nonempty_pos({raw_obj.Attributes}));
            else
                res = '';
            end
        end
        function res = return_named_obj(parent, name)
            res = SVG_STRUCT.return_nonempty_obj([parent(strcmp({parent.Name}, name)).Children]);
        end
        function res = return_atrr_val(obj, attr)            
            idx = find(strcmp({obj.Attributes.Name},attr));
            if isempty(idx)
                res = NaN;
            else
                res = obj.Attributes(idx).Value;
            end
        end
        function res = return_general_layout(layout_obj, dimensions, possible_fields)
            first_parse = struct();
            for i = 1:length(layout_obj)
                ly_i = layout_obj(i);
                tmp_struct = SVG_STRUCT.recursive_children_first_parse(...
                    ly_i, dimensions, possible_fields);
                group_name = tmp_struct.GROUP;
                first_parse.(group_name) = tmp_struct;
            end         
            
            second_parse = first_parse;
            group_names = fieldnames(first_parse);
            for i = 1:length(group_names)
                name_i = group_names{i};
                group_i = first_parse.(name_i);
                second_parse = SVG_STRUCT.recursive_children_second_parse(...
                    second_parse, group_i);
            end
            res = struct(); 
            res = SVG_STRUCT.recursive_children_third_parse(res, second_parse, '');             
        end
        function obj = recursive_children_third_parse(obj, cur_node, name)
            if isfield(cur_node, 'normz_pos')
                obj.(name) = cur_node; 
            else
                node_fields = fieldnames(cur_node); 
                for i = 1 : length(node_fields) 
                    field_i = node_fields{i}; 
                    next_node = cur_node.(field_i);
                    if isempty(name) 
                        next_name = field_i; 
                    else 
                        next_name = [name, '_', field_i];
                    end
                    obj = SVG_STRUCT.recursive_children_third_parse(obj, next_node, next_name); 
                end                
            end
        end
        function obj = normalize_dimensions(obj, max_width, max_height)         
            dim_params = {'x', 'y', 'width', 'height'};
            normz_fun = {@(a) a/max_width, ...
                        @(a) 1-(a/max_height), ...
                        @(a) a/max_width, ...
                        @(a) a/max_height};
            for i = 1:length(dim_params)
                normz_i = normz_fun{i};
                val_i = str2double(obj.(dim_params{i}));
                obj.(dim_params{i}) = normz_i(val_i);
            end
            obj.y = obj.y - obj.height;
            obj.normz_pos = [obj.x, obj.y, obj.width, obj.height];
        end
        function res = transform(src_child, src_border, tgt_border)
            scale_x = tgt_border.width/src_border.width; 
            scale_y = tgt_border.height/src_border.height; 
            translate_x = src_child.x - src_border.x; 
            translate_y = src_child.y - src_border.y; 
            res = struct(); 
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
                dim_params = fieldnames(src_border);  
                for i = 1:length(dim_params); 
                    field = dim_params{i}; 
                    tgt_border.(field) = tgt.(field); 
                end
                tgt = rmfield(tgt, fieldnames(src_border)); 
            catch 
                error('The target object does not have the fields necessary for creating a border'); 
            end
        end 
        function tgt = copy_template(src, tgt)
           [src_border, tgt_border, tgt] = SVG_STRUCT.get_borders(src, tgt); 
           tgt = SVG_STRUCT.recursive_template(src, tgt, src_border, tgt_border);            
        end 
        function tgt_child = recursive_template(src_child, tgt_child, src_border, tgt_border)
            if ~isfield(src_child, 'normz_pos') 
                components = fieldnames(src_child); 
                for i = 1:length(components) 
                    comp_name = components{i}; 
                    tgt_child.(comp_name) = src_child.(comp_name); 
                    tgt_child.(comp_name) = SVG_STRUCT.recursive_template(src_child.(comp_name), ...
                        tgt_child.(comp_name), src_border, tgt_border);
                end
            else
                tgt_child = SVG_STRUCT.transform(src_child, src_border, tgt_border); 
            end
        end
        function parent = recursive_children_second_parse(parent, child) 
            if isfield(child, 'LABEL')  
                lbl = child.LABEL; 
                child = rmfield(child, 'LABEL'); 
                parent.(lbl) = child;
            else 
                if isfield(child, 'TEMPLATE') && isfield(child, 'GROUP')   
                    tmplt = child.TEMPLATE; 
                    group = child.GROUP;
                    has_children = isfield(child, 'Children'); 
                    raw_template = strcmp(tmplt, 'none'); 
                    
                    if has_children && raw_template
                        for kid = child.Children
                            child = SVG_STRUCT.recursive_children_second_parse(child, kid{:});
                        end
                        child = rmfield(child, 'Children'); 
                    end
                    if ~has_children && ~raw_template 
                        if ~isfield(parent, tmplt)
                            error('There is no corresonding template named ''%s'' in the parent', tmplt);                         
                        end                        
                        template_obj = parent.(tmplt);
                        child = SVG_STRUCT.copy_template(template_obj, child);
                    end 
                    
                    if has_children && ~raw_template
                        error('There cannot be grandkids if using a valid template');                        
                    end
                    if ~has_children && raw_template 
                        error('There needs to be grandkids if not using a template') ;
                    end 
                    
                    if isfield(child, {'GROUP', 'TEMPLATE'}) 
                        child = rmfield(child, {'GROUP', 'TEMPLATE'}); 
                    end
                    parent.(group) = child; 
                    
                else
                    error(['The child needs to be having a either a LABEL or '...
                        'a pair of (TEMPLATE, GROUP)']); 
                end
            end
        end 
        function res_child = recursive_children_first_parse(parent, dimensions, possible_fields)
            res_child = struct();
            for i_field = 1:length(possible_fields)
                field = possible_fields{i_field};
                val = SVG_STRUCT.return_atrr_val(parent,field);
                if ~isnan(val)
                    res_child.(field) = val;
                end                
            end
            if isfield(res_child, 'LABEL') || ...
                (isfield(res_child, 'GROUP') && isfield(res_child, 'x'))
                res_child = SVG_STRUCT.normalize_dimensions(...
                    res_child, dimensions.width, dimensions.height); 
            end
            if isfield(parent, 'Children')
                children = SVG_STRUCT.return_nonempty_obj([parent.Children]);
                if ~isempty(children)
                    for i_child = 1:length(children)
                        child_i = children(i_child);
                        res_child.Children(i_child) = ...
                            { SVG_STRUCT.recursive_children_first_parse(...
                                child_i, dimensions, possible_fields) };
                    end
                end
            end
        end
    end
end