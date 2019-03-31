%% MatConvnet
% download
system('wget http://www.vlfeat.org/matconvnet/download/matconvnet-1.0-beta25.tar.gz');
system('tar -xvzf matconvnet-1.0-beta25.tar.gz');

% Compile matconvnet library
addpath(genpath('matconvnet-1.0-beta25'));

% You might need to include the following line into '~/.bashrc'
%    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/

% NOTE: '/usr/local/cuda/' is the default cuda path for ubuntu 16.04, 
% please modify accordingly if cuda is installed in another location
% in your device.
vl_compilenn('enableGpu', true, ...
             'cudaRoot', '/usr/local/cuda/', ...   
             'cudaMethod', 'nvcc')
         
%% Vlfeat
system('wget http://www.vlfeat.org/download/vlfeat-0.9.21-bin.tar.gz');
system('tar -xvzf vlfeat-0.9.21-bin.tar.gz ');

%%
clc
disp('DONE!!!')