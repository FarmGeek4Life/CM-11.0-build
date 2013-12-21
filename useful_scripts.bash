#!/bin/bash

SHELL=/bin/bash

function reset_git_dir()
{
   git reset --hard
   git clean -fdx
}

export -f reset_git_dir

function fix_highsense()
{
   #~/android/highsense/cm-11.0/high-touch-sensitivity/
   #emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
   #emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch &
   #emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Hardware-Add-high-touch-sensitivity-support.patch &
   #emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Samsung-add-support-for-high-touch-sensitivity.patch &
   PATCH_OPEN=0
   
   #~/android/system11.0/packages/apps/Settings/
   if [ -f ~/android/system11.0/packages/apps/Settings/res/xml/display_settings.xml.orig ]; then
      emacs ~/android/system11.0/packages/apps/Settings/res/xml/display_settings.xml &
      emacs ~/android/system11.0/packages/apps/Settings/res/xml/display_settings.xml.orig &
      emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
      PATCH_OPEN=1
   fi
   if [ -f ~/android/system11.0/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.orig ]; then
      emacs ~/android/system11.0/packages/apps/Settings/src/com/android/settings/DisplaySettings.java &
      emacs ~/android/system11.0/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.orig &
      if [ $PATCH_OPEN -eq 0 ]; then
	 emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
      fi
   fi
   if [ -f ~/android/system11.0/packages/apps/Settings/res/values/cm_strings.xml.orig ]; then
      emacs ~/android/highsense/cm-11.0/high-touch-sensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch &
      emacs ~/android/system11.0/packages/apps/Settings/res/values/cm_strings.xml &
      emacs ~/android/system11.0/packages/apps/Settings/res/values/cm_strings.xml.orig &
   fi
}

export -f fix_highsense

