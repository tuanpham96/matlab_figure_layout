clc; close all; clear;
addpath('../code');
%% Parse the svg  
file_id = 'example_2b'; 
file_prefix = ['layout_', file_id]; 
file_name = [file_prefix, '.svg']; 
replacetextstruct = '';
svg_parsed = FigureLayout(file_name, replacetextstruct); 
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
    'PaperUnits', 'centimeters', ...  
    'PaperPositionMode', 'manual', ... 
    'PaperPosition', [0, 0, width, height]*conv_factor, ...
    'PaperSize', [width, height]*conv_factor, ... 
    'InvertHardcopy', 'off', ...
    'Color', 'w');
%% Component styles
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

create_inset = @(lbl) axes('Units', 'normalized', ...
    'Position', layout.([lbl,'_inset']).normz_pos, 'box', 'on', ...
    'ytick', '');
%% Figure A
create_text('A', 'Simple sine functions with different phases and frequencies', ...
    {'fontangle', 'italic'});

cmap_options = {'parula', 'summer', 'bone'}; 
freq_vec = [0.3, 0.5, 0.9]; 
phase_vec = [0.3, -0.3, -0.2];
n_phase = 10; 
t = -2:0.01:2;
for i = 1:3
    label = ['A_sub', num2str(i)]; 
    create_annotation(label, ['A', num2str(i)]); 
    ax = create_figure(label);      hold(ax, 'on');
    inset = create_inset(label);    hold(inset, 'on');
    
    cmap = eval([cmap_options{i}, '(', num2str(n_phase), ')']);  

    phase_vi = zeros([1,n_phase]); 
    factor = freq_vec(i) * 2 * pi; 
    for j = 1:n_phase
        phase_vi(j) = phase_vec(i) * j;         
        y = sin(factor*t + phase_vi(j)); 
        
        plot(ax, t, y, '-', 'color', cmap(j,:), 'linewidth', 1);    
        
        r_idx = randi(length(t), [1,20]);        
        plot(inset, t(r_idx), y(r_idx), '.', 'color', cmap(j,:), 'markersize', 5);
    end
    xlim(ax, t([1,end]) + [-1,1]*0.2); 
    ylim(ax, [-1.2,1.2]);
    ylabel(ax, 'Value'); 
    set(ax, 'fontsize', 10, 'xtick', '');     
    title(ax, ['Frequency = ' num2str(freq_vec(i)) ' Hz'], ...
        'fontsize', 12, 'fontweight', 'normal'); 
    
    xlabel(inset, 'Time (s)');
    xlim(inset, t([1,end]) + [-1,1]*0.2); 
    set(inset,'fontsize',10); 
    colormap(ax, cmap);
    cbar = colorbar(ax); 
    cbar_pos = layout.([label, '_colorbar']).normz_pos; 
    title(cbar, 'phase');
    cbar_show = phase_vi([1,end]);
    set(cbar, 'units', 'normalized', 'Position', cbar_pos, ...
        'Ticks', linspace(0,1,length(cbar_show)), 'TickLabels', cbar_show, ...
        'fontsize', 5, 'box', 'off'); 
end
%% Figure B1
create_text('B', 'A random pixel plot and mixed frequency sine', ...
    {'fontangle', 'italic'});
create_annotation('B_sub1', 'B1'); 
pixel = create_figure('B_sub1'); 
r_dat = rand(10); 
image(pixel, r_dat, 'CDataMapping', 'scaled'); 
colormap(pixel, 'jet'); 
pbaspect(pixel, [1,1,1]); 
set(pixel, 'fontsize', 10, 'xtick', '', 'ytick', '', 'box', 'on'); 
xlabel(pixel, 'I''m so random'); 
ylabel(pixel, 'Shut up, I am'); 
title(pixel, 'I''m a TV', 'fontsize', 12, 'fontweight', 'normal'); 

%% Figure B2
create_annotation('B_sub2', 'B2'); 
ax = create_figure('B_sub2');  hold(ax,'on'); 

freq_mix = [0.1, 0.2, 0.5, 1:2:11];
idx_freq = 1:length(freq_mix);
t = -1:0.01:5; 
line_style = {'-', '-', '-'};
color_opts = {[0.2,0.2,0.95], [0.2,0.2,0.7], [0.2, 0.2, 0.5]} ;
for i = 1:3
    idx2plt = idx_freq(mod(idx_freq,3)==i-1);
    y = 5*i;
    lgnd_name = []; 
    for j = idx2plt
        f = freq_mix(j);
        lgnd_name = [lgnd_name, f]; 
        y = y + sin(2*pi*f*t); 
    end
    lgnd_name = sprintf(' %.1f,',lgnd_name);
    lgnd_name(end) = ''; 
    lgnd_name = ['[' lgnd_name ' ] Hz']; 
    plot(ax, t, y, '-', 'linewidth', 1.25, 'DisplayName', lgnd_name, ...
        'Color', color_opts{i}); 

end
set(ax, 'fontsize', 10); 
xlabel(ax, 'Time (s)'); xlim(ax, [-1.2,5.2]); 
ylabel(ax, 'Value'); 
title(ax, 'Mixed frequencies', 'fontsize', 12, ...
    'fontweight', 'normal', 'horizontalalignment', 'right'); 

lgnd = legend(ax, 'show');
cur_lgnd_pos = lgnd.Position; 
lgnd_pos = layout.B_sub2_legend.normz_pos;
lgnd_pos(3:4) = cur_lgnd_pos(3:4); 
set(lgnd, 'units', 'normalized', 'Position', lgnd_pos, 'box', 'off', 'fontsize', 7);
%% Once finished, print it out 
print(gcf, [file_id, '_withplot'], '-dpdf'); 

