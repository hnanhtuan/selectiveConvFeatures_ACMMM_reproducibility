addpath(genpath('utils/'));
addpath(genpath('data/'));

poolobj = gcp;
addAttachedFiles(poolobj, {'triemb_map.m', 'triemb_res.mexa64', ...
                            'qdemocratic.m', 'sinkhornm.m', ...
                            'embedding.m', 'vecpostproc.m'})

%% Dataset 
data_dir = 'extract_feature_map/features/';
work_dir = 'data/workdir/';
if ~exist(work_dir, 'dir'), mkdir(work_dir); end

datasets = {'oxford5k', 'holidays_rotated'}; 
mask_methods = {'max', 'sum', 'sift', 'none'};
pws=[1 0.7 0.5 0.3 0.2 0];

if (exist('results/exp2_figure3_powerlaw_norm_analysis_results.mat', 'file'))
    load('results/exp2_figure3_powerlaw_norm_analysis_results.mat');
else
    mAPs = zeros(length(datasets), length(mask_methods), length(pws));
end
for dataset_idx=1:length(datasets)
    dataset = datasets{dataset_idx};
    switch dataset
        case {'oxford5k', 'oxford105k'}
            dataset_train				= 'paris6k';        % dataset to learn the PCA-whitening on
            dataset_test 				= 'oxford5k';       % dataset to evaluate on 
        case {'paris6k', 'paris106k'}
            dataset_train				= 'oxford5k';       
            dataset_test 				= 'paris6k';         
        case 'holidays_rotated'
            dataset_train				= 'flickr5k';       
            dataset_test 				= 'holidays_rotated';       
    end
    gnd_test = load(['gnd_', dataset_test, '.mat']);

    lid         = 31;       % index of output layer of VGG network
    max_img_dim = 1024;     % max(W_I, H_I): the largest dimension of input images

    % The 'dataset_name' should be the same folder where the extracted conv.
    % features are stored.
    dataset_name  = [dataset_test, '_', num2str(lid),'_', num2str(max_img_dim)];

    dataset_dir   = [data_dir, dataset_name, '/'];
    trainset_dir  = [dataset_dir, dataset_train, '/'];
    baseset_dir   = [dataset_dir, dataset_test, '/'];
    queryset_dir  = [dataset_dir, dataset_test, 'q/'];

    %% Parameters
    enc_method      = 'tembsink';
        % 'temb':      Triangular embedding + Sum pooling
        % 'tembsink':  Triangular embedding + Democratic pooling
        % 'faemb':     Fast-Function Apprximate Embdding + Democratic pooling
    
    for mask_method_idx=1:length(mask_methods)
        mask_method = mask_methods{mask_method_idx};
        
        if (sum(sum(sum(mAPs(dataset_idx, mask_method_idx, :)))) > 0)
            continue;
        end
   
        final_dim = 8064;
    
        param.d         = 128;      
        param.k         = 64;
        truncate        = 128;                  % Truncate the first 128 dimensions

        filename_surfix = [ '_', enc_method, '_', mask_method ];

        save_param = true;              % Save the learned parameters for later usage
        save_data  = false;             % Save the processed global image representation for later usage
        overwrite_olddata = false;       % Re-learn the parameters and re-process image (if did).

        %% Learning parameters
        disp(['Test - ', dataset_name, ' - ', enc_method, ' - ', mask_method]);

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

        % Apply power-law normalization
        for pw_idx = 1:length(pws);
            pw = pws(pw_idx);
            x = (sign(vecs_base) .* (abs(vecs_base).^pw));
            q = (sign(qvecs) .* (abs(qvecs).^pw));

            % l2 normalize to achieve the final vector
            x = yael_vecs_normalize (x, 2, 0);
            q = yael_vecs_normalize (q, 2, 0);

            % retrieval with inner product
            [ranks,~] = yael_nn(x, -q, size(x, 2), 16);
            map = compute_map (ranks, gnd_test.gnd);
            fprintf ('%s  %s  %s  k=%d   d=%3d  D=%5d   pw=%.2f  mAP=%.3f\n', ...
                            dataset_name, mask_method, enc_method, param.k,...
                            param.d, size(x,1), pw, map);
            mAPs(dataset_idx, mask_method_idx, pw_idx) = map;
        end
        fprintf(2, '================================================================\n');
        if ~exist('results/', 'dir'), mkdir('results/'); end
        save('results/exp2_figure3_powerlaw_norm_analysis_results.mat', ...
                    'mAPs', 'datasets', 'mask_methods', 'pws');
    end
    plot_figure3_powerlaw_norm_analysis;
end

