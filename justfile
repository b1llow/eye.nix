builddir := absolute_path('build')
installdir := absolute_path('install')
default_profile := 'debug'
default_targetdir := 'rizin'

alias b := build
alias t := test
alias i := install
alias at := asmtest

setup targetdir=default_targetdir profile=default_profile:
	@mkdir -p {{builddir}}/{{targetdir}}/{{profile}}
	@mkdir -p {{installdir}}
	meson setup --buildtype={{profile}} --prefix=`realpath {{installdir}}` {{builddir}}/{{targetdir}}/{{profile}} {{targetdir}}

build targetdir=default_targetdir profile=default_profile: (setup targetdir profile)
	meson compile -C {{builddir}}/{{targetdir}}/{{profile}}

test targetdir=default_targetdir profile=default_profile: (build targetdir profile)
	meson test -C {{builddir}}/{{targetdir}}/{{profile}} --print-error-stack --verbose

install targetdir=default_targetdir profile=default_profile: (build targetdir profile)
	meson install -C {{builddir}}/{{targetdir}}/{{profile}}

asmtest target='h8500' targetdir="rizin" profile="debug": (install targetdir profile)
	#!/usr/bin/env bash
	export PATH=`realpath {{installdir}}`/bin:$PATH
	rz-test -qi rizin/test/db/asm/{{target}}

clean:
	rm -rf {{builddir}} {{installdir}}
