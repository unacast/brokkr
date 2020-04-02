#!/bin/bash

mkdir -p brokkr
curl --fail -s "https://raw.githubusercontent.com/unacast/brokkr/master/brokkr/brokkr.mk" -o brokkr/brokkr.mk

if [ ! -f "Makefile" ]; then
	echo '.SILENT: ;' > Makefile
	echo 'BROKKR_PLUGINS = help/help-master.mk' >> Makefile
	echo '.DEFAULT_GOAL := help' >> Makefile
	echo -e '\n-include ./brokkr/brokkr.mk' >> Makefile
elif [[ ! `grep 'include ./brokkr/brokkr.mk' Makefile` ]]; then
	echo -e '\n-include ./brokkr/brokkr.mk' >> Makefile
fi
