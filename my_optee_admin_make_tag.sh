#!/bin/bash -e

if [[ "$1" == "" ]]; then
	echo "Please enter a tag as an argument, such as 3.0.1"
	echo "Abort..."
	exit 1
fi;

export MY_TAG=$1
read -p "New tag will be $MY_TAG? (Y/N) "
if [[ $REPLY =~ Y$ ]]; then
	echo "Let's go"
else
	echo "Abort..."
	exit 1
fi

unset MY_ALLDIRS
read -p "Do you want to tag 'manifest'? (Y/N) "
if [[ $REPLY =~ Y$ ]]; then
	export MY_ALLDIRS="$MY_ALLDIRS manifest"
fi
read -p "Do you want to tag 'optee_client optee_os optee_test build'? (Y/N) "
if [[ $REPLY =~ Y$ ]]; then
	export MY_ALLDIRS="$MY_ALLDIRS optee_client optee_os optee_test build"
fi

echo ""
echo ""
echo "to remove all the local tags, please run"
echo "    for dir in $MY_ALLDIRS"
echo "    do"
echo "      echo ============================== ${MY_OPTEE_ROOT}/\$dir"
echo "      cd ${MY_OPTEE_ROOT}/\$dir && git tag --delete $MY_TAG"
echo "      if [[ \$? != 0 ]]; then"
echo "          echo FAILED: Cannot push the tag on upstream"
echo "          break"
echo "      fi;"
echo "    done"
echo ""
echo ""

# Check the tag exist
for dir in $MY_ALLDIRS
do
	echo ============================== ${MY_OPTEE_ROOT}/$dir
	cd ${MY_OPTEE_ROOT}/$dir
	echo "Fetch and go on upstream/master..."
	git fetch --all &> /dev/null
	git checkout upstream/master &> /dev/null

	echo "Check tag exists on remote..."
	if [[ `git ls-remote --tags upstream 2>/dev/null | grep -cF refs/tags/$MY_TAG` != 0 ]]; then
		echo "Tag $TAG_NAME exists on remote. Please remove it carefully if required"
		echo "Abort..."
		exit 1
	fi

	echo "Check tag exists locally..."
	if [[ `git tag 2>/dev/null | grep -cF $MY_TAG` != 0 ]]; then
		echo "Tag $MY_TAG exists locally"
		read -p "Do you want to remove the local tag? (Y/N) "
		if [[ $REPLY =~ Y$ ]]; then
			git tag --delete $MY_TAG
		else
			echo "Abort..."
			exit 1
		fi
	fi

	if [ "$dir" == "optee_os" ]; then
		export MY_MAJOR=`echo $MY_TAG | cut -d "." -f1`
		export MY_MINOR=`echo $MY_TAG | cut -d "." -f2`
		echo "Check CHANGE.log updated with the tag..."
		if [[ `grep -cF "OP-TEE - version $MY_MAJOR.$MY_MINOR" CHANGELOG.md` == 0 ]]; then
			echo "Cannot find in CHANGELOG.md: OP-TEE - version $MY_MAJOR.$MY_MINOR"
			echo "Abort..."
			exit 1
		fi;

		echo "Check CFG_OPTEE_REVISION_MAJOR and CFG_OPTEE_REVISION_MINOR are up-to-date..."
		if [[ `grep -cF "CFG_OPTEE_REVISION_MAJOR ?= $MY_MAJOR" mk/config.mk` == 0 ]]; then
			echo "Cannot find in mk/config.mk: CFG_OPTEE_REVISION_MAJOR ?= $MY_MAJOR"
			echo "Abort..."
			exit 1
		fi;
		if [[ `grep -cF "CFG_OPTEE_REVISION_MINOR ?= $MY_MINOR" mk/config.mk` == 0 ]]; then
			echo "Cannot find in mk/config.mk: CFG_OPTEE_REVISION_MINOR ?= $MY_MINOR"
			echo "Abort..."
			exit 1
		fi;
	fi
done

read -p "Check are OK. Wants to set local tags? (Y/N) "
if [[ $REPLY =~ Y$ ]]; then
	echo "Go... Setting local tag $MY_TAG"
else
	echo "Abort..."
	exit 1
fi

for dir in $MY_ALLDIRS
do
	echo ============================== ${MY_OPTEE_ROOT}/$dir
	cd ${MY_OPTEE_ROOT}/$dir
	echo "git tag -a $MY_TAG"
	git tag -a $MY_TAG -m "$MY_TAG"
done

echo "To finalize and push the tag on upstream, please run:"
echo "    for dir in $MY_ALLDIRS"
echo "    do"
echo "      echo ============================== ${MY_OPTEE_ROOT}/\$dir"
echo "      cd ${MY_OPTEE_ROOT}/\$dir && git push upstream $MY_TAG && gitk --all"
echo "      if [[ \$? != 0 ]]; then"
echo "          echo FAILED: Cannot push the tag on upstream"
echo "          break"
echo "      fi;"
echo "    done"
