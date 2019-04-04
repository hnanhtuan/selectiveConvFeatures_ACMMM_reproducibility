run('../tools/matconvnet-1.0-beta25/matlab/vl_setupnn.m')


%% Parameters
baseDir     = 'datasets/';    % Image folder
outputDir   = 'features/';    % Folder for conv. features
max_img_dim = 1024;
lid         = 31;
folder_suffix = [num2str(lid), '_', num2str(max_img_dim), '_siaMAC'];

modelfn     = 'siaMAC_vgg.mat';
% If the model is not downloaded properly, please handle it manually.
if ~exist(modelfn, 'file')
    system(['wget --no-check-certificate https://www.dropbox.com/s/hq81glcxd2ei6qe/siaMAC_vgg.mat?dl=0 -O ', modelfn]);
end

load(modelfn);
net = dagnn.DagNN.loadobj(net) ;
net.move('gpu'); % extract on GPU
net.conserveMemory = 0;
%% Selecting dataset to extract conv. feature
paris_oxford    = false;
flickr100k      = false;
holidays        = false;

%% Flickr100k
if (flickr100k)
    im_folder  = [baseDir, 'oxc1_100k/'];
    out_folder = [outputDir, 'flickr100k_', folder_suffix, '/'];
    if (~exist(out_folder, 'dir')), mkdir(out_folder); end;
        
    subDirList = dir(im_folder);
    subDirList(1:2) = [];
    for i=1:length(subDirList)
        imlist = dir([im_folder, subDirList(i).name, '/*.jpg']);
        for j=1:length(imlist)
            try
                I = imread([im_folder, subDirList(i).name, '/', imlist(j).name]);
                if (size(I, 3) ~= 3), continue; end;
                ratio = max_img_dim/max(size(I, 1), size(I, 2));
                I = imresize(I, ratio);
                fea = mac( I, net );
                save([out_folder, strrep(imlist(j).name, '.jpg', '_fea.mat')], 'fea');

                disp([num2str(j), ' --- ', num2str(i), ' --- ' , imlist(j).name]);
            catch
                delete([im_folder, subDirList(i).name, '/', imlist(j).name]);
            end
        end
    end
end

%% Holidays
if (holidays)
    im_folder  = [baseDir, 'holidays/'];
    out_folder = [outputDir, 'holidays_', folder_suffix, '/'];
    base_set   = [out_folder, 'holidays/'];
    if (~exist(out_folder, 'dir')), mkdir(out_folder); end;
    if (~exist(base_set, 'dir')),   mkdir(base_set); end;

    imlist     = dir([im_folder, '*.jpg']);

    for i=1:length(imlist)
        orig = imread([im_folder, imlist(i).name]);
        ratio = max_img_dim/max(size(orig, 1), size(orig, 2));
        I = imresize(orig, ratio);
        fea = mac( I, net );
        save([base_set, strrep(imlist(i).name, '.jpg', '_fea.mat')], 'fea');
        
        disp([num2str(i), ' --- ', imlist(i).name]);	
    end
    system(['ln -sv ' pwd '/' out_folder 'holidays/ ' pwd '/' out_folder 'holidaysq']);
    
    % random sample 5000 samples from Flickr100k, called Flickr5k
    out_folder_flickr5k = [outputDir, 'flickr5k_', folder_suffix, '/'];
    in_folder = [outputDir, 'flickr100k_', folder_suffix, '/'];
    if (~exist(out_folder_flickr5k, 'dir')), mkdir(out_folder_flickr5k); end;
    file_list = dir([in_folder, '*_fea.mat']);
    rand_idx = randperm(length(file_list));
    for i=1:5000
        copyfile([in_folder, file_list(rand_idx(i)).name], ...
                 [out_folder_flickr5k, file_list(rand_idx(i)).name]);
    end
    system(['ln -sv ' pwd '/' out_folder_flickr5k  '  ' pwd '/' out_folder 'flickr5k']);
end

%% Oxford5k + Paris6k
if (paris_oxford)
im_folder_oxford  = [baseDir, 'oxford5k/'];
im_folder_paris   = [baseDir, 'paris6k/'];

