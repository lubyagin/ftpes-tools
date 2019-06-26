#!/bin/bash
# Upload file to FTPES-server by /usr/bin/lftp utility
# Started at 2019-05-06 02:26:34 MSK, for Debian 9.*

# .cfg constants:
# USERNAME="..." # passwords in ~/.netrc
# HOSTNAME="..."
# BASEDIR="/MyFQDN/"

SCRIPT=`/usr/bin/realpath "$0"` # or $BASH
SCRIPTDIR=`/usr/bin/dirname "$SCRIPT"`

. "$SCRIPTDIR"/ftpes-upload.cfg

FILE="$1"
if [ ! -r "$FILE" ]; then
  /bin/echo "[ERR] Could not read file "$FILE""
  exit
fi
FILEDIR=`/usr/bin/dirname "$FILE"` # or PWD=`pwd`

REL=`/usr/bin/realpath --relative-to "$SCRIPTDIR" "$FILEDIR"`

# filename = name-ts-cc.sfx, where cc is control code = MD5-SHA512
TS=`/bin/date --utc +"%Y-%m%d-%H%M%S"`
CC1=`/bin/cat "$FILE" | /usr/bin/md5sum | /bin/sed 's/[[:space:]]*\-$//' | colrm 9`
CC2=`/bin/cat "$FILE" | /usr/bin/sha512sum | /bin/sed 's/[[:space:]]*\-$//' | colrm 9`
CC="$CC1-$CC2"
PFX=`/usr/bin/basename "${FILE%.*}"` # prefix without directory
SFX="${FILE##*.}" # suffix i.e. file extension
NAME="$PFX"-"$TS"-"$CC"."$SFX"
NAMEORIG="$PFX"."$SFX"

# supress standard output > /dev/null
/bin/echo "cd "$REL""
/usr/bin/lftp ftp://$USERNAME@$HOSTNAME:"$BASEDIR" > /dev/null \
<< EOF
debug off
mkdir -p -f "$REL"
cd "$REL"
put "$FILE" -o "$NAME"
put "$FILE" -o "$NAMEORIG"
exit
EOF

# get current shell status
if [ $? -eq 0 ]; then
  /bin/echo "[OK] The file "$NAME" has been uploaded successfully"
  /bin/echo "[OK] The file "$NAMEORIG" has been uploaded successfully"
else
  /bin/echo "[ERR] Could not upload file"
fi

: '

~/.lftprc

set ftp:ssl-allow true
set ftp:ssl-force true
set ssl:verify-certificate false

set cache:enable false

set xfer:log false
set cmd:save-cwd-history no
set cmd:save-rl-history no

set net:idle 3
set net:timeout 10
set dns:fatal-timeout 3

~/.netrc

machine ... login ... password

'

