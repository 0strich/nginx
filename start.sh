#!/usr/bin/env bash

# 1. env 파일 존재시 적용
if [ -e .env ]; then
    source .env
else
    echo "create .env file"
    cp .env.sample .env
    source .env
    # exit 1
fi

# 2. 도커 네트워크 생성
docker network create $NETWORK $NETWORK_OPTIONS

# 3. 두 번째 네트워크가 구성되어 있는지 확인
if [ ! -z ${SERVICE_NETWORK+X} ]; then
    docker network create $SERVICE_NETWORK $SERVICE_NEWTORK_OPTIONS
fi

# 4. 최신 nginx.tmpl 파일 다운로드
curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl >nginx.tmpl

# 5. 로컬 이미지 업데이트
docker-compose pull

# 6. .env 파일이 설정된 경우 특수 구성을 추가

# 사용자가 Special Config 파일 설정 했는지 확인
if [ ! -z ${USE_NGINX_CONF_FILES+X} ] && [ "$USE_NGINX_CONF_FILES" = true ]; then

    # Create the conf folder if it does not exists
    mkdir -p $NGINX_FILES_PATH/conf.d

    # Copy the special configurations to the nginx conf folder
    cp -R ./conf.d/* $NGINX_FILES_PATH/conf.d

    ls $NGINX_FILES_PATH/conf.d
    cat $NGINX_FILES_PATH/conf.d/default.conf

    # Check if there was an error and try with sudo
    if [ $? -ne 0 ]; then
        sudo cp -R ./conf.d/* $NGINX_FILES_PATH/conf.d
    fi

    # If there was any errors inform the user
    if [ $? -ne 0 ]; then
        echo
        echo "#######################################################"
        echo
        echo "There was an error trying to copy the nginx conf files."
        echo "The proxy will still work with default options, but"
        echo "the custom settings your have made could not be loaded."
        echo
        echo "#######################################################"
    fi
fi

# 7. proxy 시작

# 여러 네트워크가 있는지 확인
if [ -z ${SERVICE_NETWORK+X} ]; then
    docker-compose up -d
else
    docker-compose -f docker-compose-multiple-networks.yml up -d
fi

exit 0
