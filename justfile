builddir := absolute_path('build')
installdir := absolute_path('install')
default_profile := 'debug'
default_targetdir := 'rizin'
default_options := '--native-file=asan.ini'

alias s := setup
alias b := build
alias t := test
alias i := install
alias rt := rtest
alias at := atest

setup targetdir=default_targetdir profile=default_profile args=default_options :
	@mkdir -p {{builddir}}/{{targetdir}}/{{profile}}
	@mkdir -p {{installdir}}
	meson setup {{args}} --buildtype={{profile}} --prefix=`realpath {{installdir}}` {{builddir}}/{{targetdir}}/{{profile}} {{targetdir}}

build targetdir=default_targetdir profile=default_profile: (setup targetdir profile)
	meson compile -C {{builddir}}/{{targetdir}}/{{profile}}

test targetdir=default_targetdir profile=default_profile: (build targetdir profile)
	meson test -C {{builddir}}/{{targetdir}}/{{profile}} --verbose

install targetdir=default_targetdir profile=default_profile: (build targetdir profile)
	meson install -C {{builddir}}/{{targetdir}}/{{profile}}

rtest profile="debug": (install "rizin" profile)
	#!/usr/bin/env bash
	export PATH=`realpath {{installdir}}`/bin:$PATH
	rz-test -qi rizin/test/db/cmd/cmd_aL
	rz-test -qi rizin/test/db/cmd/cmd_list

atest target='h8300' profile="debug": (install "rizin" profile) (rtest profile)
	#!/usr/bin/env bash
	export PATH=`realpath {{installdir}}`/bin:$PATH
	rz-test -qi rizin/test/db/rzil/{{target}}
	rz-test -qi rizin/test/db/asm/{{target}}
	rz-test -qi rizin/test/db/analysis/{{target}}

clean:
	rm -rf {{builddir}} {{installdir}}

setup-cutter profile=default_profile:
	cmake -B build/cutter/{{profile}} -S cutter -DCUTTER_USE_BUNDLED_RIZIN=OFF -DCUTTER_ENABLE_PYTHON=ON -DCUTTER_ENABLE_PYTHON_BINDINGS=ON -DCUTTER_ENABLE_GRAPHVIZ=ON -DCUTTER_QT6=ON -GNinja -DCMAKE_BUILD_TYPE={{profile}}
build-cutter profile=default_profile:
	cmake --build build/cutter/{{profile}}
