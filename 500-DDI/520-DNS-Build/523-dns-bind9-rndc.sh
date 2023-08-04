#!/bin/bash
# File: 513-dns-bind-rndc-restrict.sh
# Title: Configure 'rndc' security
#
# Description:
#
#   Creates /etc/bind/controls-named.conf  # template
#   Creates /etc/bind/keys-named.conf  # template
#   Creates /etc/bind/controls-rndc-127.0.0.1.conf
#   Creates /etc/bind/rndc.conf (RNDC_CONF_FILESPEC)
#   Creates /etc/bind/keys/rndc.key (RNDC_KEY_FILESPEC)
#     apparmor check
#     SELinux check
#     file permission check
#
#   Restrict RNDC access of related files and netdev access
#   based on its intended usage.
#
#   Three roles of full-admin-privileged usage of 'rndc' tool:
#
#     * system administrator
#     * power end-users using their own copy of an RNDC keyg
#     * auto-evoked by other daemons/scripts
#
# NOTE: named.conf provides ways for end-user/sysadmin to
#       separately update the:
#   * individual zone's data
#   * forwarder assignments
#
# CAVEATS:
#   * Cannot use the same /etc/bind/rndc.conf file for a different
#     (or instantiated) named process.
#     * Because multiple chroots would result in making support for
#       multiple-key (via 'rndc -s server') approach in the
#       rndc.conf option into an non-reality
#       (non-useable/non-sharable).
#     * locking down a key file's file permission to a different
#       user/group ID would render said key file to be unaccessible
#       by another daemon having a different user/group ID.
#     * Cannot use 'include' clause in `rndc.conf` because of aboves.
#       * As a result, 'include' clause utility has diminished somewhat a bit
#   * therefore an instantiated rndc.conf (and its corrresponding key)
#        must reside under and within its own instantiated subdirectory.
#
# Detailed Design:
#
# if just the system administrator(s) alone (no users)
#  For 'rndc' binary, drop file ownership to 'root:bind'
#  For 'rndc' binary, drop world file permissions to '---' (no read/execute)
#  For 'rndc' binary, ensure group file permissions is 'r-x' (read/execute)
#  For 'rndc.key', drop file ownership to 'root:bind'
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  For 'rndc.key', ensure group file permissions is 'r--' (read)
#  introduce 'bind' group enforcement to each applicable system administrator
#    by executing 'usermod -a -G bind <username>'
#
# if got power users to cater (QA auditor/Common-Criteria-enforcer)
#  For 'rndc' binary, ensure file ownership is 'root:root'
#  For 'rndc' binary, ensure world file permissions is 'r-x' (read/execute)
#  For 'rndc' binary, ensure group file permissions is 'r-x' (read/execute)
#  For 'rndc.key', drop file ownership to 'root:bind'
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  For 'rndc.key', ensure group file permissions is 'r--' (read)
#  create a new 'rndc.key' and labeled for each end-user
#  insert 'new labeled rndc.key' into named.conf
#  do not give 'bind' supplemental group to end-user:
#     This keeps zone files ('bind' group) as untouchable
#     but daily operation of 'named' may be altered
#     NOTE: nasty thing is that 'rndc' still can add/delete 'A' records
#
# If auto-evoked by other daemons/scripts (ie. ddclient dynamic IP update)
#  For 'rndc' binary, ensure world file permissions to 'r-x' (read/execute)
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  must duplicate /etc/bind/rndc.key into that daemons config directory
#    instruct that daemons/scripts to use 'rndc -k /etc/daemon/rndc.key' instead
#  drop /etc/daemon/rndc.key to 'root:daemon' 0640 permission
#
# SECURITY-RISK: Allow ANYONE/ANYTHING within ONLY this host to run 'rndc'
#                binary (distro default)
#  For 'rndc' binary, ensure world file permissions to 'r-x' (read/execute)
#  For 'rndc.key', ensure file ownership to 'root:root'
#  For 'rndc.key', ensure world file permissions 'r--' (read)
#

[ "${DEBUG:-0}" = "1" ] && ( set -o posix; set ) > /tmp/variables.before

RNDC_IP4_ADDR="127.0.0.1"
RNDC_IP6_ADDR="::1"

# /etc/bind/controls-rndc-named.conf
CONTROLS_RNDC_LOCALHOST_CONF_FILENAME="controls-rndc-named.conf"

echo "Configure RNDC control channel and its various security settings."
echo



source ./maintainer-dns-isc.sh
# INSTANCE_ETC_NAMED_BIND_DIRSPEC=


