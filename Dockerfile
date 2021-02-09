FROM ubuntu:18.04

ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /var/app

RUN apt-get update \
    && apt-get install -y curl openssh-client \
    && curl -sL "https://deb.nodesource.com/setup_12.x" | bash - \
    && apt-get install -y nodejs \
    && curl -sL "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && npm install -g gatsby-cli

RUN command -v node
RUN command -v npm
RUN command -v npx
RUN command -v gatsby

RUN mkdir ~/.ssh && touch ~/.ssh/config
