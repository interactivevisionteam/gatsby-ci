# Gatsby CI

This is a simple Dockerfile configuration based on Ubuntu and contains most of the stuff you might need to build and
deploy your Gatsby website using CI/CD pipelines. It contains:

- openssh client
- nodejs
- yarn
- gatsby (binary)

## Example GitLab pipeline configuration

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
        - public/

build:
    stage: build
    only:
        - master
    tags:
        - some-custom-tag
    script:
        - npm install
        - gatsby build

deploy:
    stage: deploy
    dependencies:
        - build
    only:
        - master
    tags:
        - some-custom-tag
    script:
        - mkdir ~/.ssh
        - echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
        - chmod 644 ~/.ssh/known_hosts
        - eval $(ssh-agent -s)
        - ssh-add <(echo "$DEPLOY_PRIVATE_KEY")
        - ssh user@remote-host -p 22 "mkdir /home/user/domains/domain.example/new"
        - scp -P 22 -r public/* user@remote-host:/home/user/domains/domain.example/new
        - ssh user@remote-host -p 22 "rm -rf /home/user/domains/domain.example/current"
        - ssh user@remote-host -p 22 "mv /home/user/domains/domain.example/new /home/user/domains/domain.example/current"
```