if [ "${BUILDROOT:0:1}" == '/' ]; then
  FILE_SETTING_PERFORM=true
  # absolute (rootfs?)
  echo "Absolute build"
else
  FILE_SETTING_PERFORM=false
#  mkdir -p build
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-rndc-security${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  rm -f "$FILE_SETTINGS_FILESPEC"
#  mkdir build/etc
  flex_ckdir "${ETC_NAMED_DIRSPEC}"
  if [ -n "$INSTANCE" ]; then
    flex_ckdir "${INSTANCE_ETC_NAMED_DIRSPEC}"
  fi
  flex_ckdir "${INSTANCE_ETC_NAMED_DIRSPEC}/keys"
fi

#INSTANCE_CONTROLS_RNDC_LOCALHOST_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$CONTROLS_RNDC_LOCALHOST_CONF_FILENAME"
#INSTANCE_CONTROLS_RNDC_READ_LOCALHOST_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$CONTROLS_RNDC_READ_LOCALHOST_CONF_FILENAME"

echo "NOTE: REMOTELY-IP-speaking, named.conf provides a way for"
echo "      a separate end-user and sysadmin to individually update their:"
echo "  * zones database"
echo "  * forwarder assignments"
echo
echo "Have QA, PCIC, PCI-DSS or Common Criteria folks? You should say 'y':"
echo "Keys and TSIGs will never be viewable at world file permission."
#read -rp "Allow anyone within this host to view Bind configuration files? (N/y): " -iN
#REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
#if [ "$REPLY" == 'y' ]; then
# setting to default
  WORLD_READABLE=1
#else
#  WORLD_READABLE=0
#fi

# Setting up instance-specific RNDC configuration and key files
HMAC_ALGORITHM="hmac-sha512"

# /etc/bind/rndc.conf
if [ ! -f "${BUILDROOT}${CHROOT_DIR}${INSTANCE_RNDC_CONF_FILESPEC}" ];
then
  echo "Creating new rndc.conf File."
  create_header "${INSTANCE_RNDC_CONF_FILESPEC}" \
      "${USER_NAME}:$GROUP_NAME" 0640 "RNDC configuration file"


  cat << RNDC_MASTER_CONF | tee -a "${INSTANCE_RNDC_CONF_FILESPEC}" > /dev/null
options {
    default-key "${INSTANCE_RNDC_KEYNAME}";
    default-server 127.0.0.1;
    default-port 953;
    };

# Always hide keys from main config file
RNDC_MASTER_CONF
fi

# Generate RNDC keys
echo "Generating RNDC key ..."
rndc-confgen -a \
        -c "${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_KEY_FILESPEC" \
        -k "$INSTANCE_RNDC_KEYNAME" \
        -A "$HMAC_ALGORITHM"
flex_chmod 0640 "$INSTANCE_RNDC_KEY_FILESPEC"
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_RNDC_KEY_FILESPEC"
echo "Created ${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_KEY_FILESPEC"

echo "Generating RNDC read-only key ..."
rndc-confgen -a \
        -c "${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_READ_KEY_FILESPEC" \
        -k "$INSTANCE_RNDC_READ_KEYNAME" \
        -A "$HMAC_ALGORITHM"
flex_chmod 0640 "$INSTANCE_RNDC_READ_KEY_FILESPEC"
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_RNDC_READ_KEY_FILESPEC"
echo "Created ${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_READ_KEY_FILESPEC"

append_include_clause \
  "${INSTANCE_RNDC_KEY_FILESPEC}" \
    "${INSTANCE_KEY_NAMED_CONF_FILESPEC}"
append_include_clause \
  "${INSTANCE_RNDC_READ_KEY_FILESPEC}" \
    "${INSTANCE_KEY_NAMED_CONF_FILESPEC}"

RNDC_DEFAULT_NAME="${INSTANCE:-default}"
unique_add_line \
  "server ${RNDC_DEFAULT_NAME} { key ${INSTANCE_RNDC_KEYNAME};  addresses { ${RNDC_IP4_ADDR} port 953; }; };" \
    "${INSTANCE_RNDC_CONF_FILESPEC}"
unique_add_line \
  "server ${RNDC_DEFAULT_NAME}-ro { key ${INSTANCE_RNDC_READ_KEYNAME};  addresses { ${RNDC_IP4_ADDR} port 954; }; };" \
    "${INSTANCE_RNDC_CONF_FILESPEC}"
append_include_clause \
  "${INSTANCE_RNDC_KEY_FILESPEC}" \
    "${INSTANCE_RNDC_CONF_FILESPEC}"
append_include_clause \
  "${INSTANCE_RNDC_READ_KEY_FILESPEC}" \
    "${INSTANCE_RNDC_CONF_FILESPEC}"

filename="$CONTROLS_NAMED_CONF_FILENAME"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NAMED_KEY_CONF | tee -a "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
controls {
    inet ${RNDC_IP4_ADDR} port ${RNDC_PORT} allow {
        ${RNDC_IP4_ADDR}/32;
            } keys {
            "${INSTANCE_RNDC_KEYNAME}";
            };
    inet ${RNDC_IP6_ADDR} port ${RNDC_PORT} allow {
        ::1;
            } keys {
            "${INSTANCE_RNDC_KEYNAME}";
            };
    inet ${RNDC_IP4_ADDR} port 954 allow {
        ${RNDC_IP4_ADDR}/32;
            } keys {
            "${INSTANCE_RNDC_READ_KEYNAME}";
            } read-only true;
    inet ${RNDC_IP6_ADDR} port 954 allow {
        ::1;
            } keys {
            "${INSTANCE_RNDC_READ_KEYNAME}";
            } read-only true;
    };

NAMED_KEY_CONF

flex_chmod 0640 "$filespec"
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"

#append_include_clause \
#  "${INSTANCE_CONTROLS_RNDC_LOCALHOST_CONF_FILESPEC}" \
#    "${BUILDROOT}${CHROOT_DIR}$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC"

# /etc/bind/controls-named.conf
#echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
#cat << CONTROLS_CONF_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC" > /dev/null
#include "${INSTANCE_CONTROLS_RNDC_LOCALHOST_CONF_FILESPEC}";
#CONTROLS_CONF_EOF


######################### not cleaned up yet ################################

if [ "$WORLD_READABLE" -eq 1 ]; then
  flex_chmod go+rx-w "$INSTANCE_ETC_NAMED_DIRSPEC"
  flex_chown ${USER_NAME}:${GROUP_NAME} "$INSTANCE_ETC_NAMED_DIRSPEC"

  flex_chmod go+r-wx "$INSTANCE_RNDC_CONF_FILESPEC"
  flex_chown ${USER_NAME}:${GROUP_NAME} "$INSTANCE_RNDC_CONF_DIRSPEC"

  flex_chmod go+r-wx "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
  flex_chown ${USER_NAME}:${GROUP_NAME} "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
  # file-ownership are set by other logics
  # need to chase 'include' statements within named.conf here
  # problem is that in build/, there is no named.conf
else
  flex_chmod o-rwx "$INSTANCE_ETC_NAMED_DIRSPEC"
  flex_chmod o-rwx "$INSTANCE_RNDC_CONF_FILESPEC"
  flex_chmod o-rwx "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
fi

if [ $UID -ne 0 ]; then
  echo "NOTE: Unable to perform syntax-checking this in here."
  echo "      named-checkconf needs CAP_SYS_CHROOT capability in non-root $USER"
  echo "      ISC Bind9 Issue #3119"
  echo "You can execute:"
  echo "  $named_checkconf_filespec -p -x $named_chroot_opt $INSTANCE_NAMED_CONF_FILESPEC"
  read -rp "Do you want to sudo the previous command? (Y/n): " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
fi
if [ "$REPLY" != 'n' ]; then
  # Check syntax of named.conf file
  named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"

# shellcheck disable=SC2086
  sudo $named_checkconf_filespec \
    $named_chroot_opt \
    "$INSTANCE_NAMED_CONF_FILESPEC"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
# shellcheck disable=SC2086
    sudo $named_checkconf_filespec \
      "$named_chroot_opt" \
      "$INSTANCE_NAMED_CONF_FILESPEC"
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    retsts=$?
  fi
  if [ $retsts -ne 0 ]; then
    exit $retsts
  else
    echo "Syntax-check passed for ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_NAMED_CONF_FILESPEC"
  fi
fi
echo

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Restarting $SYSTEMD_NAMED_SERVICE service using 'systemctl restart'..."
  systemctl restart "$INSTANCE_SYSTEMD_NAMED_SERVICE"
  retsts=$?
  sleep 2
  echo "Checking RNDC control connection ..."
  rndc -c "$INSTANCE_RNDC_CONF_FILESPEC" status
  retsts=$?
else
  echo "Execute the following:"
  echo "  systemctl restart $INSTANCE_SYSTEMD_NAMED_SERVICE"
  echo "  rndc -c $INSTANCE_RNDC_CONF_FILESPEC status"
fi
echo


[ "${DEBUG:-0}" = "1" ] && ( set -o posix; set ) > /tmp/variables.after

echo "Done."
