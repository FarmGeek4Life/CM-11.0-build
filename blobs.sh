#!/bin/bash

if [ ! -d ~/android ]; then
   mkdir ~/android
fi
if [ ! -d ~/android/vendor_blobs ]; then
   mkdir ~/android/vendor_blobs
fi
if [ ! -d ~/android/vendor_blobs/samsung ]; then
   mkdir ~/android/vendor_blobs/samsung
fi
if [ ! -d ~/android/vendor_blobs/samsung/jf-common ]; then
   mkdir ~/android/vendor_blobs/samsung/jf-common
   svn checkout https://github.com/invisiblek/proprietary_vendor_samsung/trunk/jf-common ~/android/vendor_blobs/samsung/jf-common
fi
if [ ! -d ~/android/vendor_blobs/samsung/jfltei337 ]; then
   mkdir ~/android/vendor_blobs/samsung/jfltei337
   svn checkout https://github.com/invisiblek/proprietary_vendor_samsung/trunk/jfltei337 ~/android/vendor_blobs/samsung/jfltei337
fi
if [ ! -d ~/android/vendor_blobs/samsung/adrenoblobs4.2 ]; then
   mkdir ~/android/vendor_blobs/samsung/adrenoblobs4.2
   svn checkout https://github.com/invisiblek/proprietary_vendor_samsung/trunk/adrenoblobs4.2 ~/android/vendor_blobs/samsung/adrenoblobs4.2
fi
if [ ! -h ~/android/vendor_blobs/samsung/jflteatt ]; then
   ln -s ~/android/vendor_blobs/samsung/jfltei337 ~/android/vendor_blobs/samsung/jflteatt
fi

# https://github.com/invisiblek/proprietary_vendor_samsung/tree/cm-11.0#
pushd ~/android/vendor_blobs/samsung/jf-common
   svn update
popd
pushd ~/android/vendor_blobs/samsung/jfltei337
   svn update
popd
pushd ~/android/vendor_blobs/samsung/adrenoblobs4.2
   svn update
popd
