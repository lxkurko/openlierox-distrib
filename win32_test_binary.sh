#!/bin/zsh

source "$(dirname "$0")"/functions.sh

if [ "$1" != "" ]; then
	bin="$1"
	# if no absolute filename, add $(pwd)
	[ "$(echo "$bin" | head -c 1)" != "/" ] && bin="$(pwd)/$1"
	if ! is_olx_macosx_bin "$bin"; then
		echo "Given parameter $bin is not a MacOSX binary."
		exit 1
	fi
else
	bin="$(get_olx_macosx_bin)"
	
	if ! is_olx_macosx_bin "$bin"; then
		echo "Guessed filename $bin is not a MacOSX binary."
		exit 1
	fi	
fi

libtmpdir="/Library/Frameworks/tmp"
mkdir -p "$libtmpdir" || {
	echo "Cannot create ${libtmpdir}."
	exit 1
}

ret=0

# We move the frameworks to a temporary directory to be sure that all linking
# is correct (fixed by osx_fix_binary.sh) and that OLX runs on a clean system.
frameworks=("$bin/Contents/Frameworks/"*.framework)
frameworks=(${frameworks:t})
for fr in $frameworks; do
	mv "/Library/Frameworks/$fr" "${libtmpdir}/" || ret=1
done

test_olx_bin "${bin}/Contents/MacOS/OpenLieroX" || {
	echo "Error while running OpenLieroX."
	ret=1
}

# cleanup
for fr in $frameworks; do
	mv "${libtmpdir}/$fr" "/Library/Frameworks/"
done
rmdir "${libtmpdir}"

exit $ret
