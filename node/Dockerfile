ARG NODEJS_VARIANT

FROM node:${NODEJS_VARIANT} as base

ARG USER
ARG USER_GROUP
ARG USER_HOME=/home/${USER}

ENV USER_HOME=${USER_HOME}
ENV SSH_USERS=${USER}
ENV USER_GROUP=${USER_GROUP}

RUN apk add --update --no-cache \
						bash augeas shadow \
						openssh-server \
						&& rm -rf /var/cache/apk/*

RUN deluser $(getent passwd 33 | cut -d: -f1) && \
    delgroup $(getent group 33 | cut -d: -f1) 2>/dev/null || true && \
    mkdir -p ~root/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ && \
    mkdir -p ~/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ && \
		augtool 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%u"' && \
    echo -e "Port 22\n" >> /etc/ssh/sshd_config && \
		# sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \ 
    cp -a /etc/ssh /etc/ssh.cache




# RUN systemctl enable sshd
# RUN sed -i 's/#Port.*$/Port 2022/' /etc/ssh/sshd_config && chmod 775 /var/run && rm -f /var/run/nologin
# RUN chmod 775 /var/run && rm -f /var/run/nologin
# RUN mkdir /etc/systemd/system/sshd.service.d/ && echo -e '[Service]\nRestart=always' > /etc/systemd/system/sshd.service.d/sshd.conf
# RUN ["/bin/echo", "USER===> ", ${USER}]
RUN echo "====================================="
RUN echo "USER: $USER"
RUN echo "USER_GROUP: $USER_GROUP"
RUN echo "USER_HOME: $USER_HOME"
RUN echo "SSH_USERS: $SSH_USERS"
RUN echo "SSH_PUB_KEY: $SSH_PUB_KEY"
RUN echo "====================================="
# CMD ["sh", "-c", "echo $USER"]

RUN addgroup -S ${USER_GROUP} && adduser -S ${USER} -G ${USER_GROUP} --shell /bin/bash
RUN mkdir -p $USER_HOME/.ssh
RUN echo 'admin:ttyrqttyrq' | chpasswd
# RUN cat /run/secrets/id_rsa > $USER_HOME/.ssh/authorized_keys
# RUN ln -sf /run/secrets/id_rsa $USER_HOME/.ssh/authorized_keys
# RUN chmod 700 $HOME/.ssh/authorized_keys
# RUN chown $USER_GROUP $HOME/.ssh/authorized_keys
# RUN chmod 600 $HOME/.ssh/authorized_keys

COPY ssh_entry.sh /ssh_entry.sh
RUN chmod +x /ssh_entry.sh
ENTRYPOINT ["/ssh_entry.sh"]

# CMD ["/usr/sbin/sshd", "-D", "-vvv", "-e", "-f", "/etc/ssh/sshd_config"]

# Create a group and user
# RUN addgroup -S dev && adduser -S dev -Gdev 

# USER admin 
# WORKDIR /home/admin/

# WORKDIR /
# COPY package*.json /