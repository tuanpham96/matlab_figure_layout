
# FigLay MATLAB
### *Figure layout planning in `Inkscape` & `MATLAB` for easily-reproducible figures*  
This function is for planning figure layout in Inkscape (to produce tagged `.svg` files) before plotting sub panels in `MATLAB`.   
The reason I wrote this function was because of the manual labor of deciding the subplot positions in `MATLAB`.  
  
## Prerequisites  
* Basic usuage of `Inkscape` (customizing rectangles and `XML editors`). I am using `Inkscape v0.92` with `SVG 1.1`.
* `MATLAB` (so far I have been using `MATLAB R2016a`). I am unsure if earlier versions would have issues. 

## Inspirations  
The idea of using `Inkscape` to create a tagged `.svg` file is from the package in `python` called `FigureFirst`, which parses `.svg` file to read in axes position for `matplotlib`. Specifically, the github link is https://github.com/FlyRanch/figurefirst. I was inspired by this to create one for `MATLAB` users.


## Instructions
The general steps include:
1. creating an `.svg` file in `Inkscape` with desired layout and specific tags; then
2. parsing the file for the positions to use for subplots in `MATLAB`. 

### Create layout file in `Inkscape` 
All layout object needs to be in the same **layer**. For simplicity, at the end of your layout design, please move everything to **layer 1**. More importantly, this layer needs to be tagged with another attribute in order to be parsed. Specifically, please create a new attribute named `TAG` with value `LAYOUT` (both names and values are case-sensitive)

There are three classes of objects:
 1. **PS**: *position-specific*. PS is an`Inkscape` *rectangle* whose position will be parsed and generic label annotated.   
 2. **GS**: *group-specific*. GS is a `Inkscape` *group* of a combination of the three classes. Its children's positions must be resolved within the group itself.  They can be used as template to construct **GT**'s within the same level. 
 3. **GT**: *group-template*. GT is an `Inkscape` *rectangle* whose positions will be parsed to construct its children from a template of a **GS**. 

Each **PS** in the layout needs to be a **rectangular** object and have the required **SVG attributes** as to be discussed. 
- The subplot positions are obtained by parsing the attributes `x, y, width, height` of the rectangular object. 
- Besides these attributes, it also requires adding a new attribute named `LABEL`, with the value like `figure`, `annotation`, `inset`, `colorbar` (case-sensitive). The values of `LABEL` is not constrained so the user should be able to name whatever they like, as long as it follows the rule of naming `MATLAB` variables. 
- The attribute `style` does not matter so customization of colors, fill, stroke of the rectangle does not matter, but can be visually helpful to differentiate between different types (e.g: red for `figures`, blue for `annotation`, orange for `inset`, etc.). 
- Importantly, **PS** cannot be left without belonging to a group like **GS** or **GT**. `GROUP` attribute (e.g: `A`, `B`) in either would be concatenated to the `LABEL` of **PS** like `A_figure`, `B_inset`. 

Each **GS** in the layout is an `Inkscape` **group**. 
- It needs adding of two attributes: `GROUP` and `TEMPLATE` (case-sensitive). `GROUP`'s value can be anything, usually `A`, `sub1`, as long as it follows the rules of `MATLAB` variable naming convention.  
- `TEMPLATE`'s value **needs** to set to **`raw`** in this case, because it does not use anything template to construct its children's positions. 
- Its children can be a combination of **PS, GS, GT**, as long as each child follows the guidelines listed here for each class.
- When planning, the requirement of **GS** is: its children's positions must be resolved within the group itself; hence, the word *specific*. 
- Additionally, if another **GT** uses it as a template, a **GS** needs to have a **PS** child with attribute `LABEL=border`(case-sensitive). See below for more explanation. 
- Importantly, each **GT** object cannot have any attribute named `transformation`, which happens in `Inkscape` when you move/scale a group of objects instead of each single one. This means that you should finalize the positions of the children before grouping. If you move it just ungroup then regroup and add the `TEMPLATE` and `GROUP` again. I'm looking for solutions of this. 

