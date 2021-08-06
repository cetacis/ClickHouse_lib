#!/usr/bin/env bash

set -e
# set -x
DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIR"/src
# if [ "$(git branch --show-current)" != "master" ]; then
# 	echo "You can only release under the master branch."
# 	exit 1
# fi

# if [ -n "$(git status --untracked-files=no --porcelain)" ]; then
# 	echo "The working tree is dirty. Please commit/stash it before building."
# 	exit 1
# fi
# git pull --tags

version=$(git describe --tags --abbrev=0 --exact-match || (
	echo "There is no tag on current commit. Will use <commit_hash>" >&2
	echo ckx-$(git rev-parse --short HEAD)
))

read -p "Do you want to release $version now? (NOTE you may need to clean up the builder directory first) [Enter to continue, Ctrl-C to quit]" -n 1 -r
echo

dir=$version
cd ..
b ckx
if [ -f build-ckx/programs/clickhouse ]; then
	rm -rf "$dir" "$dir".tar.gz $dir.debug
	mkdir -p "$dir"/bin "$dir"/run
	cp -r src/etc "$dir"/conf
	cp -r src/sbin "$dir"/
	rsync -aHS --exclude='*odbc*' "$DIR"/build-ckx/programs/clickhouse* "$dir"/bin/

	pushd $dir/bin
	objcopy --only-keep-debug clickhouse clickhouse.debug
	strip --strip-debug --strip-unneeded clickhouse
	objcopy --add-gnu-debuglink="clickhouse.debug" "clickhouse"
	strip --strip-debug --strip-unneeded clickhouse-odbc-bridge
	popd
	mv $dir/bin/clickhouse.debug $dir.debug

	tar czf "$dir".tar.gz "$dir"
else
	echo "build-ckx/programs/clickhouse doesn't exist. Build it with 'b ckx'."
	exit 1
fi
