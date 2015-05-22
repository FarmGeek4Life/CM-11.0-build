#!/bin/bash

SHELL=/bin/bash

function reset_git_dir()
{
   git reset --hard
   git clean -fdx
}

export -f reset_git_dir

function clean_custom_patches()
{ 
   VERSION_CODE="$1" # Valid values: depends on existing directories
   BASE_DIR="/home/brysoncg/android/system$VERSION_CODE"
   
   TEXT_GREEN='\e[1;32m' # Bold and Red
   TEXT_RED='\e[1;31m'   # Bold and Green
   TEXT_RESET='\e[0m'    # Reset
   
   if [ "$VERSION_CODE" != "12.1" ]; then
      #return 0
      VERSION_CODE=12.1
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   AFFECTED_PATHS=(
       'device/samsung/jf-common'
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
   PATCHES="/home/brysoncg/android/CM-build-tools"
   MY_PATCHES="/home/brysoncg/android/CM-build-tools/my-patches"
   echo -ne "${TEXT_GREEN}"
   echo "Using patch file directory: ${PATCHES}"
   echo -ne "${TEXT_RESET}"
   
   pushd device/samsung/jf-common
      echo "$(pwd)"
      echo -ne "${TEXT_GREEN}"
      echo -e "$PATCH_STAT:\t\t Device patches"
      echo -ne "${TEXT_RESET}"
      $PATCH $PATCH_ARGS < ${MY_PATCHES}/jf-common.patch
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
   
   if [ "$VERSION_CODE" != "12.1" ]; then
      #return 0
      VERSION_CODE=12.1
   fi
   
   # Enter the directory
   pushd $BASE_DIR
   
   AFFECTED_PATHS=(
       'device/samsung/jf-common'
       'device/samsung/jflteatt'
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
   
   if [ "$VERSION_CODE" != "12.1" ]; then
      #return 0
      VERSION_CODE=12.1
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
       `# device/samsung/jf-common` \
       'http://review.cyanogenmod.org/#/c/98728/' `# rootdir: Fix LTE doesn't come up on boot` \
       'http://review.cyanogenmod.org/#/c/98729/' `# sepolicy: More rild denials` \
       `# device/samsung/jflteatt` \
       'http://review.cyanogenmod.org/#/c/99095/' `# jflteatt: update fingerprint to 5.0.1` \
       'http://review.cyanogenmod.org/#/c/99096/' `# jflteatt: Update default apn` \
       || { GERRIT_SUCCESS=1; echo -e "${TEXT_RED}*** FAILED TO APPLY PATCHES ***${TEXT_RESET}"; }
   
   # For bash with adb: To set to bash: setprop persist.sys.adb.shell /system/xbin/bash
   
   TEMP_SUCCESS=$GERRIT_SUCCESS
      
   
   # Add the following line to the end of each cherry-pick enable fail-out of build if merge fails
   # || GERRIT_SUCCESS=1
   
   popd
   return $GERRIT_SUCCESS
}

export -f apply_gerrit_picks
