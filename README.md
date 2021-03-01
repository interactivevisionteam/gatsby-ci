# Gatsby CI
This is a simple Dockerfile configuration based on Ubuntu and contains most of the stuff you might need to build and deploy your Gatsby website using CI/CD pipelines. It contains:
- openssh client
- nodejs
- yarn
- gatsby (binary)

## Example GitLab pipeline configuration

Here's basic example of configuring a project build using Gatsby's binary and then deployment to 

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
        - eval $(ssh-agent -s)
        - ssh-add <(echo "$DEPLOY_PRIVATE_KEY")
        - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
        - ssh user@remote-host -p 22 "mkdir /home/user/domains/domain.example/new"
        - scp -P 22 -r public/* user@remote-host:/home/user/domains/domain.example/new
        - ssh user@remote-host -p 22 "rm -rf /home/user/domains/domain.example/current"
        - ssh user@remote-host -p 22 "mv /home/user/domains/domain.example/new /home/user/domains/domain.example/current"
```
