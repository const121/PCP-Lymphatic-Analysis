clear;
clc; 
close all;

% Change fluorescent intensity so that all valve cells are included
fluorescent_intensity = 80;

%% Load Data
%
csv_file = "/Volumes/cbs_lab_mcetera/Isabel/Lp_valve_data_for_scatterplot/1099.10_Lp/STARDIST/MAX_M1099.10_LP_P_10.csv"; 
nuclei_data = readtable(csv_file);

tif_file = "/Volumes/cbs_lab_mcetera/Isabel/Lp_valve_data_for_scatterplot/1099.10_Lp/STARDIST/MAX_M1099.10_LP_P_10.tif";
vessel_image = imread(tif_file);

%% Filter data

% Filter Data Based on Fluorescent (percentile) and Area
mean_area = mean(nuclei_data.Area);
lower_cutoff = max(mean_area - (mean_area/2), 0);
upper_cutoff = max(nuclei_data.Area);
intensity_threshold = prctile(nuclei_data.Mean, fluorescent_intensity);

filtered_data = nuclei_data(nuclei_data.Area >= lower_cutoff & ...
                            nuclei_data.Area <= upper_cutoff & ...
                            nuclei_data.Mean >= intensity_threshold, :);

% Extract Parameters
x_coords = filtered_data.X;
y_coords = filtered_data.Y;
full_roi_angles = mod(filtered_data.Angle, 180);
major_axis = filtered_data.Feret / 2;
minor_axis = filtered_data.MinFeret / 2;




%% Figure 1: Define Vessel Midline
figure(1);
enhanced_image = imadjust(vessel_image);  
clf;
imshow(enhanced_image);
title('Figure 1: Define Vessel Midline');
[x_vessel, y_vessel] = ginput(2);

%% Analysis

% Compute Vessel Angle
delta_y = y_vessel(2) - y_vessel(1);
delta_x = x_vessel(2) - x_vessel(1);
vessel_angle = atan2d(delta_y, delta_x);
vessel_angle = mod(vessel_angle, 180);
vessel_angle = 180 - vessel_angle;

% Compute Cyclic Angle Difference
raw_diff = abs(full_roi_angles - vessel_angle);
angle_diff = min(raw_diff, 180 - raw_diff);
norm_angles = angle_diff / 180;

%% Define Colormaps
num_colors = 256;

% CYM Colormap (for cyclic angle differences)
CYM = [1, 1, 0; 1, 0, 1; 1, 1, 0];
cym_colormap = interp1(linspace(0, 1, size(CYM, 1)), CYM, linspace(0, 1, num_colors));
color_indices = max(1, min(round(norm_angles * (num_colors - 1)) + 1, num_colors));

% AR Colormap (Light Green to Mid Blue)
light_green = [0.6, 1, 0.6];
mid_blue = [0.2, 0.4, 1];
ar_colormap = interp1([0, 1], [light_green; mid_blue], linspace(0, 1, num_colors));

% Distance Colormap (Light to Dark Red)
light_red = [1, 0.8, 0.8];
dark_red = [0.5, 0, 0];
red_gradient_colormap = interp1([0, 1], [light_red; dark_red], linspace(0, 1, num_colors));