function apply_highsense_patches()
{
   VERSION_CODE="$1" # Valid values: depends on existing directories
   PATCH_MODE="$2"   # Valid values: 'P' and 'R' (patch and reverse)
   VANILLA="$3"   # Valid values: 0 or 1 ('1' means vanilla on)
   
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   PATCH_SUCCESS=0       # Shell style status: 0 for good, >0 for error
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset

   if [ ! -d $BASE_DIR ]; then
      echo -ne "${TEXT_RED}"
      echo "ERROR: Bad version code: $VERSION_CODE"
      echo "Directory '$BASE_DIR' does not exist!"
      echo -ne "${TEXT_RESET}"
      return 1
   fi
   
   VERSION="cm-$VERSION_CODE"
   PATCH_MODE="$2" # Valid values: 'P' and 'R' (patch and reverse)
   if [ ! -f $BASE_DIR/highsense_patched* ] && [ "$PATCH_MODE" == "P" ]; then
      PATCH_ARGS="-p1"
      PATCH_STAT="PATCH APPLY"
   elif [ -f $BASE_DIR/highsense_patched* ] && [ "$PATCH_MODE" == "R" ]; then
      PATCH_ARGS="-R -p1"
      PATCH_STAT="PATCH REVERT"
      VANILLA=0        # Automatically set/unset VANILLA mode when reverting
      if [ -f $BASE_DIR/highsense_patched_vanilla ]; then
	 VANILLA=1
      fi
   elif [ "$PATCH_MODE" == "P" ] || [ "$PATCH_MODE" == "R" ]; then
      MODE="APPLIED"
      if [ "$PATCH_MODE" == "R" ]; then
	 MODE="REVERTED"
      fi
      echo -ne "${TEXT_GREEN}"
      echo "PATCH ALREADY $MODE: High Sensitivity / Glove Mode"
      echo -ne "${TEXT_RESET}"
      return 0;
   else
      echo -ne "${TEXT_RED}"
      echo "ERROR: Bad mode '$PATCH_MODE'. Valid values: 'P' 'R'"
      echo -ne "${TEXT_RESET}"
      return 1
   fi
   if [ $VANILLA -eq 1 ]; then
      VANILLA_PATH="_vanilla"
   else
      VANILLA_PATH=""
   fi
   
   pushd $BASE_DIR
   PATCHES="/home/brysoncg/android/highsense/$VERSION$VANILLA_PATH"
   echo -ne "${TEXT_GREEN}"
   echo "Using patch file directory: ${PATCHES}"
   echo -ne "${TEXT_RESET}"
   HIGHTOUCHSENSITIVITY=${PATCHES}/high-touch-sensitivity
   pushd packages/apps/Settings/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t /0001-Samsung-add-support-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      patch $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
      if [ $(ls -1 res/xml/display_settings.xml.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 res/xml/display_settings.xml.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(ls -1 src/com/android/settings/DisplaySettings.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 src/com/android/settings/DisplaySettings.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t /0001-Auto-copied-translations-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      patch $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
      if [ $(ls -1 res/values*/*xml.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 res/values*/*xml.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd
   
   pushd frameworks/opt/hardware/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t /0001-Hardware-Add-high-touch-sensitivity-support.patch"
      echo -ne "${TEXT_RESET}"
      patch $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
      if [ $(ls -1 src/org/cyanogenmod/hardware/HighTouchSensitivity.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 src/org/cyanogenmod/hardware/HighTouchSensitivity.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd
   
   pushd hardware/samsung/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t /0001-Samsung-add-support-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      patch $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
      if [ $(ls -1 cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd
   if [ "$PATCH_MODE" == "P" ]; then
      touch highsense_patched$VANILLA_PATH
   else
      rm -rf highsense_patched$VANILLA_PATH
   fi
   popd
   return $PATCH_SUCCESS
}

export -f apply_highsense_patches

function clean_up_gerrit()
{
   VERSION_CODE="$1" # Valid values: depends on existing directories
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset
   
   if [ "$VERSION_CODE" != "11.0" ]; then
      return 0
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   AFFECTED_PATHS=(
       'device/samsung/jf-common'
       'device/samsung/msm8960-common'
       'frameworks/base'
       'android'
       'system/core'
       'external/koush/Superuser'
       'vendor/cm'
       'device/samsung/qcom-common'
       )
   
   # 'vendor/cm': AVOID: prebuilts exist here, are downloaded. Makefile modified to auto-download if non-existent

   for i in ${AFFECTED_PATHS[@]}; do
      if [ -d "${i}" ]; then
	 echo -e "${TEXT_RED}Resetting directory: ${i}${TEXT_RESET}"
	 pushd ${i}
	 git reset --hard
	 git clean -fdx
	 popd
      fi
   done

   popd
   return 0;
}

export -f clean_up_gerrit

function apply_gerrit_picks()
{
   VERSION_CODE="$1" # Valid values: depends on existing directories
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   if [ "$VERSION_CODE" != "11.0" ]; then
      return 0
   fi
   
   GERRIT_SUCCESS=0      # Shell style status: 0 for good, >0 for error
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset
   
   if [ ! -d $BASE_DIR ]; then
      echo -ne "${TEXT_RED}"
      echo "ERROR: Bad version code: $VERSION_CODE"
      echo "Directory '$BASE_DIR' does not exist!"
      echo -ne "${TEXT_RESET}"
      return 1
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   clean_up_gerrit $VERSION_CODE
   
   export GERRIT_URL="http://review.cyanogenmod.org"
   python3 /home/brysoncg/android/gerrit_changes.py \
       `# device/samsung/jf-common` \
       'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS` \
       `# android` \
       'http://review.cyanogenmod.org/#/c/55384/' `# manifest: Trebuchet` \
       `# frameworks/base` \
       'http://review.cyanogenmod.org/#/c/56080/' `# Multi-window ported from omnirom` \
       `# frameworks/base` \
       'http://review.cyanogenmod.org/#/c/55881/' `# Close sockets on wpa_supplicant termination` \
       `# system/core` \
       'http://review.cyanogenmod.org/#/c/54968/' `# adb: use bash as default shell for adb shell` \
       `# external/koush/Superuser` \
       'http://review.cyanogenmod.org/#/c/54969/' `# su: use bash as default shell` \
       || { GERRIT_SUCCESS=1; echo -e "${TEXT_RED}*** FAILED TO APPLY PATCHES ***${TEXT_RESET}"; }
   
   TEMP_SUCCESS=$GERRIT_SUCCESS

   python3 /home/brysoncg/android/gerrit_changes.py \
       `# device/samsung/jf-common` \
       'http://review.cyanogenmod.org/#/c/53969/' `# jf: fix fstab` \
       || { GERRIT_SUCCESS=1; echo -e "${TEXT_RED}*** FAILED TO APPLY PATCHES ***${TEXT_RESET}"; }
   emacs device/samsung/jf-common/rootdir/etc/fstab.qcom && GERRIT_SUCCESS=$TEMP_SUCCESS
   
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56070/' `# jf: Updates for new kernel` \
      # `# device/samsung/msm8960-common` \
      # 'http://review.cyanogenmod.org/#/c/56069/' `# msm8960: WiFi is no longer a module` \
      # Problem: Requires use of new kernel branch: https://github.com/CyanogenMod/android_kernel_samsung_jf/tree/wip-ml4
      # `# frameworks/base` \
      # 'http://review.cyanogenmod.org/#/c/56100/' `# Squashed fixes for Statusbar Clock and Date actions` \
      # `# android` \
      # 'http://review.cyanogenmod.org/#/c/55384/' `# manifest: Trebuchet` \
      # `# vendor/cm` \
      # 'http://review.cyanogenmod.org/#/c/55718/' `# cm: Add Trebuchet back to the build` \
      # `# packages/apps/Settings` \
      # 'http://review.cyanogenmod.org/#/c/56095/' `# [WIP] Forward port sound settings (1/2)` \
   
   # Add the following line to the end of each cherry-pick enable fail-out of build if merge fails
   # || GERRIT_SUCCESS=1
   
   # `# frameworks/base` \
   # http://review.cyanogenmod.org/#/c/55209/' `# [WIP] Forward port Status Bar interface (1/2)` \
   # Can't build: 12/16/2013 5:00PM
   
   # `# packages/apps/Settings` \
   # 'http://review.cyanogenmod.org/#/c/55211/' `# [WIP] Forward port Status Bar settings (2/2)` \
   
   popd
   return $GERRIT_SUCCESS
}

export -f apply_gerrit_picks
