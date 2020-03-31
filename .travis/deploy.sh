#!/bin/bash

IMAGE_TAG=$1
IMAGE_NAME=openshift-acme-whitelist-updater

do_tag(){
    local SOURCE=$1
    local TARGET=$2
    docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${SOURCE} ${DOCKER_USERNAME}/${IMAGE_NAME}:${TARGET}
}

do_push(){
    local TAG=$1
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}
    echo "Publish image ${DOCKER_USERNAME}:${IMAGE_NAME}:${TAG}"
}

[ -z ${DOCKER_USERNAME} ] && echo "Error: variable DOCKER_USERNAME not defined, deployment canceled" && exit 1
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

case ${IMAGE_TAG} in
    dev|nightly)
        do_tag ${TRAVIS_COMMIT} nightly
        do_push nightly
        ;;
    master|latest)
        [ -z ${TRAVIS_TAG} ] && echo "Error: undefined variable TRAVIS_TAG" && exit 1
        for TARGET in nightly ${TRAVIS_TAG} latest; do
            do_tag ${TRAVIS_COMMIT} ${TARGET}
            do_push ${TARGET}
        done
        ;;
    *)
        echo "Usage: $0 [dev|nightly|master|latest]"
        exit 1
        ;;
esac
