#!/usr/bin/env bash
#
# reference: https://github.com/panubo/docker-sshd/blob/master/entry.sh


echo "----------------------------------------------------"
echo "DOCKER_USER: ${DOCKER_USER}"
echo "DOCKER_USER_GROUP: ${DOCKER_USER_GROUP}"
echo "USER_HOME: ${USER_HOME}"
echo "----------------------------------------------------"
cat /run/secrets/id_rsa > ${USER_HOME}/.ssh/authorized_keys
cat /run/secrets/id_rsa > /etc/authorized_keys/${SSH_USERS}
chown ${DOCKER_USER} ${USER_HOME}/.ssh
chmod 700 ${USER_HOME}/.ssh
chown ${DOCKER_USER} ${USER_HOME}/.ssh/authorized_keys
chmod 600 ${USER_HOME}/.ssh/authorized_keys

# Allow User to run docker containers
chown ${DOCKER_USER}:${DOCKER_USER_GROUP} /var/run/docker.sock 

# for AWS credentials
chown ${DOCKER_USER}:${DOCKER_USER_GROUP} /home/${DOCKER_USER}/.aws/*

set -e

[ "$DEBUG" == 'true' ] && set -x

DAEMON=sshd

echo "> Starting SSHD"

# Copy default config from cache, if required
if [ ! "$(ls -A /etc/ssh)" ]; then
    cp -a /etc/ssh.cache/* /etc/ssh/
fi

set_hostkeys() {
    echo ">>> Setting hostkeys"
    printf '%s\n' \
        'set /files/etc/ssh/sshd_config/HostKey[1] /etc/ssh/keys/ssh_host_rsa_key' \
        'set /files/etc/ssh/sshd_config/HostKey[2] /etc/ssh/keys/ssh_host_dsa_key' \
        'set /files/etc/ssh/sshd_config/HostKey[3] /etc/ssh/keys/ssh_host_ecdsa_key' \
        'set /files/etc/ssh/sshd_config/HostKey[4] /etc/ssh/keys/ssh_host_ed25519_key' \
    | augtool -s 1> /dev/null
    echo ">>> Done"
}

print_fingerprints() {
    local BASE_DIR=${1-'/etc/ssh'}
    for item in dsa rsa ecdsa ed25519; do
        echo ">>> Fingerprints for ${item} host key"
        ssh-keygen -E md5 -lf ${BASE_DIR}/ssh_host_${item}_key
        ssh-keygen -E sha256 -lf ${BASE_DIR}/ssh_host_${item}_key
        ssh-keygen -E sha512 -lf ${BASE_DIR}/ssh_host_${item}_key
    done
}

check_authorized_key_ownership() {
    local file="$1"
    local _uid="$2"
    local _gid="$3"
    local uid_found="$(stat -c %u ${file})"
    local gid_found="$(stat -c %g ${file})"

    if ! ( [[ ( "$uid_found" == "$_uid" ) && ( "$gid_found" == "$_gid" ) ]] || [[ ( "$uid_found" == "0" ) && ( "$gid_found" == "0" ) ]] ); then
        echo "WARNING: Incorrect ownership for ${file}. Expected uid/gid: ${_uid}/${_gid}, found uid/gid: ${uid_found}/${gid_found}. File uid/gid must match SSH_USERS or be root owned."
    fi
}

# Generate Host keys, if required
# if ls /etc/ssh/keys/ssh_host_* 1> /dev/null 2>&1; then
#     echo ">> Found host keys in keys directory"
#     set_hostkeys
#     print_fingerprints /etc/ssh/keys
# elif ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
#     echo ">> Found Host keys in default location"
#     # Don't do anything
#     print_fingerprints
# else
    echo ">> Generating new host keys"
    mkdir -p /etc/ssh/keys
    ssh-keygen -A
    mv /etc/ssh/ssh_host_* /etc/ssh/keys/
    set_hostkeys
    print_fingerprints /etc/ssh/keys
# fi

# Fix permissions, if writable.
# NB ownership of /etc/authorized_keys are not changed
if [ -w ~/.ssh ]; then
    chown root:root ~/.ssh && chmod 700 ~/.ssh/
fi
if [ -w ~/.ssh/authorized_keys ]; then
    chown root:root ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi
if [ -w /etc/authorized_keys ]; then
    chown root:root /etc/authorized_keys
    chmod 755 /etc/authorized_keys
    # test for writability before attempting chmod
    for f in $(find /etc/authorized_keys/ -type f -maxdepth 1); do
        [ -w "${f}" ] && chmod 644 "${f}"
    done
fi

# Unlock root account, if enabled
if [[ "${SSH_ENABLE_ROOT}" == "true" ]]; then
    echo ">> Unlocking root account"
    usermod -p '' root
else
    echo "INFO: root account is now locked by default. Set SSH_ENABLE_ROOT to unlock the account."
fi

# Update MOTD
if [ -v MOTD ]; then
    echo -e "$MOTD" > /etc/motd
fi

# PasswordAuthentication (disabled by default)
if [[ "${SSH_ENABLE_PASSWORD_AUTH}" == "true" ]]; then
    echo 'set /files/etc/ssh/sshd_config/PasswordAuthentication yes' | augtool -s 1> /dev/null
    echo "WARNING: password authentication enabled."
else
    echo 'set /files/etc/ssh/sshd_config/PasswordAuthentication no' | augtool -s 1> /dev/null
    echo "INFO: password authentication is disabled by default. Set SSH_ENABLE_PASSWORD_AUTH=true to enable."
fi

configure_ssh_options() {
    # Enable AllowTcpForwarding
    if [[ "${TCP_FORWARDING}" == "true" ]]; then
        echo 'set /files/etc/ssh/sshd_config/AllowTcpForwarding yes' | augtool -s 1> /dev/null
    fi
    # Enable GatewayPorts
    if [[ "${GATEWAY_PORTS}" == "true" ]]; then
        echo 'set /files/etc/ssh/sshd_config/GatewayPorts yes' | augtool -s 1> /dev/null
    fi
    # Disable SFTP
    if [[ "${DISABLE_SFTP}" == "true" ]]; then
        printf '%s\n' \
            'rm /files/etc/ssh/sshd_config/Subsystem/sftp' \
            'rm /files/etc/ssh/sshd_config/Subsystem' \
        | augtool -s 1> /dev/null
    fi
}

##################################################
configure_ssh_options
/usr/sbin/sshd -D &
##################################################


# Run scripts in /etc/entrypoint.d
for f in /etc/entrypoint.d/*; do
    if [[ -x ${f} ]]; then
        echo ">> Running: ${f}"
        ${f}
    fi
done

stop() {
    echo "Received SIGINT or SIGTERM. Shutting down $DAEMON"
    # Get PID
    local pid=$(cat /var/run/$DAEMON/$DAEMON.pid)
    # Set TERM
    kill -SIGTERM "${pid}"
    # Wait for exit
    wait "${pid}"
    # All done.
    echo "Done."
}

echo "Running $@"
if [ "$(basename $1)" == "$DAEMON" ]; then
    trap stop SIGINT SIGTERM
    $@ &
    pid="$!"
    mkdir -p /var/run/$DAEMON && echo "${pid}" > /var/run/$DAEMON/$DAEMON.pid
    wait "${pid}"
    exit $?
else
    exec "$@"
fi