FROM docker:26.1-dind-rootless

USER root

RUN apk add --no-cache slirp4netns

USER rootless
