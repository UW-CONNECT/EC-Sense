% Change VWC, reader height and tag depth here for different settings.
function [loss_top_tag, loss_tag_in_soil] = compute_theoretical_pathlosses(VWC,reader_height,tag_depth)

    freq = 915e6;
    tag_distance = 0.3;
    reader_loc.x = tag_distance * 0;
    reader_loc.y = tag_distance * 0;
    reader_loc.z = reader_height;
    snr = -1;
    
    n_tags_x = 1;
    n_tags_y = 1;
    total_n_tags = n_tags_x * n_tags_y;
    tag_locs = [];
    for i = 1:n_tags_x
        for j = 1:n_tags_y
            tag_locs(i, j).x = tag_distance * (i - 1);
            tag_locs(i, j).y = tag_distance * (j - 1);
            tag_locs(i, j).z = tag_depth;
        end
    end
    
    % dis_reader_to_tag_horizontal = [];
    % for i = 1:n_tags_x
    %     for j = 1:n_tags_y
    %         dis_reader_to_tag_horizontal(i, j) = sqrt((tag_locs(i, j).x - reader_loc.x)^2 + (tag_locs(i, j).y - reader_loc.y)^2);
    %     end
    % end
    
    %% 
    losses_top_tag = [];
    losses_tag_in_soil = [];
    losses_diff = [];
    for i = 1:n_tags_x
        for j = 1:n_tags_y
            [loss_top_tag, loss_tag_in_soil, loss_diff] = compute_pathloss(tag_locs(i, j), reader_loc, freq, VWC, snr);
            losses_top_tag(i,j) = loss_top_tag;
            losses_tag_in_soil(i,j) = loss_tag_in_soil;
            losses_diff(i,j) = loss_diff;
        end
    end
end
% total_path_length = path_length_in_air + soil_n .* path_length_in_soil;
% fprintf('loss range: %.2f - %.2f\n', min(losses_diff(:)), max(losses_diff(:)))
%%
% figure(1);clf;
% imagesc(losses_tag_in_soil);
% colormap summer
% h = colorbar;
% % caxis([1.4 2.2]);
% % caxis([2 2.8]);
% h.Label.String = 'Path loss (dB)';
% ax = gca;
% ax.XTick = 1:n_tags_x;
% ax.YTick = 1:n_tags_y;
% xlabel('Tag index along x axis');
% ylabel('Tag index along y axis');
% set(gca,'FontSize',20);

% figure(2);clf;
% imagesc(path_length_in_soil);
% colormap summer
% colorbar

% %%
% % rel_total_path_length = path_length_in_air + soil_n .* path_length_in_soil - path_length_top_tags;
% figure(2);clf;
% imagesc(losses_diff);
% colormap summer
% h = colorbar;
% % caxis([10.2 11.6]);
% % caxis([3.2 4.6]);
% h.Label.String = 'Pathloss difference (dB)';
% ax = gca;
% ax.XTick = 1:n_tags_x;
% ax.YTick = 1:n_tags_y;
% xlabel('Tag index along x axis');
% ylabel('Tag index along y axis');
% set(gca,'FontSize',20);
