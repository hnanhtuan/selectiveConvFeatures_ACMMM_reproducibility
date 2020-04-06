% Please modify the following paths appropriately.
run('../tools/matconvnet-1.0-beta25/matlab/vl_setupnn.m')
run('../tools/vlfeat-0.9.21/toolbox/vl_setup')

%% Parameters
modelfn     = 'imagenet-vgg-verydeep-16.mat';
if ~exist(modelfn, 'file')
    websave(modelfn, 'http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-16.mat');
end

max_img_dim  = 1024;           % Resize to have max(W, H)=max_img_dim
baseDir      = 'datasets/';    % Image folder
outputDir    = 'features/';    % Folder for conv. features
extract_SIFT = false;          % Extract the SIFT locations
oxford_paris = true;

lids         = [20, ...             % For vgg conv4.1
                22, ...             % For vgg conv4.2
                24, ...             % For vgg conv4.3
                27, ...             % For vgg conv5.1
                29];                % For vgg conv5.2
for lid=lids
    net = load(modelfn);
    net.layers{lid} = net.layers{31};
    net.layers = {net.layers{1:lid}}; % remove fully connected layers
    net = vl_simplenn_tidy(net);
    net = vl_simplenn_move(net, 'gpu') ;

    folder_suffix = [num2str(lid),'_', num2str(max_img_dim)];

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
end
