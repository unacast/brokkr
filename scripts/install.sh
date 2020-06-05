#!/bin/bash

VERSION=${VERSION:=latest}
TAG=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/unacast/brokkr/releases/${VERSION} | cut -d '/' -f8`

# Download brokkr.mk for TAG into brokkr folder
mkdir -p brokkr
curl --fail -s "https://raw.githubusercontent.com/unacast/brokkr/${TAG}/brokkr/brokkr.mk" -o brokkr/brokkr.mk

# Add Brokkr to Makefile or create Makefile if it does not exist
if [ ! -f "Makefile" ]; then
	echo '.SILENT: ;' > Makefile
	echo 'BROKKR_PLUGINS = help/help@master' >> Makefile
	echo '.DEFAULT_GOAL := help' >> Makefile
	echo -e '\n-include ./brokkr/brokkr.mk' >> Makefile
elif [[ ! `grep 'include ./brokkr/brokkr.mk' Makefile` ]]; then
	echo -e '\n-include ./brokkr/brokkr.mk' >> Makefile
fi

# Add version
(echo "BROKKR_VERSION=${TAG}" && cat brokkr/brokkr.mk) > /tmp/brokkr.mk && mv /tmp/brokkr.mk brokkr/brokkr.mk

# Edit .gitignore - if present
if [[ -f ".gitignore" ]] && ! grep -q "brokkr/plugins/" .gitignore 2>/dev/null; then
  echo -e '\n# Working folder for Brokkr' >> .gitignore
  echo -e 'brokkr/plugins/' >> .gitignore
fi