out_folder_oxford = [outputDir, 'oxford5k_', folder_suffix, '/'];
out_folder_paris  = [outputDir, 'paris6k_', folder_suffix, '/'];
base_set_paris    = [out_folder_paris, 'paris6k/'];
query_set_paris   = [out_folder_paris, 'paris6kq/'];
base_set_oxford   = [out_folder_oxford, 'oxford5k/'];
query_set_oxford  = [out_folder_oxford, 'oxford5kq/'];

if (~exist(out_folder_oxford, 'dir')), mkdir(out_folder_oxford); end;
if (~exist(out_folder_paris, 'dir')),  mkdir(out_folder_paris);  end;
if (~exist(base_set_paris, 'dir')),    mkdir(base_set_paris);    end;
if (~exist(query_set_paris, 'dir')),   mkdir(query_set_paris);   end;
if (~exist(base_set_oxford, 'dir')),   mkdir(base_set_oxford);   end;
if (~exist(query_set_oxford, 'dir')),  mkdir(query_set_oxford);  end;

% These links should be created only 1 time.
system(['ln -sv ' pwd '/' out_folder_oxford 'oxford5k/ ' pwd '/' out_folder_paris 'oxford5k']);
system(['ln -sv ' pwd '/' out_folder_oxford 'oxford5kq/ ' pwd '/' out_folder_paris 'oxford5kq']);
system(['ln -sv ' pwd '/' out_folder_paris 'paris6k/ ' pwd '/' out_folder_oxford 'paris6k']);
system(['ln -sv ' pwd '/' out_folder_paris 'paris6kq/ ' pwd '/' out_folder_oxford 'paris6kq']);

gnd_oxford = load('gnd_oxford5k.mat');
gnd_paris  = load('gnd_paris6k.mat');  

for i=1:length(gnd_paris.imlist)
    I = imread([im_folder_paris, gnd_paris.imlist{i}, '.jpg']);
    ratio = 1024/max(size(I, 1), size(I, 2));
    if (max(size(I, 1), size(I, 2))/min(size(I, 1), size(I, 2)) > 1024/224)
        ratio = 224/min(size(I, 1), size(I, 2));
    end
    I = imresize(I, ratio);

    fea = mac( I, net );
    save([base_set_paris, gnd_paris.imlist{i}, '_fea.mat'], 'fea');
    disp([num2str(i), ' --- ', gnd_paris.imlist{i}]);	
end

qimlist = {gnd_paris.imlist{gnd_paris.qidx}};
for i=1:length(qimlist)
    I = crop_qim([im_folder_paris, qimlist{i}, '.jpg'], gnd_paris.gnd(i).bbx);
    if (min(size(I, 1), size(I, 2)) < 224)
        ratio = 224/min(size(I, 1), size(I, 2));
        I = imresize(I, ratio);
    end

    fea = mac( I, net );
    save([query_set_paris, qimlist{i}, '_fea.mat'], 'fea');
    disp([num2str(i), ' --- ', qimlist{i}]);	
end
%%
for i=1:length(gnd_oxford.imlist)
    I = imread([im_folder_oxford, gnd_oxford.imlist{i}, '.jpg']);
    ratio = 1024/max(size(I, 1), size(I, 2));
    if (max(size(I, 1), size(I, 2))/min(size(I, 1), size(I, 2)) > 1024/224)
        ratio = 224/min(size(I, 1), size(I, 2));
    end
    I = imresize(I, ratio);

    fea = mac( I, net );
    save([base_set_oxford, gnd_oxford.imlist{i}, '_fea.mat'], 'fea');
    disp([num2str(i), ' --- ', gnd_oxford.imlist{i}]);	
end
%%
qimlist = {gnd_oxford.imlist{gnd_oxford.qidx}};

for i=1:length(qimlist)
    I = crop_qim([im_folder_oxford, qimlist{i}, '.jpg'], gnd_oxford.gnd(i).bbx);
    if (min(size(I, 1), size(I, 2)) < 224)
        ratio = 224/min(size(I, 1), size(I, 2));
        I = imresize(I, ratio);
    end

    fea = mac( I, net );
    save([query_set_oxford, qimlist{i}, '_fea.mat'], 'fea');
    disp([num2str(i), ' --- ', qimlist{i}]);	
end
end