_GIT_SHA1=$(shell git rev-parse HEAD)
_GIT_SHA1_SHORT=$(shell git rev-parse --short HEAD)
_GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
_GIT_AUTHOR=$(shell git show -s --format='%ae')


.PHONY: _git.buildinfo
_git.buildinfo:
	$(if $(value BUILD_INFO_PATH),, $(error BUILD_INFO_PATH environment variable is not set.\
		Add this to your Makefile.))
	echo [git] > $(BUILD_INFO_PATH)
	echo sha1=$(_GIT_SHA1) >> $(BUILD_INFO_PATH)
	echo sha1_short=$(_GIT_SHA1_SHORT) >> $(BUILD_INFO_PATH)
	echo branch=$(_GIT_BRANCH) >> $(BUILD_INFO_PATH)
	echo author=$(_GIT_AUTHOR) >> $(BUILD_INFO_PATH)
	echo [build] >> $(BUILD_INFO_PATH)
	echo deployed_by=$(USER) >> $(BUILD_INFO_PATH)
	echo unix_timestamp=`date +%s` >> $(BUILD_INFO_PATH)
