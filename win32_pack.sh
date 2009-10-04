#!/bin/zsh

cd "$(dirname "$0")"
distribdir="$(pwd)"

source functions.sh

olxdir="$(guess_olx_dir)"
cd $olxdir
olxdir="$(pwd)" # to have absolute filename

if ! is_olx_dir "$olxdir"; then
	echo "Cannot find openlierox dir. Fix functions.sh."
	exit 1
fi


VERSION="$(get_olx_version)"
echo ">>> preparing $VERSION archives ..."

for fileext in exe pdb map; do
	f="${olxdir}/bin/OpenLieroX.${fileext}"
	[ -e $f ] && echo "rename $(basename $f)" && \
	mv $f ${olxdir}/bin/"OpenLieroX $(get_olx_human_version).${fileext}"
done


win32_files=(doc COPYING.LIB ${olxdir}/share/gamedir/* bin/OpenLieroX.exe ${distribdir}/win32/*)
win32patch_files=("bin/OpenLieroX $(get_olx_human_version).exe" share/gamedir/cfg share/gamedir/data ${distribdir}/win32/*)
win32debug_files=("bin/OpenLieroX $(get_olx_human_version)".{exe,pdb,map} bin/vc80.{pdb,idb} ${olxdir}/src ${olxdir}/include)


# $1 - zip filename
# $[1:] - array of files
function create_archiv() {
	files=($*)
	files=($files[2,-1])
	zipfile=$1

	rm -f $zipfile 2>/dev/null
	echo ">>> creating $(basename $zipfile) ..."

	cd ${distribdir} || {
		echo "create_archiv: cd to distrib failed"
		return 1
	}

	[ -d win32tmp ] && rm -rf win32tmp
	mkdir -p win32tmp/OpenLieroX || {
		echo "create_archiv: cannot create tmp directory"
		return 1
	}

	for f in $files; do
		[ "$f[1]" != "/" ] && f="${olxdir}/$f"
		{ tar -c \
			--exclude=.svn --exclude=.git --exclude=.pyc --exclude=~ \
			-C "$(dirname $f)" "$(basename $f)" \
		| tar -x -C win32tmp/OpenLieroX; } || {
			echo "create_archiv $(basename $zipfile): Couldn't copy $f"
			return 1
		}
		echo -n "+"
	done

	cd win32tmp
	zip -r -9 $zipfile OpenLieroX | { while read t; do echo -n "."; done; } || {
		echo "create_archiv $(basename $zipfile): error while zipping"
		return 1
	}
	cd ..

	rm -rf win32tmp
	echo " *"

}


create_archiv "${distribdir}/$(get_olx_win32debug_fn)" $win32debug_files && \
create_archiv "${distribdir}/$(get_olx_win32patch_fn)" $win32patch_files && \
create_archiv "${distribdir}/$(get_olx_win32_fn)" $win32_files