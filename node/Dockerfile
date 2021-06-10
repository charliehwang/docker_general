FROM debian:sid-slim

ARG NODE_VARIANT

ARG DOCKER_USER
ARG DOCKER_USER_GROUP
ARG USER_HOME=/home/${DOCKER_USER}
ENV USER_GROUP=${DOCKER_USER_GROUP}

ENV DOCKER_USER ${DOCKER_USER}
ENV DOCKER_USER_GROUP ${DOCKER_USER_GROUP}
ENV USER_HOME=${USER_HOME}
ENV SSH_USERS=${DOCKER_USER}

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

# ESLint
RUN npm install -g eslint

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

# AWS SAM CLI
# curl -L follows the github redirect
RUN curl -L "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip" -o "aws-sam-cli.zip"
RUN unzip aws-sam-cli.zip  -d aws-sam-cli
RUN ./aws-sam-cli/install
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
RUN echo "DOCKER_USER: $DOCKER_USER"
RUN echo "DOCKER_USER_GROUP: $DOCKER_USER_GROUP"
RUN echo "USER_HOME: $USER_HOME"
RUN echo "SSH_USERS: $SSH_USERS"
RUN echo "====================================="

# RUN addgroup --group ${USER_GROUP} && adduser --group ${USER_GROUP} --shell /bin/bash ${USER}
RUN addgroup --group ${DOCKER_USER_GROUP} 
RUN useradd -rm -d ${USER_HOME} -s /bin/bash -g ${DOCKER_USER_GROUP} -G sudo -u 1001 ${DOCKER_USER}
RUN mkdir -p $USER_HOME/.ssh
RUN mkdir -p /var/run/sshd
# RUN echo 'admin:ttyrqttyrq' | chpasswd

###########################################
# RUN as USER then go back to ROOT
USER ${DOCKER_USER}
RUN git config --global user.email "${GIT_USER_EMAIL}"
RUN git config --global user.name "${GIT_USER_NAME}"

# for AWS
RUN mkdir -p /home/${DOCKER_USER}/.aws 
RUN chown ${DOCKER_USER}:${DOCKER_USER_GROUP} /home/${DOCKER_USER}/.aws 

USER root
###########################################


COPY ssh_entry.sh /ssh_entry.sh
RUN chmod +x /ssh_entry.sh
ENTRYPOINT ["/ssh_entry.sh"]
