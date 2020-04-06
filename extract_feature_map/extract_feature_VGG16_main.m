% Please modify the following paths appropriately.
run('../tools/matconvnet-1.0-beta25/matlab/vl_setupnn.m')
run('../tools/vlfeat-0.9.21/toolbox/vl_setup')

%% Parameters
modelfn      = 'imagenet-vgg-verydeep-16.mat';
lid          = 31;             % The index of conv. layer to extract features.
max_img_dim  = 1024;           % Resize to have max(W, H)=max_img_dim
baseDir      = 'datasets/';    % Image folder
outputDir    = 'features/';    % Folder for conv. features
extract_SIFT = true;          % Extract the SIFT locations

if ~exist(modelfn, 'file')
    fprintf('Downloading %s ...\n', modelfn);
    websave(modelfn, 'http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-16.mat');
end

net = load(modelfn);
net.layers = {net.layers{1:lid}}; % remove fully connected layers
net = vl_simplenn_tidy(net);
net = vl_simplenn_move(net, 'gpu') ;

folder_suffix = [num2str(lid),'_', num2str(max_img_dim)];

%% Select the dataset 
oxford_paris = true;
flickr100k   = true;       
% Please note that flickr100k feature need to be extracted before
% extracting feature for holidays datasets
holidays     = true;


%% Oxford5k - Paris6k
if (oxford_paris)
im_folder_oxford  = [baseDir, 'oxford5k/'];
im_folder_paris   = [baseDir, 'paris6k/'];

out_folder_oxford = [outputDir, 'oxford5k_', folder_suffix, '/'];
out_folder_paris  = [outputDir, 'paris6k_', folder_suffix, '/'];
base_set_paris    = [out_folder_paris, 'paris6k/'];
query_set_paris   = [out_folder_paris, 'paris6kq/'];
base_set_oxford   = [out_folder_oxford, 'oxford5k/'];
query_set_oxford  = [out_folder_oxford, 'oxford5kq/'];

if (~exist(outputDir, 'dir')),         mkdir(outputDir); end;
if (~exist(out_folder_oxford, 'dir')), mkdir(out_folder_oxford); end;
if (~exist(out_folder_paris, 'dir')),  mkdir(out_folder_paris);  end;
if (~exist(base_set_paris, 'dir')),    mkdir(base_set_paris);    end;
if (~exist(query_set_paris, 'dir')),   mkdir(query_set_paris);   end;
if (~exist(base_set_oxford, 'dir')),   mkdir(base_set_oxford);   end;
if (~exist(query_set_oxford, 'dir')),  mkdir(query_set_oxford);  end;


gnd_oxford = load('gnd_oxford5k.mat');
gnd_paris  = load('gnd_paris6k.mat');    

fprintf('Extracting features\n');

