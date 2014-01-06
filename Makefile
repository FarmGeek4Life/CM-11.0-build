SHELL := /bin/bash

#. ./make_upload.bash

all_auto: all shutdown

all: 11.0

setup:
	. useful_scripts.bash

11.0_setup: setup
	$(eval zipfile = $(wildcard /home/brysoncg/android/system/out/target/product/jflteatt/*-UNOFFICIAL-jflteatt.zip) )
	$(eval md5 =  $(wildcard /home/brysoncg/android/system/out/target/product/jflteatt/*-UNOFFICIAL-jflteatt.zip.md5sum) )
	$(eval ota =  $(wildcard /home/brysoncg/android/system/out/target/product/jflteatt/cm_jflteatt-ota-*.zip) )
#	pushd /home/brysoncg/android/system/out/target/product/jflteatt /; \
#	( [ ! -d oldBuilds ] && mkdir oldBuilds ); \
#	mv $(zipfile) oldBuilds/ ; \
#	mv $(md5) oldBuilds/ ; \
#	mv $(ota) oldBuilds/ ; \
#	popd
	pushd /home/brysoncg/android/system/out/target/product/jflteatt /; \
	( [ ! -d oldBuilds ] && mkdir oldBuilds ); \
	mv *jflteatt* oldBuilds/ ; \
	popd

11.0: unpatch_highsense clean_gerrit sync_clean patch_gerrit patch_highsense ensure_prebuilts fix_Trebuchet build unpatch_highsense

nosync: unpatch_highsense clean_gerrit patch_gerrit patch_highsense ensure_prebuilts fix_Trebuchet build unpatch_highsense

build_all: patch_highsense ensure_prebuilts fix_Trebuchet build unpatch_highsense

base: setup unpatch_highsense clean_gerrit sync_clean ensure_prebuilts build 11.0_upload

vanilla: setup unpatch_highsense clean_gerrit sync_clean patch_highsense_vanilla ensure_prebuilts build upload unpatch_highsense

ensure_prebuilts:
	pushd /home/brysoncg/android/system/vendor/cm/; [ ! -f proprietary/Term.apk ] && ./get-prebuilts || true; popd

patch_highsense: setup
	apply_highsense_patches 11.0 P 0

unpatch_highsense: setup
	apply_highsense_patches 11.0 R 0

patch_highsense_vanilla: setup
	apply_highsense_patches 11.0 P 1

clean_gerrit: setup
	. ~/android/useful_scripts.bash; clean_up_gerrit 11.0

patch_gerrit: setup
	. ~/android/useful_scripts.bash; apply_gerrit_picks 11.0

sync:
	pushd system; (repo sync -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

sync_clean:
	pushd system; (repo sync -d -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

fix_Trebuchet:
	-rm -rf /home/brysoncg/android/system/device/samsung/jf-common/overlay/packages/apps/Trebuchet

build:
#	Make sure the exit status is that of the 'brunch' command, not of the 'popd' command
	pushd system; source build/envsetup.sh; (brunch jflteatt && STATUS=0) || STATUS=1; popd; exit $$STATUS

upload:
#	$(eval zipfile = $(ls /home/brysoncg/android/system/out/target/product/jflteatt/cm-11-201?????-UNOFFICIAL-jflteatt.zip) )
#	$(eval md5 = $(ls /home/brysoncg/android/system/out/target/product/jflteatt/cm-11-201?????-UNOFFICIAL-jflteatt.zip.md5sum) )
	$(eval zipfile = $(wildcard /home/brysoncg/android/system/out/target/product/jflteatt/*-UNOFFICIAL-jflteatt.zip) )
	$(eval md5 =  $(wildcard /home/brysoncg/android/system/out/target/product/jflteatt/*-UNOFFICIAL-jflteatt.zip.md5sum) )
	curl -n -T $(zipfile) ftp://192.168.9.1/data/
	curl -n -T $(md5) ftp://192.168.9.1/data/
	pushd /home/brysoncg/android/system/out/target/product/jflteatt/; rm -rf oldBuilds; popd
#	curl -n -T /home/brysoncg/android/system/out/target/product/jflteatt/cm-11-201?????-UNOFFICIAL-jflteatt.zip ftp://192.168.9.1/data/
#	curl -n -T /home/brysoncg/android/system/out/target/product/jflteatt/cm-11-201?????-UNOFFICIAL-jflteatt.zip.md5sum ftp://192.168.9.1/data/

clean_highsense_errors: setup
#	-rm system/packages/apps/Settings/res/xml/display_settings.xml.*
#	-rm system/packages/apps/Settings/res/values*/*.xml.*
#	-rm system/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.*
#	-rm system/highsense_patched
#	-rm system/frameworks/opt/hardware/src/org/cyanogenmod/hardware/HighTouchSensitivity.java
#	-rm system/hardware/samsung/cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java
#	# Git revert files and remove untracked files: git reset --hard; git clean -fdx
#	# Probably would be better to use than patch revert...
	pushd system/packages/apps/Settings; reset_git_dir; popd
	pushd system/frameworks/opt/hardware; reset_git_dir; popd
	pushd system/hardware/samsung; reset_git_dir; popd

shutdown:
	gnome-session-quit --power-off

clean: clean_11.0

clean_11.0:
	pushd system; make clean; popd

.PHONY: all all_auto 11.0 clean clean_11.0 shutdown setup
