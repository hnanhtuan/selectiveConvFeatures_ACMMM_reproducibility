% run('../tools/vlfeat-0.9.21/toolbox/vl_setup');
% 
% files = {'all_souls_000000', 'all_souls_000001', 'all_souls_000002', 'all_souls_000003', 'all_souls_000005'};
% for i=1:length(files)
%     sift1 = load(['/home/tdo/Documents/TuanHoang/sift/' files{i} '.mat']);
%     I = imread(['datasets/oxford/' files{i} '.jpg']);
% 
%     max_img_dim = 1024;
%     ratio = max_img_dim/max(size(I, 1), size(I, 2));
%     I = imresize(I, ratio);
%     I = single(rgb2gray(I));
% 
%     for peak_thresh=4
%         for edge_thresh=10
%             [f, d] = vl_sift(I, 'PeakThresh', peak_thresh, 'edgethresh', edge_thresh);
%             fprintf('%s - %.02f - %.02f - %d - %d\n', ...
%                     files{i}, peak_thresh, edge_thresh, size(f, 2), size(sift1.f, 2));
%         end
%     end
% end

datadir = 'features/holidays_31_1024/holidays/';
filelist = dir([datadir, '*.mat']);
parfor i=1:length(filelist)
    filename = filelist(i).name;
    if isempty(strfind(filename, '_sift'))
        movefile([datadir, filename], ...
                 [datadir, strrep(filename, '.mat', '_fea.mat')]);
    end
end