SHELL := /bin/bash

auto_suspend: 12.1
	systemctl suspend -i

12.1: 12.0

all_shutdown: all shutdown

all: 12.1

build:
#	Make sure the exit status is that of the 'brunch' command, not of the 'popd' command
	source /home/brysoncg/.bashrc; source CM-build-tools/openjdk.bash; pushd system; source build/envsetup.sh; (brunch jflteatt && STATUS=0) || STATUS=1; popd; exit $$STATUS

upload:
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; curl -n -T $$(echo -n "{$$(ls *-UNOFFICIAL-jflteatt.zip),$$(ls *-UNOFFICIAL-jflteatt.zip.md5sum)}") ftp://192.168.9.1/data/cm_builds/; popd
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; rm -rf oldBuilds; popd

dropbox:
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; cp *-UNOFFICIAL-jflteatt.zip* ~/Dropbox/ ; popd

setup: setup_base
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; \
	( [ ! -d oldBuilds ] && mkdir oldBuilds ); \
	mv *jflteatt* oldBuilds/ ; \
	popd

setup_base:
	. useful_scripts.bash
#	-pushd /home/brysoncg/android/CM-build-tools/; \
#	git pull; \
#	popd
#	-pushd /home/brysoncg/android/xiaolong_chen/hudson/; \
#	git pull; \
#	popd

clean_build_uniques:
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; \
	rm -rf obj/PACKAGING/apkcerts_intermediates/cm_jf*; \
	rm -rf obj/PACKAGING/target_files_intermediates/cm_jf*; \
	rm -rf cm_jf*; \
	rm -rf cm-*; \
	rm obj/KERNEL_OBJ/vmlinux; \
	rm system/build.prop; \
	popd

#. ./make_upload.bash
12.0: setup unpatch_custom clean_gerrit sync_clean patch_gerrit patch_custom clean_build_uniques build upload unpatch_custom

autosync: setup unpatch_custom clean_gerrit sync_clean patch_gerrit patch_custom

nosync: unpatch_custom clean_gerrit patch_gerrit patch_custom build unpatch_custom

build_all: setup patch_custom build upload unpatch_custom

base: setup unpatch_custom clean_gerrit sync_clean build upload

vanilla: base

patch_custom: setup
	. ~/android/useful_scripts.bash; apply_custom_patches 12.1 P 0

unpatch_custom: setup
	-. ~/android/useful_scripts.bash; apply_custom_patches 12.1 R 0
	-. ~/android/useful_scripts.bash; clean_custom_patches 12.1

clean_gerrit: setup
	. ~/android/useful_scripts.bash; clean_up_gerrit 12.1

patch_gerrit: setup
	. ~/android/useful_scripts.bash; apply_gerrit_picks 12.1

sync:
	pushd system; (repo sync -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

sync_clean:
	pushd system; (repo sync -d -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

adb_push:
	@read -p "Connect Phone via USB!!!. Press enter to continue: "
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/ ; \
	adb push *-UNOFFICIAL-jflte.zip /storage/sdcard1/updates/ ; \
	adb push *-UNOFFICIAL-jflte.zip.md5sum /storage/sdcard1/updates/ ; \
	popd

adb_push_net:
	@read -p "Enable ADB Networking!!!. Press enter to continue: "
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/ ; \
	adb connect 192.168.9.210 ; \
	sleep 2 ; \
	adb push *-UNOFFICIAL-jflte.zip /storage/sdcard1/updates/ ; \
	adb push *-UNOFFICIAL-jflte.zip.md5sum /storage/sdcard1/updates/ ; \
	adb disconnect ; \
	popd

clean_custom_errors: setup
#	-rm system/packages/apps/Settings/res/xml/display_settings.xml.*
#	-rm system/packages/apps/Settings/res/values*/*.xml.*
#	-rm system/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.*
#	-rm system/highsense_patched
#	-rm system/frameworks/opt/hardware/src/org/cyanogenmod/hardware/HighTouchSensitivity.java
#	-rm system/hardware/samsung/cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java
#	# Git revert files and remove untracked files: git reset --hard; git clean -fdx
#	# Probably would be better to use than patch revert...
	pushd system/device/samsung/jf-common; reset_git_dir; popd

shutdown:
	gnome-session-quit --power-off

clean: 
	pushd system; make clean; popd

.PHONY: all all_auto clean shutdown setup
