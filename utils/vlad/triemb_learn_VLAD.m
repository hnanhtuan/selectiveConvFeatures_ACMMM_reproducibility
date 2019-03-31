function [Xmean, eigvec, eigval, Xmean_local, eigvec_local, eigval_local] = vlad_learn(vtrain, C)


Xmean_local = []; eigvec_local = []; eigval_local = [];

nlearn = size (vtrain, 2);     % number of input vectors
k = size (C, 2);               % number of support centroids
d = size (vtrain, 1);          % input vector dimensionality
D = k * d;                     % output dimensionality
dout = D;

slicesize = 10000;
nslices = nlearn / slicesize;
Xmean = zeros (D, 1, 'single');

% Compute mean embedded vector
Xsum = zeros (D, 1);
Xtmp = [];

for i=1:slicesize:nlearn
  endi = min(i+slicesize-1, nlearn);
%   fprintf ('\r%d-%d/%d', i, endi, nlearn);
  
%   X = triemb_res (vtrain (:,i:endi), C, Xmean);
  
  %%%%%%%%%%%%%%%%%%%%%%%
  n_nearest = 1; % the number of nearest neigbors we want
  [idxnn, ~] = yael_nn (C, vtrain (:,i:endi), n_nearest);
  idxnn = single(idxnn);
  X = triemb_res_new (vtrain (:,i:endi), C, Xmean,idxnn);
  %%%%%%%%%%%%%%%%%%%%%%%
    
  Xsum = Xsum + sum (X, 2);
end

Xmean = Xsum / nlearn;
Xmean_local = reshape(Xmean,d,k);
% Compute whitening parameters
covD = zeros(d * k);
covD_local = zeros(d,d,k); 

for i=1:slicesize:nlearn
  endi = min(i+slicesize-1, nlearn);
%   fprintf ('\r%d-%d/%d', i, endi, nlearn);
  
%   X = triemb_res (vtrain (:,i:endi), C, Xmean);

  %%%%%%%%%%%%%%%%%%%%%%%
  n_nearest = 1; % the number of nearest neigbors we want
  [idxnn, ~] = yael_nn (C, vtrain (:,i:endi), n_nearest);
  idxnn = single(idxnn);
  X = triemb_res_new (vtrain (:,i:endi), C, Xmean, idxnn); % tinh residual, sau do norm, sau do tru mean. moi cot cua X la phi(x)
  %%%%%%%%%%%%%%%%%%%%%%%
   
% X = Xtmp(:,i:endi);
% X = bsxfun (@minus, X, Xmean);
  
 covD = covD + X * X';
%  tmpX = matrix_mul(X',X');
%  covD = covD + tmpX';
 
  for j = 1:k
      idxj = 1+(j-1)*d : j*d; % all residuals tren cell thu j
      covD_local(:,:,j) = covD_local(:,:,j) + X(idxj,:)*X(idxj,:)'; %covariance on cell j
  end
end
fprintf ('\n');
%tai sao covD khong chia cho N
covD = 1/(nlearn-1)*covD;

% Eigen-decomposition
if 3 * dout < D
  eigopts.issym = true;
  eigopts.isreal = true;
  eigopts.tol = eps;
  eigopts.disp = 0;

  [eigvec, eigval] = eigs (double(covD), dout, 'LM', eigopts);
  
else
  [eigvec, eigval] = eig (covD); %out put theo trat tu tang dan cua eigenvalue
  eigvec = eigvec (:, end:-1:end-dout+1); %sap xep lai theo trat tu giam dan
  eigval = diag (eigval);
  eigval = eigval (end:-1:end-dout+1);
%   for j=1:k %compute PCA for each cell
%         [eigvec_tmp, eigval_tmp] = eig (covD_local(:,:,j)); %out put theo trat tu tang dan cua eigenvalue
%         eigvec_local(:,:,j) = eigvec_tmp(:, end:-1:1); %sap xep lai theo trat tu giam dan
%         eigval_tmp = diag (eigval_tmp);
%         eigval_local(:,j) = eigval_tmp (end:-1:1);
%   end
end
