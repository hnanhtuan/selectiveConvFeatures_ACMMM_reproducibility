#!/bin/bash
echo 'hello'

DATASET_DIR=datasets
if [ ! -d $DATASET_DIR ]; then
    mkdir $DATASET_DIR
fi

# Oxford dataset
FILE=datasets/oxbuild_images.tgz
if [ -f $FILE ]; then
    echo " * File $FILE exists."
else
    echo " * Downloading $FILE ..."
    wget http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz -O $FILE
fi
OXFORD_DIR=datasets/oxford5k/
if [ ! -d $OXFORD_DIR ]; then
    mkdir $OXFORD_DIR
fi
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $OXFORD_DIR


# Paris dataset
PARIS_DIR=datasets/paris6k/
if [ ! -d $PARIS_DIR ]; then
    mkdir $PARIS_DIR
fi

FILE=datasets/paris_1.tgz
if [ -f $FILE ]; then
    echo " * File $FILE exists."
else
    echo " * Downloading $FILE ..."
    wget http://www.robots.ox.ac.uk/~vgg/data/parisbuildings/paris_1.tgz -O $FILE
fi
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $PARIS_DIR

FILE=datasets/paris_2.tgz
if [ -f $FILE ]; then
    echo " * File $FILE exists."
else
    echo " * Downloading $FILE ..."
    wget http://www.robots.ox.ac.uk/~vgg/data/parisbuildings/paris_2.tgz -O $FILE
fi
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $PARIS_DIR

find $PARIS_DIR -mindepth 2 -type f -exec mv -t $PARIS_DIR -i '{}' +
rm -R datasets/paris6k/paris

# Holidays dataset
FILE=datasets/holidays.tar.gz
if [ -f $FILE ]; then
    echo " * File $FILE exists."
else
    # We provide images which are rotated to correct the image orientation.
    echo " * Downloading $FILE ..."
    wget https://www.dropbox.com/s/f1z8pgzhkf52tcb/holidays_rotated.tar.gz?dl=0 -O $FILE
fi
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $DATASET_DIR

# Oxford100k
for i in `seq 1 40`; do
    partNum=$(printf "%.2d" $i)
    FILE='datasets/oxc1_100k.part'$partNum'.rar'
    if [ ! -f $FILE ]; then
        printf "Downloading %.2d out of 40\n" $i;
        cmd='wget http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/ox100k/oxc1_100k.part'$partNum'.rar -O datasets/oxc1_100k.part'$partNum'.rar';
        echo 'Executing: '$cmd
        $cmd
    fi
done

unrar x  datasets/oxc1_100k.part01.rar $DATASET_DIR