%% Figure 2: Nuclei Overlays
figure(2);
clf;
imshow(vessel_image);
hold on;
title('Figure 2: Nuclei Overlays');
all_patch_handles = gobjects(length(x_coords), 1);
for i = 1:length(x_coords)
    this_color = cym_colormap(color_indices(i), :);
    angle_rad = -deg2rad(full_roi_angles(i));
    t = linspace(0, 2*pi, 100);
    ellipse_x = major_axis(i) * cos(t);
    ellipse_y = minor_axis(i) * sin(t);
    Rmat = [cos(angle_rad), -sin(angle_rad); sin(angle_rad), cos(angle_rad)];
    rotated_coords = Rmat * [ellipse_x; ellipse_y];
    ellipse_x_rot = rotated_coords(1,:) + x_coords(i);
    ellipse_y_rot = rotated_coords(2,:) + y_coords(i);
    all_patch_handles(i) = fill(ellipse_x_rot, ellipse_y_rot, this_color, ...
                                'FaceAlpha', 0.7, 'EdgeColor', 'none');
    text(x_coords(i), y_coords(i), sprintf('%d', filtered_data.Var1(i)), ...
        'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end
title('Figure 2: Click overlays to remove. Blue dot = clicked. Press Enter when done.');

%% Hand Correct

% User Correction
disp('Click on overlays you want to remove. Press Enter when done.');
to_delete = false(height(filtered_data), 1);
delete_radius = 10;
while true
    [x_click, y_click, button] = ginput(1);
    if isempty(button)
        break;
    end
    plot(x_click, y_click, 'bo', 'MarkerSize', 8, 'LineWidth', 1.5);
    distances = sqrt((x_coords - x_click).^2 + (y_coords - y_click).^2);
    [min_dist, idx] = min(distances);
    if min_dist < delete_radius
        to_delete(idx) = true;
        delete(all_patch_handles(idx));
    end
end

% Remove deleted data
filtered_data = filtered_data(~to_delete, :);
x_coords = x_coords(~to_delete);
y_coords = y_coords(~to_delete);
full_roi_angles = full_roi_angles(~to_delete);
major_axis = major_axis(~to_delete);
minor_axis = minor_axis(~to_delete);
angle_diff = angle_diff(~to_delete);
color_indices = color_indices(~to_delete);

disp('Overlay removal complete.');
close(1); 
close(2)

%% Figure 3: Corrected Overlays
figure(3); 
clf;
imshow(vessel_image);
hold on;
title('Figure 3: Corrected Overlays');
for i = 1:length(x_coords)
    this_color = cym_colormap(color_indices(i), :);
    angle_rad = -deg2rad(full_roi_angles(i));
    t = linspace(0, 2*pi, 100);
    ellipse_x = major_axis(i) * cos(t);
    ellipse_y = minor_axis(i) * sin(t);
    Rmat = [cos(angle_rad), -sin(angle_rad); sin(angle_rad), cos(angle_rad)];
    rotated_coords = Rmat * [ellipse_x; ellipse_y];
    ellipse_x_rot = rotated_coords(1,:) + x_coords(i);
    ellipse_y_rot = rotated_coords(2,:) + y_coords(i);
    fill(ellipse_x_rot, ellipse_y_rot, this_color, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
end
hold off;
drawnow;

%% Figure 4: Original Raw ROI Angles
figure(4); 
clf;
imshow(vessel_image);
hold on;
plot(x_vessel, y_vessel, 'r-', 'LineWidth', 2);
for i = 1:length(x_coords)
    text(x_coords(i), y_coords(i), sprintf('%.1f\xB0', full_roi_angles(i)), ...
        'Color', 'g', 'FontSize', 8, 'HorizontalAlignment', 'center');
end
title('Figure 4: Original Raw ROI Angles');
hold off;
drawnow;

%% Figure 5: Cyclic ROI Angle Differences
figure(5); 
clf;
imshow(vessel_image);
hold on;
plot(x_vessel, y_vessel, 'r-', 'LineWidth', 2);
for i = 1:length(x_coords)
    text(x_coords(i), y_coords(i), sprintf('%.1f\xB0', angle_diff(i)), ...
        'Color', 'y', 'FontSize', 8, 'HorizontalAlignment', 'center');
end
title('Figure 5: Cyclic ROI Angle Differences Relative to Vessel');
hold off;
drawnow;

%% Figure 6: AR Overlays
figure(6);
clf;
imshow(vessel_image);
hold on;
title('Figure 6: Aspect Ratio (AR) Overlays: Light Green to Blue');
num_colors_ar = 256;
light_green = [0.6, 1, 0.6];
mid_blue    = [0.2, 0.4, 1];
AR_colormap = interp1([0, 1], [light_green; mid_blue], linspace(0, 1, num_colors_ar));
clamped_AR = max(1, min(filtered_data.AR, 3));
norm_AR = (clamped_AR - 1) / (3 - 1);
color_indices_AR = round(norm_AR * (num_colors_ar - 1)) + 1;
for i = 1:length(x_coords)
    this_color = AR_colormap(color_indices_AR(i), :);
    angle_rad = -deg2rad(full_roi_angles(i));
    t = linspace(0, 2*pi, 100);
    ellipse_x = major_axis(i) * cos(t);
    ellipse_y = minor_axis(i) * sin(t);
    Rmat = [cos(angle_rad), -sin(angle_rad); sin(angle_rad), cos(angle_rad)];
    rotated_coords = Rmat * [ellipse_x; ellipse_y];
    ellipse_x_rot = rotated_coords(1,:) + x_coords(i);
    ellipse_y_rot = rotated_coords(2,:) + y_coords(i);
    fill(ellipse_x_rot, ellipse_y_rot, this_color, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
end
hold off;
drawnow;

%% Figure 7: Distance to Vessel Midline (Red Gradient)
figure(7);
clf;
imshow(vessel_image);
hold on;
title('Figure 7: Distance to Vessel Midline: Light to Dark Red');
dx = x_vessel(2) - x_vessel(1);
dy = y_vessel(2) - y_vessel(1);
vessel_vec = [dx; dy];
vessel_norm_sq = dx^2 + dy^2;
distances = zeros(length(x_coords), 1);
for i = 1:length(x_coords)
    point_vec = [x_coords(i) - x_vessel(1); y_coords(i) - y_vessel(1)];
    t = dot(point_vec, vessel_vec) / vessel_norm_sq;
    closest_point = [x_vessel(1); y_vessel(1)] + t * vessel_vec;
    distances(i) = norm([x_coords(i); y_coords(i)] - closest_point);
end
clamped_distances = min(distances, prctile(distances, 98));
norm_distances = clamped_distances / max(clamped_distances);
normalized_distances = (distances / max(distances)) * 100;
color_indices_dist = round(norm_distances * (num_colors_ar - 1)) + 1;
for i = 1:length(x_coords)
    this_color = interp1([0, 1], [[1 0.8 0.8]; [0.5 0 0]], norm_distances(i));
    angle_rad = -deg2rad(full_roi_angles(i));
    t = linspace(0, 2*pi, 100);
    ellipse_x = major_axis(i) * cos(t);
    ellipse_y = minor_axis(i) * sin(t);
    Rmat = [cos(angle_rad), -sin(angle_rad); sin(angle_rad), cos(angle_rad)];
    rotated_coords = Rmat * [ellipse_x; ellipse_y];
    ellipse_x_rot = rotated_coords(1,:) + x_coords(i);
    ellipse_y_rot = rotated_coords(2,:) + y_coords(i);
    fill(ellipse_x_rot, ellipse_y_rot, this_color, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
end
plot(x_vessel, y_vessel, 'b-', 'LineWidth', 2);
hold off;
drawnow;

% %% Figure Legends
% 
% % Figure 8: CYM Legend
% figure(8);
% legend_strip = repmat(linspace(0, 1, num_colors), 40, 1);
% imagesc(legend_strip);
% colormap(cym_colormap);
% axis off;
% title('Figure 8: CYM Colormap Legend');
% c = colorbar('Ticks', linspace(0, 1, 5), 'TickLabels', {'0\xB0', '45\xB0', '90\xB0', '45\xB0', '0\xB0'});
% c.Label.String = 'Cyclic Angle Difference';
% 
% % Figure 9: Distance Legend
% figure(9);
% legend_strip_dist = repmat(linspace(0, 1, num_colors_ar), 40, 1);
% imagesc(legend_strip_dist);
% colormap(interp1([0, 1], [[1 0.8 0.8]; [0.5 0 0]], linspace(0, 1, num_colors_ar)));
% axis off;
% title('Figure 9: Distance Colormap Legend (Red Gradient)');
% cb = colorbar('Ticks', linspace(0, 1, 5), 'TickLabels', {'0', '25%', '50%', '75%', 'Max'});
% cb.Label.String = 'Distance to Vessel Midline (relative)';
% 
% % Figure 10: AR Legend
% figure(10);
% legend_strip_AR = repmat(linspace(0, 1, num_colors_ar), 40, 1);
% imagesc(legend_strip_AR);
% colormap(AR_colormap);
% axis off;
% title('Figure 10: Aspect Ratio (AR) Colormap Legend');
% cb = colorbar('Ticks', linspace(0, 1, 5), 'TickLabels', {'1', '1.5', '2', '2.5', '3'});
% cb.Label.String = 'Aspect Ratio (AR)';

%% Save Data
output_table = table(filtered_data.Var1, angle_diff, filtered_data.AR, ...
                     distances, normalized_distances, ...
                     'VariableNames', {'Var1', 'AngleDifference', 'AR', ...
                                       'DistanceToMidline', 'DistanceToMidline_Percent'});

[filename, pathname] = uiputfile('*.csv', 'Save filtered cells angle differences and AR as');
if isequal(filename,0) || isequal(pathname,0)
    disp('User canceled file saving.');
else
    fullFileName = fullfile(pathname, filename);
    writetable(output_table, fullFileName);
    fprintf('File saved: %s\n', fullFileName);
end
