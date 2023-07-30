FROM ubuntu:focal AS riscv_docs_generate

ARG TZ=UTC
ARG DOCKER_USER_UID=1000
ARG NODE_VERSION=14.18.0
ARG NVM_VERSION=v0.38.0

ENV APT_OPTS="-o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false"

RUN DEBIAN_FRONTEND="noninteractive" \
    apt-get ${APT_OPTS} update &&  \
    apt-get ${APT_OPTS} -y install tzdata

RUN apt-get ${APT_OPTS} update

# Basic Unix tools
RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
            make \
            git \
            curl \
            wget \
            sudo 

# Scripting languages
RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
            ruby \
            ruby-dev \
            gem  \
            perl \
            python2 \
            python-is-python3 \
            python3-pip \
            python3-sympy

RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py # Fetch get-pip.py for python 2.7
RUN python2 get-pip.py
RUN python2 -m pip install sympy

# Graphics utils
RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
            imagemagick \
            poppler-utils \
            graphviz 

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:inkscape.dev/stable
RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
             inkscape

# Documentation tools
RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
            pandoc \
            pandoc-citeproc

RUN apt-get ${APT_OPTS} update -qq && \
    apt-get ${APT_OPTS} install -y \
            texlive-latex-base \
            texlive-latex-extra \
            texlive-latex-recommended \
            texlive-science

RUN gem install bundler

# User account
RUN mkdir /project
WORKDIR /project

# Setup user
RUN useradd \
    -u ${DOCKER_USER_UID} \
    -m \
    -r \
    -G sudo -s /sbin/nologin \
    -c "Docker image user" \
    docker_user
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN chown docker_user:docker_user /project

USER docker_user
WORKDIR /project

# Path for gems
RUN bundle config path /home/docker_user/.local 
ENV GEM_HOME=/home/docker_user/.local/ruby/2.7.0/
ENV PATH="/home/docker_user/.local/ruby/2.7.0/bin/:${PATH}"

# Install gems from Gemfile
COPY Gemfile Gemfile
RUN set
RUN bundle install

# Node is used to install wavedrom-cli
ENV NVM_DIR=/home/docker_user/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash

RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}

# Check it works
ENV PATH="/home/docker_user/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN npm i wavedrom-cli -g

