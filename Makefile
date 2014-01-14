SHELL := /bin/bash

#. ./make_upload.bash

all_auto: all shutdown

all: 11.0

setup:
	. useful_scripts.bash

11.0_setup: setup
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt /; \
	( [ ! -d oldBuilds ] && mkdir oldBuilds ); \
	mv *jflteatt* oldBuilds/ ; \
	popd

clean_build_uniques:
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt /; \
	rm -rf obj/PACKAGING/apkcerts_intermediates/cm_jf*; \
	rm -rf obj/PACKAGING/target_files_intermediates/cm_jf*; \
	rm -rf cm_jf*; \
	rm -rf cm-*; \
	popd

11.0: 11.0_setup unpatch_custom clean_gerrit sync_clean patch_gerrit patch_custom ensure_prebuilts clean_build_uniques build upload unpatch_custom

autosync: 11.0_setup unpatch_custom clean_gerrit sync_clean patch_gerrit patch_custom ensure_prebuilts

nosync: unpatch_custom clean_gerrit patch_gerrit patch_custom ensure_prebuilts build unpatch_custom

build_all: 11.0_setup patch_custom ensure_prebuilts build upload unpatch_custom

base: setup unpatch_custom clean_gerrit sync_clean ensure_prebuilts build upload

vanilla: setup unpatch_custom clean_gerrit sync_clean patch_custom_vanilla ensure_prebuilts build upload unpatch_highsense

ensure_prebuilts:
	pushd /home/brysoncg/android/system/vendor/cm/; [ ! -f proprietary/Term.apk ] && ./get-prebuilts || true; popd

patch_custom: setup
	apply_custom_patches 11.0 P 0

unpatch_custom: setup
	apply_custom_patches 11.0 R 0

patch_custom_vanilla: setup
	apply_custom_patches 11.0 P 1

clean_gerrit: setup
	. ~/android/useful_scripts.bash; clean_up_gerrit 11.0

patch_gerrit: setup
	. ~/android/useful_scripts.bash; apply_gerrit_picks 11.0

sync:
	pushd system; (repo sync -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

sync_clean:
	pushd system; (repo sync -d -j500 && STATUS=0) || STATUS=1; popd; exit $$STATUS

build:
#	Make sure the exit status is that of the 'brunch' command, not of the 'popd' command
	pushd system; source build/envsetup.sh; (brunch jflteatt && STATUS=0) || STATUS=1; popd; exit $$STATUS

upload:
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; curl -n -T $$(echo -n "{$$(ls *-UNOFFICIAL-jflteatt.zip),$$(ls *-UNOFFICIAL-jflteatt.zip.md5sum)}") ftp://192.168.9.1/data/cm_builds; popd
	-pushd /home/brysoncg/android/system/out/target/product/jflteatt/; rm -rf oldBuilds; popd

clean_custom_errors: setup
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
	pushd system/device/samsung/jf-common; reset_git_dir; popd
	pushd system/packages/apps/Dialer; reset_git_dir; popd

shutdown:
	gnome-session-quit --power-off

clean: clean_11.0

clean_11.0:
	pushd system; make clean; popd

.PHONY: all all_auto 11.0 clean clean_11.0 shutdown setup
