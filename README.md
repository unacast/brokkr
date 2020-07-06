# brokkr
A Makefile dependency tool

## Install
Brokkr installs itself in your project by either adding a Makefile or adding itself to an existing Makefile. This oneliner will install the latest version.

`curl https://raw.githubusercontent.com/unacast/brokkr/master/scripts/install.sh | bash`

## Usage
Add references to the online Makefiles you would like to add to your project/Makefile. This could be Brokkr-specific makefiles, like the ones under [plugins](https://github.com/unacast/brokkr/tree/master/plugins/).

Example:
```
BROKKR_PLUGINS = help/help@master airflow/airflow@v0.4.3
.DEFAULT_GOAL := help
```

## How does it work?
It works by downloading the `Makefile` dependencies you add to your local folder. Once downloaded they are included into your `Makefile` so that every target is available.
