#!/bin/bash
# File: 522-dns-bind9-config-reset.sh
# Title:  Restart Bind9 configuration from scratch
# Description:
#   Builds out the basic framework of named.conf via include files
#
#   All within the /etc/bind[/instance] directory
#
#   /named.conf
#     + acls-named.conf
#       - acl-public-outward-dynamic-interface-named.conf (if dynamic public IP)
#       - acl-public-bastion-interior-interface-named.conf  (bastion-only)
#       - acl-internal-bastion-interior-interface-named.conf  (bastion-only)
#       - acl-internal-outward-interface-named.conf
#     + controls-named.conf
#     + keys-named.conf
#       - key-primary-to-secondaries-transfer.conf
#       - key-primary-dynamic-ip-ddns-ddclient.conf
#       - key-hidden-master-to-public-master.conf
#     + logging-named.conf
#     + managed-keys-named.conf
#     + options-named.conf
#       - options-public-facing-dynamic-interfaces-named.conf (if dynamic IP)
#       - options-bastion-named.conf
#     + primaries-named.conf
#     + servers-named.conf
#     + statistics-named.conf
#     + trust-anchors-named.conf
#     + views-named.conf
#       - view-zone-clauses-named.conf
#         - zone-example.invalid-named.conf
#         - zone-example.org-named.conf
#         - zone-example.net-named.conf
#     + zones-named.conf (if no view clause)
#       - zone-example.invalid-named.conf (if no view clause)
#       - zone-example.org-named.conf (if no view clause)
#       - zone-example.net-named.conf (if no view clause)
#
# Prerequisites:
#
# Env varnames
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - INSTANCE  - Bind9 instance name, if any
#

[ $((${DEBUG:-0} & 0x01)) -eq 1 ] && ( set -o posix; set ) > /tmp/variables.before

echo "Resetting build area to empty."
echo

#BUILDROOT="${BUILDROOT:-build}"
echo "Purging DNS Build from $BUILDROOT ..."
echo

source ./maintainer-dns-isc.sh

echo "Clearing out prior settings in $BUILDROOT"

# Absolute path for build?
if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "BUILDROOT: $BUILDROOT"
  FILE_SETTING_PERFORM=true
