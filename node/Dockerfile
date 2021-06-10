FROM debian:sid-slim

ARG NODE_VARIANT

ARG USER
ARG USER_GROUP
ARG USER_HOME=/home/${USER}

ENV USER_HOME=${USER_HOME}
ENV SSH_USERS=${USER}
ENV USER_GROUP=${USER_GROUP}

ARG GIT_USER_EMAIL
ARG GIT_USER_NAME

RUN apt-get update && apt-get install -y \
						curl bash augeas-tools git iputils-ping \
            # Gatsby
            dh-autoreconf \ 
						openssh-server \ 
            # Angular
            watchman  \
            # AWS
            zip


RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VARIANT} | bash -
RUN apt-get install -y nodejs
RUN npm install --global yarn

# Gatsby
RUN npm i -g gatsby-cli

# TypeScript
RUN npm install -g typescript

# Angular
RUN npm install -g @angular/cli

################ AWS ###################
# AWS Command Line
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
# AWS Cloud Development Kit
# RUN npm install -g @aws-cdk/aws-s3@1.31.0
RUN npm install -g aws-cdk
########################################

RUN deluser $(getent passwd 33 | cut -d: -f1) && \
    delgroup $(getent group 33 | cut -d: -f1) 2>/dev/null || true && \
    mkdir -p ~root/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ && \
    mkdir -p ~/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ && \
		augtool 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%u"' && \
    echo "Port 22\n" >> /etc/ssh/sshd_config && \
		# sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \ 
    cp -a /etc/ssh /etc/ssh.cache

RUN echo "====================================="
RUN echo "USER: $USER"
RUN echo "USER_GROUP: $USER_GROUP"
RUN echo "USER_HOME: $USER_HOME"
RUN echo "SSH_USERS: $SSH_USERS"
RUN echo "====================================="

# RUN addgroup --group ${USER_GROUP} && adduser --group ${USER_GROUP} --shell /bin/bash ${USER}
RUN addgroup --group ${USER_GROUP} 
RUN useradd -rm -d ${USER_HOME} -s /bin/bash -g ${USER_GROUP} -G sudo -u 1001 ${USER}
RUN mkdir -p $USER_HOME/.ssh
RUN mkdir -p /var/run/sshd
# RUN echo 'admin:ttyrqttyrq' | chpasswd

###########################################
# RUN as USER then go back to ROOT
USER ${USER}
RUN git config --global user.email "${GIT_USER_EMAIL}"
RUN git config --global user.name "${GIT_USER_NAME}"
USER root
###########################################


COPY ssh_entry.sh /ssh_entry.sh
RUN chmod +x /ssh_entry.sh
ENTRYPOINT ["/ssh_entry.sh"]
