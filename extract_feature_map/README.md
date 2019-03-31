What is it?
===========

This is a Matlab script to extract conv. features for various datasets, 
including Oxford5k, Paris6k, Holidays, and Flickr100k

Prerequisites
=============

The prerequisites are:
* MatConvNet MATLAB toolbox 1.0-beta25

* Images of Oxford5k and Paris6k datasets: http://www.robots.ox.ac.uk/~vgg/data/
* Images of Holidays datasets: http://lear.inrialpes.fr/~jegou/data.php or for fixed orientation images: https://www.dropbox.com/s/f1z8pgzhkf52tcb/holidays_rotated.tar.gz?dl=0.
* Images of Flickr100k: http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/flickr100k.html

* Pre-trained VGG16 model: The mat files containing the models can be downloaded at [MatConvnet website](http://www.vlfeat.org/matconvnet/pretrained/) or [my backup file](https://www.mediafire.com/file/rx1liu6xl4ii9l0/imagenet-vgg-verydeep-16.mat).

* VGG16-based siaMAC model [1]: The model file is included in `siaMAC_vgg` folder.

[1] Filip Radenović, Giorgos Tolias, and Ondřej Chum. CNN Image Retrieval Learns from BoW: Unsupervised Fine-Tuning with Hard Examples. In ECCV 2016.

Usage
=============
1. Modify the parameters in 'extract_feature_xxx.m' file (xxx: VGG16 or siaMAC):
* *lid*:          The index of conv. layer to extract features.
* *max_img_dim*:  Resize to have max(W, H)=max_img_dim
* *baseDir*:      The directory contains subfolders, which contains images
2. Select the dataset to extract conv. features by set the corresponding variables to 'True'.
3. Execute the script.

Otherwise, execute the pre-configured MATLAB scripts to extract conv. features required for the corresponing experiments.


Files
==============
|Filename|Description|
|---|---|
|README   |                   This file|
|download_datasets.sh |       The bash script to download all datasets mentioned above. Please comment out the appropriate section if you do not want to download any dataset.
|extract_feature_VGG16.m | The MATLAB script to extract conv. features using the pretrained VGG16 model.. |
|extract_feature_VGG16_main.m | The pre-configured MATLAB script to extract conv. features using the pretrained VGG16 model required in majority of the experiments. |
|extract_feature_VGG16_exp_table5.m | The pre-configured MATLAB script to extract the additional conv. features required in experiment of table 5. |
|extract_feature_VGG16_exp_figure5.m | The pre-configured MATLAB script to extract the additional conv. features required in experiment of figure 5. |
|extract_feature_siaMAC.m | The MATLAB script to extract conv. features using the siaMAC model. |
|extract_feature_siaMAC_exp_table6.m| The pre-configured MATLAB script to extract the additional conv. features using the siaMAC model required in experiment of table 6. |
|extract_feature.m|           The function that execute the forward pass to get the conv. feature.|
|crop_qim.m        |          Function to crop image based on provided bounding box for Oxford5k and Paris6k datasets.|
|||
|gnd_oxford5k.mat    |        File contains all ground truth information of Oxford5k dataset|
|gnd_paris6k.mat      |       File contains all ground truth information of Paris6k dataset|