else
  FILE_SETTING_PERFORM=false
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-named${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.conf"
  rm -rf "$BUILDROOT"
  mkdir -v "$BUILDROOT"  # no flex_mkdir, this is an intermediate-build tmp directory
  mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$ETC_SYSTEMD_SYSTEM_DIRSPEC"
  mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_ETC_NAMED_DIRSPEC"
  mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
  mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
fi
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_KEY_DIRSPEC"
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_LOG_DIRSPEC"
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_KEYS_DB_DIRSPEC"
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_DYNAMIC_DIRSPEC"
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_PRIMARY_DIRSPEC"
mkdir -v -p "${BUILDROOT}${CHROOT_DIR}$INSTANCE_SECONDARY_DIRSPEC"
for d in "${ZONE_DB_DIRNAME[@]}"
do
  mkdir -v -p "${BUILDROOT}${CHROOT_DIR}${INSTANCE_ZONE_DB_DIRSPEC}/$d"
  flex_ckdir "${INSTANCE_ZONE_DB_DIRSPEC}/$d"
  flex_chown bind:bind "${INSTANCE_ZONE_DB_DIRSPEC}/$d"
  flex_chmod 00750      "${INSTANCE_ZONE_DB_DIRSPEC}/$d"
done

# /etc/bind
flex_ckdir "$ETC_NAMED_DIRSPEC"
flex_chown bind:bind "$ETC_NAMED_DIRSPEC"
flex_chmod 00750      "$ETC_NAMED_DIRSPEC"

# /etc/bind/instance
flex_ckdir "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_chown bind:bind "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_chmod 0750      "$INSTANCE_ETC_NAMED_DIRSPEC"

# /etc/bind/keys
flex_ckdir "$RNDC_KEY_DIRSPEC"
flex_chown bind:bind "$RNDC_KEY_DIRSPEC"
flex_chmod 00750      "$RNDC_KEY_DIRSPEC"

# /etc/bind/[instance]/keys
flex_ckdir "$INSTANCE_RNDC_KEY_DIRSPEC"
flex_chown bind:bind "$INSTANCE_RNDC_KEY_DIRSPEC"
flex_chmod 00750      "$INSTANCE_RNDC_KEY_DIRSPEC"

# /var/cache/bind
flex_ckdir "$VAR_CACHE_NAMED_DIRSPEC"
flex_chown bind:bind "$VAR_CACHE_NAMED_DIRSPEC"
flex_chmod 0750      "$VAR_CACHE_NAMED_DIRSPEC"

# /var/cache/bind/[instance]
flex_ckdir "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
flex_chown bind:bind "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
flex_chmod 0750      "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"

# /var/lib/bind
flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"
flex_chown bind:bind "$VAR_LIB_NAMED_DIRSPEC"
flex_chmod 0750      "$VAR_LIB_NAMED_DIRSPEC"

# /var/lib/bind/[instance]
flex_ckdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
flex_chown bind:bind "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
flex_chmod 0750      "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"

# /var/lib/bind/dynamic
flex_ckdir "$DEFAULT_DYNAMIC_DIRSPEC"
flex_chown bind:bind "$DEFAULT_DYNAMIC_DIRSPEC"
flex_chmod 0750      "$DEFAULT_DYNAMIC_DIRSPEC"

# /var/lib/bind/[instance]/dynamic
flex_ckdir "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chown bind:bind "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chmod 0750      "$INSTANCE_DYNAMIC_DIRSPEC"

# /var/log/named
flex_ckdir "$LOG_DIRSPEC"
flex_chown bind:bind "$LOG_DIRSPEC"
flex_chmod 0750      "$LOG_DIRSPEC"

# /var/log/named/[instance]
flex_ckdir "$INSTANCE_LOG_DIRSPEC"
flex_chown bind:bind "$INSTANCE_LOG_DIRSPEC"
flex_chmod 0750      "$INSTANCE_LOG_DIRSPEC"

# logrotate
# apparmor
# firewall

echo "Creating ${BUILDROOT}${CHROOT_DIR}$INSTANCE_NAMED_CONF_FILESPEC ..."
cat << NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$INSTANCE_NAMED_CONF_FILESPEC" > /dev/null
#
# File: $(basename "$INSTANCE_NAMED_CONF_FILESPEC")
# Path: $(dirname "$INSTANCE_NAMED_CONF_FILESPEC")
# Title: Main named.conf configuration file for ISC Bind9 name server
# Instance: ${INSTANCE}
# Generator: $(basename "$0")
# Created on: $(date)
#

include "${INSTANCE_ACL_NAMED_CONF_FILESPEC}";
include "${INSTANCE_CONTROLS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_KEY_NAMED_CONF_FILESPEC}";
include "${INSTANCE_LOGGING_NAMED_CONF_FILESPEC}";
include "${INSTANCE_OPTIONS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_PRIMARY_NAMED_CONF_FILESPEC}";
include "${INSTANCE_SERVER_NAMED_CONF_FILESPEC}";
include "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}";
include "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}";

NAMED_CONF_EOF
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_NAMED_CONF_FILESPEC"
flex_chmod 0640 "$INSTANCE_NAMED_CONF_FILESPEC"

# /etc/bind/acls-named.conf
create_header "${INSTANCE_ACL_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'acl' clauses"

# /etc/bind/controls-named.conf
create_header "$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'controls' clauses"

# /etc/bind/keys-named.conf
create_header "${INSTANCE_KEY_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'key' clauses"

# /etc/bind/logging-named.conf
create_header "$INSTANCE_LOGGING_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'logging' clauses"

# /etc/bind/managed-keys-named.conf
# deprecated in favor of 'trusted-anchors' with the 'initial-key' keyword
#create_header "${INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC}" \
#    "${USER_NAME}:$GROUP_NAME" 0640 "'managed-keys' clause"

# /etc/bind/options-named.conf
create_header "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'options' clauses"

cat << OPTIONS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" > /dev/null
options {
    directory "${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}";
    pid-file "${INSTANCE_PID_FILESPEC}";

    version "Wolfe DNS, eh?";
    server-id none;

# move to authoritative/forwarding
#    recursion no;
# default 60m not needed, set to 0 if need be
#    interface-interval 120;

    managed-keys-directory "${MANAGED_KEYS_DIRSPEC}";
    dump-file "${DUMP_CACHE_FILESPEC}";

    max-rsa-exponent-size 4096;
    session-keyalg "hmac-sha256"; // could use hmac-sha512
    session-keyfile "${SESSION_KEYFILE_DIRSPEC}/session.key";
    session-keyname "${DHCP_TO_BIND_KEYNAME}";
    statistics-file "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";

    // RNDC ACL
# I use rndc
#    allow-new-zones no;

# default
#    // conform to RFC1035
#    auth-nxdomain no;

# move to recursive, need to research if current appropriate settings have changed
#    disable-algorithms "." {
#        RSAMD5;   // 1
#        DH;       // 2 - current standard
#        DSA;      // DSA/SHA1
#        4;        // reserved
#        RSASHA1;  // RSA/SHA-1
#        6;        // DSA-NSEC3-SHA1
#        7;        // RSASHA1-NSEC3-SHA1
#        //        // RSASHA256;  // 8 - current standard
#        9;        // reserved
#        //        // RSASHA512;  // 10 - ideal standard
#        11;       // reserved
#        12;       // ECC-GOST; // GOST-R-34.10-2001
#        //        // ECDSAP256SHA256; // 13 - best standard
#        //        // ECDSAP384SHA384; // 14 - bestest standard
#        //        // ED25519; // 15
#        //        // ED448; // 16
#        INDIRECT;
#        PRIVATEDNS;
#        PRIVATEOID;
#        255;
#            };
#    //  Delegation Signer Digest Algorithms [DNSKEY-IANA] [RFC7344]
#    //  https://tools.ietf.org/id/draft-ietf-dnsop-algorithm-update-01.html
#    disable-ds-digests "egbert.net" {
#        0;        // 0
#        SHA-1;    // 1 - Must deprecate
#        //        // SHA-256; // Widespread use
#        GOST;     // 3 - has been deprecated by RFC6986
#        //        // SHA-384;  // 4 - Recommended
#        };
#    // disables the SHA-256 digest for .net TLD only.
#    disable-ds-digests "net" { "SHA-256"; };  // TBS: temporary

# default
#    dnssec-accept-expired no;
#    dnssec-enable yes;
#    dnssec-validation yes;
#    transfer-format many-answers;
# move to server type
#    allow-query { none; };
#    allow-transfer { none; };
#    allow-update { none; };  # we edit zone file by using an editor, not 'rndc'
#    allow-notify { none; };
#    forwarders { };

    key-directory "${INSTANCE_KEYS_DB_DIRSPEC}";
    max-transfer-time-in 60;
    notify no;
    zone-statistics yes;

    # https://dnsflagday.net/2020/#action-dns-resolver-operators
    edns-udp-size 1232;
    max-udp-size 1232;

    include "${INSTANCE_OPTIONS_EXT_NAMED_CONF_FILESPEC}";
};
OPTIONS_EOF

# /etc/bind/options-ext-named.conf
create_header "${INSTANCE_OPTIONS_EXT_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'extensions to options' clauses"

# /etc/bind/primaries-named.conf
create_header "${INSTANCE_PRIMARY_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'primaries' clauses"

# /etc/bind/servers-named.conf
create_header "${INSTANCE_SERVER_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'server' clauses"

# /etc/bind/stats-named.conf
create_header "${INSTANCE_STATS_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'statistics channel' clauses"

# /etc/bind/trust-anchors-named.conf
create_header "${INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'trust anchors' clauses"

# including default bind keys in config
cat << TRUSTED_ANCHORS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC" > /dev/null
trust-anchors {
        # This key (20326) was published in the root zone in 2017.
        . initial-key 257 3 8 "AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3
                +/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4+B5xQlNVz8Og8kv
                ArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF
                0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da+sqqls3eNbuv7pr+e
                oZG+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfd
                RUfhHdY6+cn8HFRm+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwN
                R1AkUTV74bU=";
};

TRUSTED_ANCHORS_EOF

# /etc/bind/views-named.conf
create_header "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'view' clauses"

# /etc/bind/zones-named.conf
create_header "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'zone' clauses"

if [ 0 -ne 0 ]; then
# TODO: MOVE THIS BLOCK TO A SEPARATE SCRIPT FILE
# TODO: Do 'listen-on' in a separate script file
# TODO: Do 'bastion' in a separate script file

# /etc/bind/options-bastion-named.conf
create_header "$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'options-bastion' clause"
append_include_clause \
  "$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC" \
    "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC"

# /etc/bind/options-listen-on-named.conf
create_header "$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'options-listen-on' clause"
append_include_clause \
  "$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC" \
    "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC"
fi

if [ -n "$INSTANCE" ]; then
  # Create the /etc/default/[named|bind]/instance file
  echo
  FILENAME="$INSTANCE_INIT_DEFAULT_FILENAME"
  FILEPATH="$INIT_DEFAULT_DIRSPEC"
  FILESPEC="$INSTANCE_INIT_DEFAULT_FILESPEC"
  flex_ckdir "$INIT_DEFAULT_DIRSPEC"

  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
  cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: SysV init.rc startup setting for "$INSTANCE"-specific instance
# Creator: $(basename "$0")
# Created on: $(date)
#
#   NAMED_CONF - Full filepath specification to 'named.conf'
#
#   NAMED_OPTIONS - passthru CLI options for 'named' daemon
#                    cannot use -c option (use NAMED_PORT)
#
#   RNDC_OPTIONS - passthru CLI options for 'rndc' utility
#                    cannot use -p option (edit rndc.conf instead)
#
#   RESOLVCONF - Do a one-shot resolv.conf setup. 'yes' or 'no'
#           Only used in SysV/s6/OpenRC/ConMan; Ignored by systemd.
#
# default settings for startup options  of '$systemd_unitname'
# is located in ${ETC_SYSTEMD_SYSTEM_DIRSPEC}/${INSTANCE_SYSTEMD_NAMED_SERVICE}
# and its defaults are:
#
#   NAMED_CONF="${INSTANCE_NAMED_CONF_FILESPEC}"
#   NAMED_OPTIONS="-c ${INSTANCE_NAMED_CONF_FILESPEC}"
#   RNDC_OPTIONS="-c ${INSTANCE_RNDC_CONF_FILESPEC}"
#


# the "rndc.conf" should have all its server, key, port, and IP address defined
RNDC_OPTIONS="-c ${INSTANCE_RNDC_CONF_FILESPEC}"

NAMED_CONF="${INSTANCE_NAMED_CONF_FILESPEC}"

# Do not use '-f' or '-g' option in NAMED_OPTIONS
# systemd 'Type=simple' hardcoded this '-f'
### NAMED_OPTIONS="-L/tmp/mydns.out -c ${INSTANCE_NAMED_CONF_FILESPEC}"
### NAMED_OPTIONS="-4 -c ${INSTANCE_NAMED_CONF_FILESPEC}"
NAMED_OPTIONS="-c ${INSTANCE_NAMED_CONF_FILESPEC}"

# There may be other settings in a unit-instance-specific default
# file such as /etc/default/named-public.conf or
# /etc/default/bind9-dmz.conf.

# run resolvconf?  (legacy sysV initrd)
RESOLVCONF=no

BIND_EOF
  flex_chown "root:root" "$FILESPEC"
  flex_chmod "0644"      "$FILESPEC"
  echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"


echo "Creating a temporary directory under '/run' for ISC Bind 'named'"
echo

ETC_TMPFILESD_DIRSPEC="/etc/tmpfiles.d"

FILENAME="${systemd_unitname}.conf"
FILESPEC=${ETC_TMPFILESD_DIRSPEC}/${FILENAME}
echo "Modifying ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
d  /run/named/${INSTANCE}  0750   ${USER_NAME}     ${GROUP_NAME}     -   -
BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"

if [ "$FILE_SETTING_PERFORM" == "true" ] \
   || [ "$UID" -eq 0 ]; then
  echo "Activating $FILESPEC tmpfile subdirectory ..."
  systemd-tmpfiles "$FILESPEC" --create
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error in $FILESPEC tmpdir; errno ${retsts}; aborted."
    exit $retsts
  fi
fi

fi

echo
echo "Done."

[ $((${DEBUG:-0} & 0x01)) -eq 1 ] && ( set -o posix; set ) > /tmp/variables.after