Each **GT** is an `Inkscape` **rectangle**.
- It needs to adding of two attributes:  `GROUP` and `TEMPLATE` (case-sensitive). `GROUP`'s value can be anything, usually `A`, `sub1`, as long as it follows the rules of `MATLAB` variable naming convention.  
-  `TEMPLATE`'s value needs to be the value in `GROUP` of another **GS**. The **GS** needs to be created before the creation of the **GT**. For example, if I created a **GS** with `GROUP=A` for subplot A and I want to create a **GT** for subplot B using template of subplot A, the **GT**'s new attributes are: `GROUP=B` and `TEMPLATE=A`. 
-  As mentioned, if a **GT** (B) wants to use a template from a **GS** (A), A needs to have a **PS** with its `LABEL = border` (case-sensitive). Since B is an `Inkscape` rectangle, the parsing performs a transformation (translation and scaling) of all A'children using A's `border` as A's coordinate system and B's position-related attributes as B's coordinate system. 
- The children within one group can only use the template at that level of the group. Meaning each child can only use its siblings' template. 

### Parse and use the layout in `MATLAB`
Once the file is finalized. Do this to parse and read the dimensions. 
```
svg_parsed = FigureLayout(file_name); 
dimensions = svg_parsed.dimensions; 
layout = svg_parsed.layout; 
```
#### Setting the right dimension of the figure 
`dimensions` is a `struct` that saves the desired dimensions of the paper in `Inkscape`. To use it to produce your figure with the desired dimensions, you can follow the code below. 
```
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
```
Here the unit from `Inkscape` is `mm`. I manually set the conversion factor here (`conv_factor = 1/10`), However, if you use a later version of `MATLAB` (like `R2017`), you replace that with: 
```
conv_factor = double(unitConversionFactor(str2symunit(unit), str2symunit('cm')));
```
#### Setting subplot positions 
`layout` is a `struct` that saves the normalized positions. Hence, before setting your subplot position, remember to set the `Units` to `Normalized`. Each field in `layout` is another `struct`, whose field `normz_pos` is all you need. Below are some examples of how to use it, and hopefully make your life easier. Note: this is dependent on how I named the `LABEL` and `GROUP` in my `Inkscape` layout file; hence below are mostly suggestions. 
```
>> layout = 
        B_sub2_figure: [1x1 struct]
        B_sub2_legend: [1x1 struct]
    B_sub2_annotation: [1x1 struct]
               B_text: [1x1 struct]
        B_sub1_figure: [1x1 struct]
    B_sub1_annotation: [1x1 struct]
               A_text: [1x1 struct]
        A_sub1_border: [1x1 struct]
        A_sub1_figure: [1x1 struct]
      A_sub1_colorbar: [1x1 struct]
    A_sub1_annotation: [1x1 struct]
         A_sub1_inset: [1x1 struct]
         
>> layout.A_sub1_annotation
            x: 0.0202
            y: 0.8386
        width: 0.0506
       height: 0.0200
    normz_pos: [0.0202 0.8386 0.0506 0.0200]
  ```
  
Example of creating an annotation is: 
```
A1_annotation_pos = layout.A_sub1_annotation; 
annotation('textbox', 'Units', 'normalized', 'Position', A1_annotation_pos , 
    'String', 'A_1', 'FontSize', 15', <fill in your style>); 
```
Example of creating a figure subplot is: 
```
A1_axes_pos = layout.A_sub1_figure; 
A1_fig = axes('Units', 'normalized','Position', A1_axes_pos );
plot(A1_fig, ...);
title(A1_fg, ...); 
```
A faster way can be to create functions for these processes like: 
```
ann_style = {'LineStyle', 'none', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', 'FontSize', 15, 'FontWeight', 'bold'};
    
text_style = {'LineStyle', 'none', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', 'FontSize', 15, 'FontWeight', 'normal'};

create_annotation = @(lbl, string_) ...
    annotation('textbox', 'Units', 'normalized', ...
    'Position', layout.([lbl,'_annotation']).normz_pos, ...
    'String', string_, ann_style{:});

create_text = @(lbl, string_, extra_style) ...
    annotation('textbox', 'Units', 'normalized', ...
    'Position', layout.([lbl,'_text']).normz_pos, ...
    'String', string_, text_style{:}, extra_style{:});

create_figure = @(lbl) axes('Units', 'normalized', ...
    'Position', layout.([lbl,'_figure']).normz_pos);
```
Then you can do: 
```
create_text('A', 'My subplots A', {'FontName', 'Times New Roman'}); 

create_annotation('A_sub1', 'A_1');
A1_fig = create_figure('A_sub1`); 
plot(A1_fig, ...); 
...

create_annotation('A_sub2', 'A_2'); 
A2_fig = create_figure('A_sub2`); 
plot(A2_fig, ...); 
...
```