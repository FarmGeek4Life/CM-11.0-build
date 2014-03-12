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
   #~/android/CM-11.0-build/high-touch-sensitivity/
   #emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
   #emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch &
   #emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Hardware-Add-high-touch-sensitivity-support.patch &
   #emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Samsung-add-support-for-high-touch-sensitivity.patch &
   PATCH_OPEN=0
   
   #~/android/system/packages/apps/Settings/
   if [ -f ~/android/system/packages/apps/Settings/res/xml/display_settings.xml.orig ]; then
      emacs ~/android/system/packages/apps/Settings/res/xml/display_settings.xml &
      emacs ~/android/system/packages/apps/Settings/res/xml/display_settings.xml.orig &
      emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
      PATCH_OPEN=1
   fi
   if [ -f ~/android/system/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.orig ]; then
      emacs ~/android/system/packages/apps/Settings/src/com/android/settings/DisplaySettings.java &
      emacs ~/android/system/packages/apps/Settings/src/com/android/settings/DisplaySettings.java.orig &
      if [ $PATCH_OPEN -eq 0 ]; then
	 emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch &
      fi
   fi
   if [ -f ~/android/system/packages/apps/Settings/res/values/cm_strings.xml.orig ]; then
      emacs ~/android/CM-11.0-build/high-touch-sensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch &
      emacs ~/android/system/packages/apps/Settings/res/values/cm_strings.xml &
      emacs ~/android/system/packages/apps/Settings/res/values/cm_strings.xml.orig &
   fi
}

export -f fix_highsense

function clean_custom_patches()
{ 
   VERSION_CODE="$1" # Valid values: depends on existing directories
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset
   
   if [ "$VERSION_CODE" != "11.0" ]; then
      #return 0
      VERSION_CODE=11.0
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   AFFECTED_PATHS=(
       'packages/apps/Settings'
       'frameworks/opt/hardware'
       'hardware/samsung'
       'device/samsung/jf-common'
       'packages/apps/Dialer'
       'packages/apps/InCallUI'
       'packages/services/Telephony'
       'frameworks/base'
       )
   
   for i in ${AFFECTED_PATHS[@]}; do
      if [ -d "${i}" ]; then
	 echo -e "${TEXT_RED}Resetting directory: ${i}${TEXT_RESET}"
	 pushd ${i}
	 SHA=$(git status | grep -E -o -e "[a-fA-F0-9]{7}")
	 #git reset --hard $SHA
	 # For this, we only want to go back to the last merge - it excludes all patches...
	 git reset --hard
	 git clean -fdx
	 popd
      fi
   done

   rm -rf custom_patched || true

   popd
   return 0;
}

export -f clean_custom_patches

