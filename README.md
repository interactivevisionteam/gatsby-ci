# Gatsby CI

This is a simple Dockerfile configuration based on Ubuntu and contains most of the stuff you might need to build and
deploy your Gatsby website using CI/CD pipelines. It contains:

- openssh client
- nodejs
- yarn
- gatsby (binary)
- lftp

## Example GitLab pipeline configuration

### Using SSH and `rsync` command

Here's a basic example of configuring a pipeline to build project using Gatsby's binary, and then to deploy a compiled
version to the remote host using SCP. This workflow first creates a `new` directory on the remote host, and uploads
compiled version to it. This prevents issues with live version if anything would fail. Once everything is uploaded,
`current` live version directory is removed, and a `new` directory is moved into it's place.

Usually shared hosting providers points your domains to `public` or `public_html` directory. The simplest way to make
your `current` directory becoming a server root directory is to symlink `public` directory to `current`. Symbolic links
stays in place even when target directory is removed, so replacement process won't affect it. Alternatively, if you can
configure a domain's root directory on your server, you can set it straight to `current` directory. 

**.gitlab-ci.yml**

```yaml
image: intervi/gatsby-ci:latest

stages:
    - build
    - deploy

cache:
    paths:
        - node_modules

build:
    stage: build
    artifacts:
        expire_in: 1h
        paths:
            - public
    only:
        - master
    before_script:
        - export NODE_ENV="production"
    script:
        - yarn install
        - gatsby build

deploy:
    stage: deploy
    dependencies:
        - build
    only:
        - master
    before_script:
        - eval $(ssh-agent -s)
        - echo "$REMOTE_SERVER_PRIVATE_KEY" | base64 -d | ssh-add -
        - mkdir -p ~/.ssh
        - chmod 700 ~/.ssh
        - echo "$REMOTE_SERVER_KNOWN_HOST" | base64 -d >> ~/.ssh/known_hosts
        - chmod 644 ~/.ssh/known_hosts
    script:
        - ssh user@remotehost -p 22 "[[ -d ${REMOTE_ROOT_PATH}/new ]] && rm -rf ${REMOTE_ROOT_PATH}/new || echo New directory does not exist. Skipping..."
        - ssh user@remotehost -p 22 "mkdir ${REMOTE_ROOT_PATH}/new"
        - rsync -avzr -e "ssh -p 22" public/ user@remotehost:"${REMOTE_ROOT_PATH}/new/"
        - ssh user@remotehost -p 22 "[[ -d ${REMOTE_ROOT_PATH}/current ]] && rm -rf ${REMOTE_ROOT_PATH}/current || echo Current directory does not exist. Skipping..."
        - ssh user@remotehost -p 22 "mv ${REMOTE_ROOT_PATH}/new ${REMOTE_ROOT_PATH}/current"
```

### Using FTP and `lftp mirror` command

When your hosting doesn't provide an SSH access, you might want to use an FTP protocol to transfer your built version
to your server, using `lftp` client, and it's `mirror` command to synchronize your new version with remote server.
It will update the files, and will remove any files that no longer exists in the source directory.

**.gitlab-ci.yml**

```yaml
image: intervi/gatsby-ci:latest

stages:
    - build
    - deploy

cache:
    paths:
        - node_modules

build:
    stage: build
    artifacts:
        expire_in: 1h
        paths:
            - public
    only:
        - master
    before_script:
        - export NODE_ENV="production"
    script:
        - yarn install
        - gatsby build

deploy:
    stage: deploy
    dependencies:
        - build
    only:
        - master
    script:
        - lftp -e "set ftp:ssl-allow no; mirror -R -e --parallel=10 public/ /public_html; quit" -u $FTP_USER,$FTP_PASSWD $FTP_IP
```
