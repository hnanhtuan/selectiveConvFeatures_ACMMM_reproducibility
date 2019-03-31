addpath(genpath('utils/'));
addpath(genpath('data/'));

poolobj = gcp;
addAttachedFiles(poolobj, {'triemb_map.m', 'triemb_res.mexa64', ...
                            'qdemocratic.m', 'sinkhornm.m', ...
                            'embedding.m', 'vecpostproc.m'})

%% Dataset 
data_dir = 'extract_feature_map/features/';
work_dir = 'data/workdir/';

datasets = {'oxford5k', 'oxford105k', 'paris6k', 'paris106k', 'holidays'};  % 
mask_methods = {'sift', 'sum', 'max'};
final_dims = [512, 1024, 4096];

mAPs = zeros(length(datasets), length(mask_methods), length(final_dims));
for dataset_idx=1:length(datasets)
    dataset = datasets{dataset_idx};
    switch dataset
        case {'oxford5k', 'oxford105k'}
            dataset_train				= 'paris6k';        % dataset to learn the PCA-whitening on
            dataset_test 				= 'oxford5k';       % dataset to evaluate on 
        case {'paris6k', 'paris106k'}
            dataset_train				= 'oxford5k';       % dataset to learn the PCA-whitening on
            dataset_test 				= 'paris6k';        % dataset to evaluate on 
        case 'holidays'
            dataset_train				= 'flickr5k';       % dataset to learn the PCA-whitening on
            dataset_test 				= 'holidays';       % dataset to evaluate on 
    end
    gnd_test = load(['gnd_', dataset_test, '.mat']);

    lid         = 31;   %  conv. feature of last VGG conv. layer
    max_img_dim = 1024;

    % The 'dataset_name' should be the same folder where the extracted conv.
    % features are stored.
    dataset_name  = [dataset_test, '_', num2str(lid),'_', num2str(max_img_dim)];

    dataset_dir   = [data_dir, dataset_name, '/'];
    trainset_dir  = [dataset_dir, dataset_train, '/'];
    baseset_dir   = [dataset_dir, dataset_test, '/'];
    queryset_dir  = [dataset_dir, dataset_test, 'q/'];
    flickrset_dir = [data_dir, 'flickr100k_', num2str(lid),'_', num2str(max_img_dim), '/'];

    %% Parameters
    enc_method      = 'tembsink';
        % 'temb':      Triangular embedding + Sum pooling
        % 'tembsink':  Triangular embedding + Democratic pooling
        % 'faemb':     Fast-Function Apprximate Embdding + Democratic pooling
    
    for mask_method_idx=1:length(mask_methods)
        mask_method = mask_methods{mask_method_idx};
        
        for final_dim_idx=1:length(final_dims)
            final_dim = final_dims(final_dim_idx);
            if final_dim == 4096 && strcmp(mask_method, 'max') == 0;
                continue;
            end
            
            switch final_dim
                case 512
                    param.d         = 32;      
                    param.k         = 20;      
                case 1024
                    param.d         = 64;      
                    param.k         = 18;  
                case 2048
                    param.d         = 64;      
                    param.k         = 34;
                case 4096
                    param.d         = 64;      
                    param.k         = 66;
                case 8064
                    param.d         = 128;      
                    param.k         = 64;
            end
        
            truncate        = 128;                  % Truncate the first 128 dimensions

            filename_surfix = [ '_', enc_method, '_', mask_method ];
            disp(filename_surfix);

            save_param = true;              % Save the learned parameters for later usage
            save_data  = false;             % Save the processed global image representation for later usage
            overwrite_olddata = false;       % Re-learn the parameters and re-process image (if did).

            %% Learning parameters
            disp(['Test - ', dataset, ' - ', enc_method, ' - ', mask_method]);

            param_file = [work_dir, dataset_name, '_param_', num2str(param.k), ...
                                 '_', num2str(param.d), filename_surfix, '.mat'];

            vecs_train_file = [dataset_dir, 'vecs_train_', num2str(param.k), '_', ...
                                                num2str(param.d),  filename_surfix, '.mat'];
            if (exist(param_file, 'file') && ~overwrite_olddata)
                fprintf(2, ' * Load pretrained parameters!\n');
                load(param_file);
            else
                fprintf(2, ' * Learning parameters ... \n');
                tic
                % Read all the feature map file in 'trainSetDir' and then applying mask
                gnd_train.imlist = dir([trainset_dir, '*_fea.mat']);
                fea_train = cell(length(gnd_train.imlist), 1);
                parfor i=1:length(gnd_train.imlist)
                    fea_train{i} = apply_mask([trainset_dir, gnd_train.imlist(i).name], mask_method);
                end

                % Apply PCA to reduce data-dimension
                vtrain = cell2mat(fea_train');
                param.desc_mean = mean(vtrain, 2);
                vtrain = bsxfun (@minus, vtrain, param.desc_mean);
                Xcov = vtrain * vtrain';
                Xcov = (Xcov + Xcov') / (2 * size (vtrain, 2));     % make it more robust
                [param.U, param.S, ~] = svd( Xcov );
                clear Xcov
                param.Ud = param.U(:,1:param.d);
                vtrain = param.Ud' * vtrain;                        % PCA
                vtrain = yael_vecs_normalize(vtrain);               % L2 normalize

                switch enc_method
                    case {'temb', 'tembsink', 'tembmax'}
                        param.C = yael_kmeans (vtrain, param.k, 'init', 1, 'redo', 2, 'niter', 100);
                        [param.Xmean, param.eigvec, param.eigval] = triemb_learn (vtrain, param.C);
                        param.eigval (end-32:end) = param.eigval (end-32);
                        param.Pemb = diag(param.eigval.^-0.5) * param.eigvec';    % PCA-whitening
                end
                clear vtrain

                vecs_train = cell(length(gnd_train.imlist), 1);
                parfor i=1:length(gnd_train.imlist)
                    vecs_train{i} = vecpostproc(embedding(fea_train{i}, param, enc_method));
                end
                clear fea_train

                % Learn RN
                vecs_train = cell2mat(vecs_train');
                param = learn_rn(vecs_train, param); 
                clear vecs_train

                if (save_param), save (param_file, 'param', '-v7.3'); end;
                fprintf ('Embedding parameters learned in %.3fs\n', toc);
            end

            %% Process database images
            vecs_base_file = [dataset_dir, 'vecs_base_', num2str(param.k), '_', ...
                        num2str(param.d),  filename_surfix, '.mat'];

            if (exist(vecs_base_file, 'file') && ~overwrite_olddata)
                fprintf(2, ' * Load database image representation.\n');
                load(vecs_base_file);
            else   
                fprintf(2, ' * Processing database images ... \n');
                tic
                vecs_base = cell(length(gnd_test.imlist), 1);
                parfor i=1:length(gnd_test.imlist)
                    masked_fea   = apply_mask([baseset_dir, gnd_test.imlist{i}, '_fea.mat'], mask_method);
                    masked_fea   = vecpostproc(embedding(masked_fea, param, enc_method));
                    masked_fea   = param.P' * bsxfun(@minus, masked_fea, param.Xm);
                    vecs_base{i} = masked_fea(1 + truncate:end, :);
                end
                if (save_data), save(vecs_base_file, 'vecs_base', '-v7.3'); end;
                fprintf ('Embedding database in %.3fs (%.3fs/sample)\n', toc, toc/length(gnd_test.imlist));
            end
            
            %% Process flickr100k images
            if (strcmp(dataset, 'oxford105k') || strcmp(dataset, 'paris106k'))

                vecs_flickr_file = [dataset_dir, 'vecs_flickr_', num2str(param.k), '_', ...
                            num2str(param.d),  filename_surfix, '.mat'];
                if (exist(vecs_flickr_file, 'file') && ~overwrite_olddata)
                    fprintf(2, ' * Load flickr image representation.\n');
                    load(vecs_flickr_file);
                else   
                    fprintf(2, ' * Processing flickr images ... \n');
                    tic
                    flickr_imlist = dir([flickrset_dir, '*_fea.mat']);
                    vecs_flickr   = cell(length(flickr_imlist), 1);
                    parfor i=1:length(flickr_imlist)
                        masked_fea     = apply_mask([flickrset_dir, flickr_imlist(i).name], mask_method);
                        masked_fea     = vecpostproc(embedding(masked_fea, param, enc_method));
                        masked_fea     = param.P' * bsxfun(@minus, masked_fea, param.Xm);
                        vecs_flickr{i} = masked_fea(1 + truncate:end, :);
                    end
                    if (save_data), save(vecs_flickr_file, 'vecs_flickr', '-v7.3'); end;
                    fprintf ('Embedding flickr in %.3fs (%.3fs/sample)\n', toc, toc/length(flickr_imlist));
                end
            end


            %% Process query images
            qvecs_file = [dataset_dir, 'rqvecs_',  num2str(param.k), '_', ...
                       num2str(param.d),  filename_surfix, '.mat'];

            if (exist(qvecs_file, 'file') && ~overwrite_olddata)
                fprintf(2, ' * Load query image representation.\n');
                load(qvecs_file);
            else   
                fprintf(2, ' * Processing query images ... \n');
                tic
                qimlist = {gnd_test.imlist{gnd_test.qidx}};
                qvecs = cell(length(qimlist), 1);
                parfor i=1:length(qimlist)
                    masked_fea = apply_mask([queryset_dir, qimlist{i}, '_fea.mat'], mask_method);
                    masked_fea = vecpostproc(embedding(masked_fea, param, enc_method));
                    masked_fea = param.P' * bsxfun(@minus, masked_fea, param.Xm);
                    qvecs{i}   = masked_fea(1 + truncate:end, :);
                end
                if (save_data), save(qvecs_file, 'qvecs', '-v7.3'); end;
                fprintf ('Embedding query set in %.3fs (%.3fs/sample)\n', toc, toc/length(qimlist));
            end

            %% Evaluate
            fprintf(2, ' * Evaluate Retrieval Performance\n');

            % final database vectors and query vectors
            vecs_base = cell2mat(vecs_base');
            qvecs = cell2mat(qvecs');
            if (strcmp(dataset, 'oxford105k') || strcmp(dataset, 'paris106k'))
                vecs_flickr = cell2mat(vecs_flickr');
                vecs_base = [vecs_base, vecs_flickr];
                clear vecs_flickr
            end

            % Apply power-law normalization
            pw = 0.5;
            x = (sign(vecs_base) .* abs(vecs_base).^pw);
            q = (sign(qvecs) .* abs(qvecs).^pw);

            % l2 normalize to achieve the final vector
            x = yael_vecs_normalize (x, 2, 0);
            q = yael_vecs_normalize (q, 2, 0);

            % retrieval with inner product
            [ranks,~] = yael_nn(x, -q, size(x, 2), 16);
            map = compute_map (ranks, gnd_test.gnd);
            fprintf ('%s  %s  %s  k=%d   d=%3d  D=%5d   pw=%.2f  mAP=%.3f\n', ...
                            dataset_name, mask_method, enc_method, param.k,...
                            param.d, size(x,1), pw, map);
            mAPs(dataset_idx, mask_method_idx, final_dim_idx) = map;
            fprintf(2, '================================================================\n');
        end
    end
    save('results/exp_table6.mat', 'mAPs', 'datasets', 'mask_methods', 'final_dims');
end
print_table6_part1;