for i=1:length(gnd_paris.imlist)
    I = imread([im_folder_paris, gnd_paris.imlist{i}, '.jpg']);
    ratio = max_img_dim/max(size(I, 1), size(I, 2));
    I = imresize(I, ratio);
    
    % conv feature
    fea = extract_feature( I, net );
    save([base_set_paris, gnd_paris.imlist{i}, '_fea.mat'], 'fea');
    
    if extract_SIFT
        % sift location
        I = single(rgb2gray(I));
        [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
        H = size(I, 1); W = size(I, 2);
        save([base_set_paris, gnd_paris.imlist{i}, '_sift.mat'], 'f', 'W', 'H');
    end
    
    disp([num2str(i), ' --- ', gnd_paris.imlist{i}]);	
end

for i=1:length(gnd_oxford.imlist)
    I = imread([im_folder_oxford, gnd_oxford.imlist{i}, '.jpg']);
    ratio = max_img_dim/max(size(I, 1), size(I, 2));
    I = imresize(I, ratio);
    
    fea = extract_feature( I, net );
    save([base_set_oxford, gnd_oxford.imlist{i}, '_fea.mat'], 'fea');
    
    if extract_SIFT
        % sift location
        I = single(rgb2gray(I));
        [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
        H = size(I, 1); W = size(I, 2);
        save([base_set_oxford, gnd_oxford.imlist{i}, '_sift.mat'], 'f', 'W', 'H');
    end
    
    disp([num2str(i), ' --- ', gnd_oxford.imlist{i}]);	
end

qimlist = {gnd_oxford.imlist{gnd_oxford.qidx}};
for i=1:length(qimlist)
    I = imread([im_folder_oxford, qimlist{i}, '.jpg']);
    ratio = max_img_dim/max(size(I, 1), size(I, 2));
    I = crop_qim([im_folder_oxford, qimlist{i}, '.jpg'], gnd_oxford.gnd(i).bbx);
    I = imresize(I, ratio);
    
    fea = extract_feature( I, net );
    save([query_set_oxford, qimlist{i}, '_fea.mat'], 'fea');
    
    if extract_SIFT
        % sift location
        I = single(rgb2gray(I));
        [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
        H = size(I, 1); W = size(I, 2);
        save([query_set_oxford, qimlist{i}, '_sift.mat'], 'f', 'W', 'H');
    end
    disp([num2str(i), ' --- ', qimlist{i}]);	
end

qimlist = {gnd_paris.imlist{gnd_paris.qidx}};
for i=1:length(qimlist)
    I = imread([im_folder_paris, qimlist{i}, '.jpg']);
    ratio = max_img_dim/max(size(I, 1), size(I, 2));
    I = crop_qim([im_folder_paris, qimlist{i}, '.jpg'], gnd_paris.gnd(i).bbx);
    I = imresize(I, ratio);
    
    fea = extract_feature( I, net );
    save([query_set_paris, qimlist{i}, '_fea.mat'], 'fea');
    
        if extract_SIFT
        % sift location
        I = single(rgb2gray(I));
        [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
        H = size(I, 1); W = size(I, 2);
        save([query_set_paris, qimlist{i}, '_sift.mat'], 'f', 'W', 'H');
    end
    
    disp([num2str(i), ' --- ', qimlist{i}]);	
end

system(['ln -sv ' pwd '/' out_folder_oxford 'oxford5k/ ' pwd '/' out_folder_paris 'oxford5k']);
system(['ln -sv ' pwd '/' out_folder_oxford 'oxford5kq/ ' pwd '/' out_folder_paris 'oxford5kq']);
system(['ln -sv ' pwd '/' out_folder_paris 'paris6k/ ' pwd '/' out_folder_oxford 'paris6k']);
system(['ln -sv ' pwd '/' out_folder_paris 'paris6kq/ ' pwd '/' out_folder_oxford 'paris6kq']);
end

%% 
if(flickr100k)
    im_folder  = [baseDir, 'oxc1_100k/'];
    out_folder = [outputDir, 'flickr100k_', folder_suffix, '/'];
    
    if (~exist(outputDir, 'dir')),  mkdir(outputDir); end;
    if (~exist(out_folder, 'dir')), mkdir(out_folder); end;
    
    subDirList = dir([im_folder]);
    subDirList(1:2) = [];
    for i=1:length(subDirList)
        imlist = dir([im_folder, subDirList(i).name, '/*.jpg']);
        for j=1:length(imlist)
            try
                I = imread([im_folder, subDirList(i).name, '/', imlist(j).name]);
                if (size(I, 3) ~= 3), continue; end;
                ratio = max_img_dim/max(size(I, 1), size(I, 2));
                I = imresize(I, ratio);
                fea = extract_feature( I, net );
                save([out_folder, strrep(imlist(j).name, '.jpg', '_fea.mat')], 'fea');
                
                if extract_SIFT
                    % sift location
                    I = single(rgb2gray(I));
                    [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
                    H = size(I, 1); W = size(I, 2);
                    save([out_folder, strrep(imlist(j).name, '.jpg', '_sift.mat')], 'f', 'W', 'H');
                end

                disp([num2str(j), ' --- ', num2str(i), ' --- ' , imlist(j).name]);
            catch
                delete([im_folder, subDirList(i).name, '/', imlist(j).name]);
            end
        end
    end
end

%% Holidays original
if (holidays)
    im_folder  = [baseDir, 'holidays_original/'];
    out_folder = [outputDir, 'holidays_original_', folder_suffix, '/'];
    base_set   = [out_folder, 'holidays_original/'];
    
    if (~exist(outputDir, 'dir')),  mkdir(outputDir); end;
    if (~exist(out_folder, 'dir')), mkdir(out_folder); end;
    if (~exist(base_set, 'dir')),   mkdir(base_set); end;

    imlist     = dir([im_folder, '*.jpg']);

    for i=1:length(imlist)
        orig = imread([im_folder, imlist(i).name]);
        ratio = max_img_dim/max(size(orig, 1), size(orig, 2));
        I = imresize(orig, ratio);
        fea = extract_feature( I, net );
        save([base_set, strrep(imlist(i).name, '.jpg', '_fea.mat')], 'fea');
        
        if extract_SIFT
            % sift location
            I = single(rgb2gray(I));
            [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
            H = size(I, 1); W = size(I, 2);
            save([base_set, strrep(imlist(i).name, '.jpg', '_sift.mat')], 'f', 'W', 'H');
        end
        
        disp([num2str(i), ' --- ', imlist(i).name]);	
    end
    system(['ln -sv ' pwd '/' out_folder 'holidays_original/ ' pwd '/' out_folder 'holidays_originalq']);
    
    % random sample 5000 samples from Flickr100k, called Flickr5k
    out_folder_flickr5k = [outputDir, 'flickr5k_', folder_suffix, '/'];
    in_folder = [outputDir, 'flickr100k_', folder_suffix, '/'];
    if (~exist(out_folder_flickr5k, 'dir')), mkdir(out_folder_flickr5k); end;   
    file_list = dir([in_folder, '*_fea.mat']);
    rand_idx = randperm(length(file_list));
    for i=1:5000
        copyfile([in_folder, file_list(rand_idx(i)).name], ...
                 [out_folder_flickr5k, file_list(rand_idx(i)).name]);
        if extract_SIFT
            copyfile([in_folder, strrep(file_list(rand_idx(i)).name, '_fea.mat', '_sift.mat')], ...
                 [out_folder_flickr5k, strrep(file_list(rand_idx(i)).name, '_fea.mat', '_sift.mat')]);
        end
    end
    system(['ln -sv ' pwd '/' out_folder_flickr5k  '  ' pwd '/' out_folder 'flickr5k']);
end

%% Holidays rotated
if (holidays)
    im_folder  = [baseDir, 'holidays_rotated/'];
    out_folder = [outputDir, 'holidays_rotated_', folder_suffix, '/'];
    base_set   = [out_folder, 'holidays_rotated/'];
    
    if (~exist(outputDir, 'dir')),  mkdir(outputDir); end;
    if (~exist(out_folder, 'dir')), mkdir(out_folder); end;
    if (~exist(base_set, 'dir')),   mkdir(base_set); end;

    imlist     = dir([im_folder, '*.jpg']);

    for i=1:length(imlist)
        orig = imread([im_folder, imlist(i).name]);
        ratio = max_img_dim/max(size(orig, 1), size(orig, 2));
        I = imresize(orig, ratio);
        fea = extract_feature( I, net );
        save([base_set, strrep(imlist(i).name, '.jpg', '_fea.mat')], 'fea');
        
        if extract_SIFT
            % sift location
            I = single(rgb2gray(I));
            [f, ~] = vl_sift(I, 'PeakThresh', 4, 'edgethresh', 10);
            H = size(I, 1); W = size(I, 2);
            save([base_set, strrep(imlist(i).name, '.jpg', '_sift.mat')], 'f', 'W', 'H');
        end
        
        disp([num2str(i), ' --- ', imlist(i).name]);	
    end
    system(['ln -sv ' pwd '/' out_folder 'holidays_rotated/ ' pwd '/' out_folder 'holidays_rotatedq']);
    
    system(['ln -sv ' pwd '/' out_folder_flickr5k  '  ' pwd '/' out_folder 'flickr5k']);
end