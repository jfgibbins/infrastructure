#!/bin/bash

##
# BASH dynamic menu script built from tree:
##

export build_root="."

source ${build_root}/900-Misc/911-Includes/menu.inc

run_menu() {
menu=(${options_0[*]})
index=1
PS3="Menu for Greywolfe Enviroment build: "
while true; do
	let len=${#menu[@]}-1
	if [ -z $menu ]; then menu=("Exit"); fi
	if [ ${menu[${len}]} != "Exit" ] && [ ${menu[${len}]:4:4} != "Exit" ]; then menu+=("Exit"); fi
	select reply in ${menu[@]}; do
		if [ -z $reply ]; then break; fi
		if [ $reply == "Exit" ] && [ $index == 1 ]; then break 2; fi
		if [ $reply == "Exit" ] && [ $index == 2 ]; then menu=(${options_0[*]}); index=1; break; fi
		if [ $reply == "Exit" ]; then menu=(${lastmenu[@]}); let index--; break; fi
		if [ $index -lt 3 ]; then lastmenu=(${menu[@]}); fi
		menu=options_${reply:0:2}[*]
		menu=(${!menu})
		case $index in
			1) menu_path=${build_root}/$reply; let index++; break;;
			2) let index++; break;;
			3) ${menu_path}/$reply/menu.sh; break;;
			*) let index--; break;;
		esac
	done
done
}

create_menu() {
	for f in `tree ${build_root} | egrep -o -e '[0-9][0-9][0-9]-.*[^-]'`; do
		case ${f:1:2} in 00)	options_0+=(${f}); continue; esac
		case ${f:2:1} in 0)	option=options_${f:0:1}0; g=`echo -e ${f} | grep -o -e '[0-9][0-9][0-9]-[^-]*'`; eval "${option}+=(${g})"; esac
		case ${f} in	*)	option=options_${f:0:2}; eval "${option}+=(${f})"; continue; esac
	done
	options_00+=("Exit")
}

create_menu
run_menu
