# github_scripts

## OP-TEE Administration

### Installation

	cd $HOME
	# Update following github.dev.com according to your .ssh/config file
	mkdir -p $HOME/git_clone/pascal-brand-st-dev && cd $HOME/git_clone/pascal-brand-st-dev
	git clone git@github.dev.com:pascal-brand-st-dev/github_scripts
	source $HOME/git_clone/pascal-brand-st-dev/github_scripts/optee_admin_env.source
	my_optee_admin_clone

The file `.ssh/config` must contain your github OP-TEE administration
account setup, something like

	Host github.admin.com
	  user pascal-brand-st
	  identityFile ~/.ssh/id_rsa_github_admin
	  hostname 192.30.252.131
	  # hostname github.com


### Merging Pull-Requests

Before merging a pull-request, one has to check:
- the PR is correctly rebased (the pull-request follows master)
- tags _Reviewed-by_ and/or _Tested-By_ are set on all commits
- Travis is happy, or errors are _under control_
- the code did not change with respect to the previous review (quickly done
  to ensure there is no stupid things)

Then the steps to merge are:

1/ Setup the script environment

	source $HOME/git_clone/pascal-brand-st-dev/github_scripts/optee_admin_env.source

2/ Check the pull-request is ok, by fetching and opening gitk

	export prnumber=759 ; my_optee_admin_check ${MY_OPTEE_ROOT}/optee_os
	export prnumber=85  ; my_optee_admin_check ${MY_OPTEE_ROOT}/optee_test
	export prnumber=47  ; my_optee_admin_check ${MY_OPTEE_ROOT}/optee_client
	export prnumber=45  ; my_optee_admin_check ${MY_OPTEE_ROOT}/optee_linuxdriver
	export prnumber=63  ; my_optee_admin_check ${MY_OPTEE_ROOT}/build
	export prnumber=28  ; my_optee_admin_check ${MY_OPTEE_ROOT}/manifest
	export prnumber=10  ; my_optee_admin_check ${MY_OPTEE_ROOT}/gen_rootfs
	export prnumber=4   ; my_optee_admin_check ${MY_OPTEE_ROOT}/bios_qemu_tz_arm
	export prnumber=1   ; my_optee_admin_check ${MY_OPTEE_ROOT}/arm-trusted-firmware
	export prnumber=3   ; my_optee_admin_check ${MY_OPTEE_ROOT}/linux
	export prnumber=1   ; my_optee_admin_check ${MY_OPTEE_ROOT}/patches_hikey

3/ You may want to diff the pull-request outside of gitk

	git difftool upstream/master upstream/pr/$prnumber

4-a/ Finally merge on the correct branch, using one of the following:

	my_optee_admin_merge master
	my_optee_admin_merge optee
	my_optee_admin_merge optee_paged_armtf_v1.2

4-b/ However, in some cases, you would like to merge _manually_ a pull-request
that has not been rebased. The steps are (to be adapted if the pull-request
contains several commits and to push on another branch than master):

	git checkout -b adminpr_$prnumber upstream/master
	git cherry-pick upstream/pr/$prnumber
	gitk
	git push upstream adminpr_$prnumber:master
	# Then close the pull-request from github interface, using the github
	# OP-TEE admin account, with the comment "Manually merged"



### Setting tags

_**EARLY VERSION - NEVER USED IN A REAL RELEASE**_

- Update, in `optee_os`:
	- Release notes in `CHANGELOG.md`
	- `CFG_OPTEE_REVISION_MAJOR` and `CFG_OPTEE_REVISION_MINOR`
- Create tags on components: `$HOME/git_clone/pascal-brand-st-dev/github_scripts/my_optee_admin_make_tag.sh 3.0.0`
- Create stable manifest: `$HOME/git_clone/pascal-brand-st-dev/github_scripts/my_optee_admin_make_stable.sh 3.0.0`



