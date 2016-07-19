#!/bin/bash

# Revert iOS PNG optimizations
# usage: $ revertPNGs path/to/png/dir
# or copy this script to the dir of PNGs then execute $ revertPNGs

if [ ! -z "$1" ] 
then
	cd "$1"
fi

mkdir -p _revertedImages

#looping for png files in . or $1 parameter
for png in `find . -name '*.png'`
do
	name=`basename $png`
	echo $name

	/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush -revert-iphone-optimizations -q "${name}" "_revertedImages/${name}"
done