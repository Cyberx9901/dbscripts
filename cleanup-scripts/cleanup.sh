#!/bin/bash

usage() {
  echo "Usage: $0 repo architecture"
}

getpkgname() {
  local tmp

  tmp=${1##*/}
  tmp=${tmp%.pkg.tar.gz}
  tmp=${tmp%-i686}
  tmp=${tmp%-x86_64}
  echo ${tmp%-*-*}
}

FTPBASEDIR="/home/ftp"
FTPDIR=${FTPBASEDIR}/${1}/os/${2}
DBFILE=${FTPDIR}/${1}.db.tar.gz
MISSINGFILES=""
DELETEFILES=""

if [ $# -lt 2 -o ! -f ${DBFILE} ]; then
  usage
  exit 1
fi

TMPDIR=$(mktemp -d /tmp/cleanup.XXXXXX) || exit 1

cd ${TMPDIR}
tar xzf ${DBFILE}
for pkg in *; do
  filename=$(grep -A1 '^%FILENAME%$' ${pkg}/desc | tail -n1)
  [ -z "${filename}" ] && filename="${pkg}.pkg.tar.gz"
  if [ ! -f ${FTPDIR}/${filename} ]; then
    MISSINGFILES="${MISSINGFILES} ${filename}"
  else
    pkgname="$(getpkgname ${filename})"
    for otherfile in ${FTPDIR}/${pkgname}-*; do
      otherfile="$(basename ${otherfile})"
      if [ "${otherfile}" != "${filename}" -a "${pkgname}" = "$(getpkgname ${otherfile})" ]; then
        DELETEFILES="${DELETEFILES} ${otherfile}"
      fi
    done
  fi
done

cd - >/dev/null
rm -rf ${TMPDIR}

echo -ne "DIRECTORY:\n${FTPDIR}\n\n"
echo -ne "DELETEFILES:\n${DELETEFILES}\n\n"
echo -ne "MISSINGFILES:\n${MISSINGFILES}\n\n"
