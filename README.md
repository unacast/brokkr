# brokkr
A Makefile dependency tool

## Install
`curl https://raw.githubusercontent.com/judoole/brokkr/master/scripts/install.sh | bash`

## Usage
Add references to the online Makefiles you would like to add to your project/Makefile. This could be Brokkr-specific makefiles, like the ones under [plugins](https://github.com/judoole/brokkr/tree/master/plugins/) or Makefiles on a http(s) url.

Example:
```
# Her we reference a versioned (git sha c09a208) of the Brokkr plugin help, 
# and an url to a hello world markdown file
BROKKR_PLUGINS = help/help-c09a208.mk \
                 https://raw.githubusercontent.com/judoole/brokkr/master/example/helloworld.mk
.DEFAULT_GOAL := help
```

## How does it work?
It works by downloading the `Makefile` dependencies you add to your local folder. Once downloaded they are included into your `Makefile` so that every target is available.
