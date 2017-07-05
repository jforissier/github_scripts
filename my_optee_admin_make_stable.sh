#!/bin/bash -e
export MY_ALLREPO='default qemu_v8 fvp hikey hikey_debian juno mt8173-evb rpi3 dra7xx'

if [ -e "$MY_OPTEE_RELEASE_ROOT" ] ; then
	echo "Remove the used directory first using"
	echo "    rm -rf $MY_OPTEE_RELEASE_ROOT"
	exit 1
fi;

if [[ "$1" == "" ]]; then
	echo "Please enter a tag as an argument, such as 3.0.1"
	echo "Abort..."
	exit 1
fi;

export MY_TAG=$1

if [[ "$2" != "" ]]; then
	export NO_REVISION_REPLACE=$2
fi;

echo "New tag will be $MY_TAG"
read -p "Agree ? (Y/N) "

if [[ $REPLY =~ Y$ ]]; then
	echo "Let's go"
else
	echo "Abort..."
	exit 1
fi

mkdir -p $MY_OPTEE_RELEASE_ROOT && cd $MY_OPTEE_RELEASE_ROOT
repo init -u https://github.com/OP-TEE/manifest.git --reference $MY_OPTEE_REFERENCE_REPO
    cd ${MY_OPTEE_RELEASE_ROOT}/.repo/manifests && \
        git remote rename origin optee && \
        git remote add origin git@${MY_OPTEE_DEV_GITHUB_ADDRESS}:${MY_OPTEE_DEV_GITHUB_ACCOUNT}/manifest.git && \
        git remote add upstream git@${MY_OPTEE_DEV_GITHUB_ADDRESS}:OP-TEE/manifest.git && \
        git remote rm optee && git fetch --all && \
        git checkout -b stable_single upstream/master

for MY_REPO_TARGET in $MY_ALLREPO
do
  echo ============================== $MY_REPO_TARGET
  cd $MY_OPTEE_RELEASE_ROOT/.repo
  rm -f manifest.xml
  ln -s manifests/$MY_REPO_TARGET.xml manifest.xml
  # Clean qemu:
  # qemu/dtc may be checked out separately by the manifest [1], in which case "repo sync" may fail with:
  #   error: Cannot remove project "qemu": uncommitted changes are present
  #      commit changes, then run sync again
  # [1] First introduced in https://github.com/OP-TEE/manifest/commit/52b4d0783cdc
  [ -e $MY_OPTEE_RELEASE_ROOT/qemu ] && cd $MY_OPTEE_RELEASE_ROOT/qemu && rm -rf dtc && git checkout -- dtc
  cd $MY_OPTEE_RELEASE_ROOT && repo sync -j4 --force-sync --no-clone-bundle
  cd $MY_OPTEE_RELEASE_ROOT && repo manifest -o .repo/manifests/${MY_REPO_TARGET}_stable.xml -r
  if [[ -z $NO_REVISION_REPLACE ]]; then
	echo "Replace revsion"
	$MY_OPTEE_ADMIN_SCRIPT_ROOT/my_optee_fix_stable.py -t $MY_TAG -i .repo/manifests/${MY_REPO_TARGET}_stable.xml
  else
	echo "Don't replace revsion"
	$MY_OPTEE_ADMIN_SCRIPT_ROOT/my_optee_fix_stable.py -t $MY_TAG -i .repo/manifests/${MY_REPO_TARGET}_stable.xml -n
  fi
  cd $MY_OPTEE_RELEASE_ROOT/.repo/manifests
  git add ${MY_REPO_TARGET}_stable.xml
  git commit -s -m "${MY_REPO_TARGET}_stable.xml"
done

# Squash
cd $MY_OPTEE_RELEASE_ROOT/.repo/manifests
git checkout -b stable upstream/master
git merge --squash stable_single
git commit -s -m "Stable versions of manifests on $MY_TAG"

echo "To Finalize:"
echo "- Create a pull-request for the new stable manifests, with:"
echo "    cd $MY_OPTEE_RELEASE_ROOT/.repo/manifests"
echo "    gitk"
echo "    git push origin stable"
echo "  followed by the creation of the pull-request in github.com"
