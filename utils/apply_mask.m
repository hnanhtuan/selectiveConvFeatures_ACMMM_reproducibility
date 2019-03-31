function [ masked_fea ] = apply_mask( filename, maskmethod )
% apply_mask
% + Load the feature map file.
% + Create the mask then apply
% + Return a set of local features

l = load(filename);
k = size(l.fea, 3);

switch maskmethod
    case 'max'
        mask = create_max_mask( l.fea );
    case {'sum50', 'sum'}
        mask = create_sum_mask( l.fea );
    case 'sift'
        sift_loc = load(strrep(filename, '_fea.mat', '_sift.mat'));
        mask = create_sift_mask(sift_loc.f, size(l.fea, 1), size(l.fea, 2), ...
                                sift_loc.H, sift_loc.W);
    case 'none'
        mask = true(size(l.fea, 1), size(l.fea, 2));
end

mask = repmat(mask, [1, 1, k]);
masked_fea =  l.fea(mask);
masked_fea = reshape(masked_fea, [length(masked_fea)/k, k])';
end

function [ mask ] = create_max_mask( fea )
% Return a binary mask

mask = false(size(fea, 1), size(fea, 2));
for j=1:size(fea, 3)
    [v1, p1] = max(fea(:, :, j));
    [~, p2] = max(v1);
    mask(p1(p2), p2) = 1;
end
mask = mask(:);
end


function [ mask ] = create_sum_mask( fea )
% Return a binary mask
mask = sum(fea, 3);
mask = (mask(:) >= prctile(mask(:), 50));
end

function [ mask ] = create_sift_mask( f, Hf, Wf, H, W )
% Return a binary mask
x_ratio = H/Hf;
y_ratio = W/Wf;

f(1,:) = round(f(1,:)/y_ratio);
f(2,:) = round(f(2,:)/x_ratio);
% f(3,:) = ceil(f(3,:));

mask = zeros(Hf, Wf);
r = 1;
for j=1:size(f, 2)
    mask(max(1, f(2, j) - r):min(Hf, f(2, j) + r), ...
                max(1, f(1, j) - r):min(Wf, f(1, j) + r)) = 1;
end
mask = mask > 0;
end



