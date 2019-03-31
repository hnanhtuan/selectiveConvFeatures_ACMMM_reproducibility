function [macv] = mac(im, net)

	mpx = mean(net.meta.normalization.averageImage(:));

	if strcmp(net.device, 'gpu')
		gpuarrayfun = @(x) gpuArray(x);
		gatherfun = @(x) gather(x);
	else
		gpuarrayfun = @(x) x; % do not convert to gpuArray
		gatherfun = @(x) x; % do not gather
	end

	if isstr(im)
		im = imread(im);
	end
	if size(im, 3) == 1
		im = repmat(im, [1 1 3]);
	end
	im = single(im) - mpx;

	if min(size(im, 1), size(im, 2)) < 70
		im = pad2minsize(im, 70, 0);
    end
    
%   VGG
%     net.eval({'input_a', gpuarrayfun(reshape(im, [size(im), 1]))});  
% 	macv = gatherfun(squeeze(net.vars(net.layers(net.getLayerIndex('descriptor_a')).outputIndexes).value));

%   VGG
    net.eval({'input_a', gpuarrayfun(reshape(im, [size(im), 1]))});  
	macv = gatherfun(squeeze(net.vars(net.layers(net.getLayerIndex('pool5_a')).outputIndexes).value));

%   ResNet
% 	net.eval({'data', gpuarrayfun(reshape(im, [size(im), 1]))});    
%     macv = gatherfun(squeeze(net.vars(net.layers(net.getLayerIndex('res5b_relu')).outputIndexes).value));

    
%     macv = gatherfun(squeeze());
%     net.layers(net.getLayerIndex('pool5_a')).outputIndexes
%     macv = gatherfun(net.vars(345).value);

% ------------------------------------------------------------------------------------------------
function x = pad2square(x, v)

	if ~exist('v'), v = 0; end
	x = padarray(x, [max(size(x))-size(x,1), max(size(x))-size(x,2)], v, 'post');

% ------------------------------------------------------------------------------------------------
function x = pad2minsize(x, minsize, v)

	if ~exist('v'), v = 0; end
	if ~exist('minsize'), minsize = 70; end
	x = padarray(x, [max(minsize-size(x,1), 0), max(minsize-size(x,2), 0)], v, 'post');