function apply_custom_patches()
{
   VERSION_CODE="$1" # Valid values: depends on existing directories
   PATCH_MODE="$2"   # Valid values: 'P' and 'R' (patch and reverse)
   
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
   if [ ! -f $BASE_DIR/custom_patched* ] && [ "$PATCH_MODE" == "P" ]; then
      PATCH_ARGS="-p1"
      PATCH_STAT="PATCH APPLY"
   elif [ -f $BASE_DIR/custom_patched* ] && [ "$PATCH_MODE" == "R" ]; then
      PATCH_ARGS="-R -p1"
      PATCH_STAT="PATCH REVERT"
   elif [ "$PATCH_MODE" == "P" ] || [ "$PATCH_MODE" == "R" ]; then
      MODE="APPLIED"
      if [ "$PATCH_MODE" == "R" ]; then
	 MODE="REVERTED"
      fi
      echo -ne "${TEXT_GREEN}"
      echo "PATCH ALREADY $MODE: Custom Patches"
      echo -ne "${TEXT_RESET}"
      return 0;
   else
      echo -ne "${TEXT_RED}"
      echo "ERROR: Bad mode '$PATCH_MODE'. Valid values: 'P' 'R'"
      echo -ne "${TEXT_RESET}"
      return 1
   fi
   
   pushd $BASE_DIR
   PATCH="git apply --whitespace=warn" # Can use 'patch', but 'git apply --whitespace=warn' is more powerful
   PATCHES="/home/brysoncg/android/CM-11.0-build"
   MY_PATCHES="/home/brysoncg/android/CM-11.0-build/my-patches"
   echo -ne "${TEXT_GREEN}"
   echo "Using patch file directory: ${PATCHES}"
   echo -ne "${TEXT_RESET}"
   HIGHTOUCHSENSITIVITY=${PATCHES}/high-touch-sensitivity
   DIALERLOOKUP=${PATCHES}/dialer-lookup
   
   pushd packages/apps/Settings/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t HighTouchSensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
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
      echo -e "$PATCH_STAT:\t\t HighTouchSensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
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
      echo -e "$PATCH_STAT:\t\t HighTouchSensitivity/0001-Hardware-Add-high-touch-sensitivity-support.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
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
      echo -e "$PATCH_STAT:\t\t HighTouchSensitivity/0001-Samsung-add-support-for-high-touch-sensitivity.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(ls -1 cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 cmhw/org/cyanogenmod/hardware/HighTouchSensitivity.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd

   #pushd device/samsung/jf-common
      #echo -ne "${TEXT_GREEN}"
      #echo -e "$PATCH_STAT:\t\t my_patches/no_wifi_module.patch"
      #echo -ne "${TEXT_RESET}"
      #$PATCH $PATCH_ARGS < ${MY_PATCHES}/no_wifi_module.patch
      #if [ $? -ne 0 ]; then
      #   echo -ne "${TEXT_RED}"
      #   echo "PATCHING ERROR: Patch failed!!!!"
      #   echo -ne "${TEXT_RESET}"
      #   PATCH_SUCCESS=1
      #fi
      #if [ $(ls -1 device/samsung/BoardConfigCommon.mk.* 2>/dev/null | wc -l) -gt 0 ]; then
      #   echo -ne "${TEXT_RED}"
      #   echo "PATCHING ERROR: Patch backup/reject files exist!"
      #   echo -e "$(ls -1 device/samsung/BoardConfigCommon.mk.*)"
      #   echo -ne "${TEXT_RESET}"
      #   PATCH_SUCCESS=1
      #fi
   #popd
   

   pushd packages/apps/Dialer/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t DialerLookup/0001-Dialer-Add-support-for-forward-and-reverse-lookups.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${DIALERLOOKUP}/0001-Dialer-Add-support-for-forward-and-reverse-lookups.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(find ./ -name "*.java.*" -o -name "*.xml.*" -o -name "*.png.*" -o -name "*.mk.*" -o -name "*.properties.*" -o -name "*.flags.*" 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(find ./ -name "*.java.*" -o -name "*.xml.*" -o -name "*.png.*" -o -name "*.mk.*" -o -name "*.properties.*" -o -name "*.flags.*")"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd

   pushd packages/apps/InCallUI/
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t DialerLookup/0001-InCallUI-Add-phone-number-service.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${DIALERLOOKUP}/0001-InCallUI-Add-phone-number-service.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      # src/com/android/incalluibind/ServiceFactory.java.*
      # src/com/android/incallui/service/PhoneNumberServiceImpl.java
      if [ $(find src/com/android/incallui*/ -name "*.java.*" 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(find src/com/android/incallui*/ -name "*.java.*")"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd

   pushd packages/services/Telephony
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t DialerLookup/0001-Telephony-Add-settings-for-forward-and-reverse-numbe.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${DIALERLOOKUP}/0001-Telephony-Add-settings-for-forward-and-reverse-numbe.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(find ./ -name "*.java.*" -o -name "*.xml.*" -o -name "*.mk.*" 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(find ./ -name "*.java.*" -o -name "*.xml.*" -o -name "*.mk.*")"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd

   pushd frameworks/base
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t DialerLookup/0001-AccountManagerService-Allow-com.android.dialer-to-ac.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${DIALERLOOKUP}/0001-AccountManagerService-Allow-com.android.dialer-to-ac.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(ls -1 services/java/com/android/server/accounts/AccountManagerService.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 services/java/com/android/server/accounts/AccountManagerService.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t DialerLookup/0001-Frameworks-Add-settings-keys-for-forward-and-reverse.patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${DIALERLOOKUP}/0001-Frameworks-Add-settings-keys-for-forward-and-reverse.patch
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(ls -1 core/java/android/provider/Settings.java.* 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(ls -1 core/java/android/provider/Settings.java.*)"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t MultiWindow Patch"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${MY_PATCHES}/multiwindow.patch # Multi-window ported from omnirom
      if [ $? -ne 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch failed!!!!"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
      if [ $(find ./ -name "*.java.*" -o -name "*.xml.rej" -o -name "*.xml.orig" -o -name "*.aidl.*" 2>/dev/null | wc -l) -gt 0 ]; then
	 echo -ne "${TEXT_RED}"
	 echo "PATCHING ERROR: Patch backup/reject files exist!"
	 echo -e "$(find ./ -name "*.java.*" -o -name "*.xml.rej" -o -name "*.xml.orig" -o -name "*.aidl.*")"
	 echo -ne "${TEXT_RESET}"
	 PATCH_SUCCESS=1
      fi
   popd


   if [ "$PATCH_MODE" == "P" ]; then
      touch custom_patched
   else
      rm -rf custom_patched
   fi
   popd
   return $PATCH_SUCCESS
}

export -f apply_custom_patches

function clean_up_gerrit()
{
   VERSION_CODE="$1" # Valid values: depends on existing directories
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset
   
   if [ "$VERSION_CODE" != "11.0" ]; then
      #return 0
      VERSION_CODE=11.0
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   AFFECTED_PATHS=(
       'external/koush/Superuser'
       'device/samsung/jflte'
       'device/samsung/qcom-common'
       'device/samsung/msm8960-common'
       'frameworks/base'
       )
   
   # 'vendor/cm': AVOID: prebuilts exist here, are downloaded. Makefile modified to auto-download if non-existent

   for i in ${AFFECTED_PATHS[@]}; do
      if [ -d "${i}" ]; then
	 echo -e "${TEXT_RED}Resetting directory: ${i}${TEXT_RESET}"
	 pushd ${i}
	 SHA=$(git status | grep -E -o -e "[a-fA-F0-9]{7}")
	 git reset --hard $SHA
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
      #return 0
      VERSION_CODE=11.0
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
   
   export GERRIT_URL="http://review.cyanogenmod.org"
   python3 /home/brysoncg/android/gerrit_changes.py \
       `# external/koush/Superuser` \
       'http://review.cyanogenmod.org/#/c/54969/' `# su: use bash as default shell` \
       `# device/samsung/jflte` \
       'http://review.cyanogenmod.org/#/c/60397/' `# jflte: init updates from NB8` \
       `# device/samsung/qcom-common` \
       'http://review.cyanogenmod.org/#/c/60398/' `# samsung_qcom-common: updates from NB8` \
       `# device/samsung/msm8960-common` \
       'http://review.cyanogenmod.org/#/c/60730/' `# samsung-msm8960: kk gps hal` \
       `# device/samsung/jflte` \
       'http://review.cyanogenmod.org/#/c/60733/' `# jf: remove gps hal` \
       `# device/samsung/jflte` \
       'http://review.cyanogenmod.org/#/c/60904/' `# jflte: improve boot speed` \
       `# device/samsung/jflte` \
       'http://review.cyanogenmod.org/#/c/60994/' `# jlte: Unbreak network mode options` \
       `# device/samsung/msm8960-common` \
       'http://review.cyanogenmod.org/#/c/61001/' `# msm8960-common: GPS hal should actually support MSM8960` \
       || { GERRIT_SUCCESS=1; echo -e "${TEXT_RED}*** FAILED TO APPLY PATCHES ***${TEXT_RESET}"; }
   
   # For bash with adb: To set to bash: setprop persist.sys.adb.shell /system/xbin/bash
   
   TEMP_SUCCESS=$GERRIT_SUCCESS
      
      ############# use https://github.com/dcd11/proprietary_vendor_samsung.git branch gps
      # `# device/samsung/jflte` \
      # 'http://review.cyanogenmod.org/#/c/60397/' `# jflte: init updates from NB8` \
      # `# device/samsung/qcom-common` \
      # 'http://review.cyanogenmod.org/#/c/60398/' `# samsung_qcom-common: updates from NB8` \
      # `# device/samsung/jflte` \
      # 'http://review.cyanogenmod.org/#/c/60569/' `# jflte: ueventd.qcom.rc: cleanup DO NOT USE WITH 60397!!` \
      # `# device/samsung/msm8960-common` \
      # 'http://review.cyanogenmod.org/#/c/60730/' `# samsung-msm8960: kk gps hal` \
      # `# device/samsung/jflte` \
      # 'http://review.cyanogenmod.org/#/c/60733/' `# jf: remove gps hal` \
      # `# device/samsung/jflte` \
      # 'http://review.cyanogenmod.org/#/c/60904/' `# jflte: improve boot speed` \

      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS` \
      # DO NOT USE ABOVE WITH NEW KERNEL PATCHES: particularly 56214: jf: Remove the GPS header
      ########## REMEMBER WIFI MODULE PATCH IN HIGHSENSE PATCH GROUP!!!!!!
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56070/' `# jf: Updates for new kernel` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56167/' `# jf: Remove Vector hack` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56168/' `# jf: Remove modem links scripts` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56169/' `# jf: Update NFC configuration` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56170/' `# jf: Update init scripts` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56171/' `# jf: Update the blob list for ML4` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56213/' `# jf: Enable background scan support` \
      # `# device/samsung/jf-common` \
      # 'http://review.cyanogenmod.org/#/c/56214/' `# jf: Remove the GPS header` \
      # ABOVE CURRENTLY BREAKS THE BUILD. FILES STILL RELY ON THE HEADER FILE.
      # Problem: Requires use of new kernel branch: https://github.com/CyanogenMod/android_kernel_samsung_jf/tree/wip-ml4
   # Didn't work - he has his directories named differently...
   # Gerrit pulls from Xiao-Long Chen's gerrit...
   #python3 /home/brysoncg/android/gerrit_changes.py \
   #    `# packages/apps/Dialer` \
   #    'http://gerrit.cxl.epac.to/#/c/1/' `# Dialer: Support for forward/reverse lookups` \
   #    `# packages/apps/InCallUI` \
   #    'http://gerrit.cxl.epac.to/#/c/2/' `# InCallUI: Add phone number service` \
   #    `# packages/services/Telephony` \
   #    'http://gerrit.cxl.epac.to/#/c/3/' `# Telephony: Add setting for forward/reverse lookup` \
   #    `# frameworks/base` \
   #    'http://gerrit.cxl.epac.to/#/c/4/' `# Frameworks: Add settings key for forward/reverse lookups` \
   #    `# frameworks/base` \
   #    'http://gerrit.cxl.epac.to/#/c/5/' `# AccountManagerService: Allow com.android.dialer to access account data` \
   #    `# packages/services/Telephony` \
   #    'http://gerrit.cxl.epac.to/#/c/6/' `# Use PackageManager to detect Google Play Services install` \
   #    `# packages/services/Telephony` \
   #    'http://gerrit.cxl.epac.to/#/c/7/' `# Telephony: Fix reverse lookup gms logic detection` \
   #    `# packages/apps/Dialer` \
   #    'http://gerrit.cxl.epac.to/#/c/8/' `# Dialer: Use PackageManager to detect Google Play Services install` \
   #    `# packages/apps/Dialer` \
   #    'http://gerrit.cxl.epac.to/#/c/9/' `# [2/2] Dialer: Add WhitePages Canada reverse lookup provider` \
   #    `# packages/services/Telephony` \
   #    'http://gerrit.cxl.epac.to/#/c/10/' `# [1/2] Telephony: Add setting for WhitePages Canada reverse lookup` \
   #    `# packages/apps/Dialer` \
   #    'http://gerrit.cxl.epac.to/#/c/11/' `# Nitpicks` \
   #    || { GERRIT_SUCCESS=1; echo -e "${TEXT_RED}*** FAILED TO APPLY PATCHES ***${TEXT_RESET}"; }
   
   # Add the following line to the end of each cherry-pick enable fail-out of build if merge fails
   # || GERRIT_SUCCESS=1
   
   popd
   return $GERRIT_SUCCESS
}

export -f apply_gerrit_picks
