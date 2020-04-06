#!/bin/bash
results="`apt-cache policy unrar | grep "Installed:" ` "
if [ "$results" = " " ]; then
    echo "Please install unrar first (sudo apt-get install unrar), then re-run this script."
    exit
else
	echo $results
fi

results_len=${#results} 
if [ "${results:13:results_len-1}" = "(none) " ]; then
    echo "Please install unrar first (sudo apt-get install unrar), then re-run this script."
    exit
else
	echo $results
fi

DATASET_DIR=datasets
if [ ! -d $DATASET_DIR ]; then
    mkdir $DATASET_DIR
fi

# Oxford dataset
FILE=datasets/oxbuild_images.tgz

OXFORD_DIR=datasets/oxford5k/
if [ ! -d $OXFORD_DIR ]; then
    mkdir $OXFORD_DIR
else
    rm -R $OXFORD_DIR
    mkdir $OXFORD_DIR
fi
echo " * Downloading $FILE ..."
wget -c --no-check-certificate http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz -O $FILE
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $OXFORD_DIR


# Paris dataset
PARIS_DIR=datasets/paris6k/
if [ ! -d $PARIS_DIR ]; then
    mkdir $PARIS_DIR
else
    rm -R $PARIS_DIR
    mkdir $PARIS_DIR
fi

FILE=datasets/paris_1.tgz
echo " * Downloading $FILE ..."
wget -c --no-check-certificate http://www.robots.ox.ac.uk/~vgg/data/parisbuildings/paris_1.tgz -O $FILE
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $PARIS_DIR

FILE=datasets/paris_2.tgz
echo " * Downloading $FILE ..."
wget -c --no-check-certificate http://www.robots.ox.ac.uk/~vgg/data/parisbuildings/paris_2.tgz -O $FILE
echo " * Extracting $FILE ...."
tar -xzf $FILE -C $PARIS_DIR

find $PARIS_DIR -mindepth 2 -type f -exec mv -t $PARIS_DIR -i '{}' +
rm -R datasets/paris6k/paris

# Holidays dataset (rotated)
FILE=datasets/holidays_rotated.tar.gz
echo " * Downloading $FILE ..."
wget -c --no-check-certificate https://www.dropbox.com/s/f1z8pgzhkf52tcb/holidays_rotated.tar.gz?dl=0 -O $FILE
echo " * Extracting $FILE ...."

if [ -d $DATASET_DIR/holidays ]; then
    rm -R $DATASET_DIR/holidays
fi
tar -xzf $FILE -C $DATASET_DIR
mv $DATASET_DIR/holidays $DATASET_DIR/holidays_rotated

# Holidays dataset (original)
FILE=$DATASET_DIR/holidays_original.tar.gz

echo " * Downloading $FILE ..."
wget -c --no-check-certificat https://www.dropbox.com/s/93baggh7zqsaibe/holidays.tar.gz?dl=0 -O $FILE
echo " * Extracting $FILE ...."

if [ -d $DATASET_DIR/holidays ]; then
    rm -R $DATASET_DIR/holidays
fi
tar -zxf $FILE -C $DATASET_DIR
mv $DATASET_DIR/holidays $DATASET_DIR/holidays_original

# Oxford100k
for i in `seq 1 40`; do
    partNum=$(printf "%.2d" $i)
    FILE='datasets/oxc1_100k.part'$partNum'.rar'
    if [ ! -f $FILE ]; then
        printf "Downloading %.2d out of 40\n" $i;
        cmd='wget -c --no-check-certificate http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/ox100k/oxc1_100k.part'$partNum'.rar -O datasets/oxc1_100k.part'$partNum'.rar';
        echo 'Executing: '$cmd
        $cmd
    fi
done

unrar x  datasets/oxc1_100k.part01.rar $DATASET_DIR