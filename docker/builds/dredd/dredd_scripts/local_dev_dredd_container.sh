#!/bin/bash
docker run -it \
-v //c/Users/nn31/Dropbox/40-githubRrepos/duke-data-service/docker/builds/dredd/dredd_scripts:/dds \
-v //c/Users/nn31/Dropbox/40-githubRrepos/duke-data-service/apiary.apib:/dds/apiary.apib \
--env HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1 \
--env MY_GENERATED_JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRhYmZiNWYyLWRmMTItNDQ3ZC1hMGQ5LWU0NzgzMDg2N2FjZSIsInNlcnZpY2VfaWQiOiIzNDJjMDc1YS03YWNhLTRjMzUtYjNmNS0yOWYwNDM4ODRiNWIiLCJleHAiOjE0NTAzODI0MTR9.qC8V-pR35VPOMSOSde94dnqIkRovMinMyCHD9WXlbZc \
dds/dredd \
bash


docker run -it \
-v /Users/nn/Dropbox/40-githubRrepos/duke-data-service/docker/builds/dredd/dredd_scripts:/dds \
-v /Users/nn/Dropbox/40-githubRrepos/duke-data-service/apiary.apib:/dds/apiary.apib \
--env HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1 \
--env MY_GENERATED_JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRhYmZiNWYyLWRmMTItNDQ3ZC1hMGQ5LWU0NzgzMDg2N2FjZSIsInNlcnZpY2VfaWQiOiIzNDJjMDc1YS03YWNhLTRjMzUtYjNmNS0yOWYwNDM4ODRiNWIiLCJleHAiOjE0NTAzODI0MTR9.qC8V-pR35VPOMSOSde94dnqIkRovMinMyCHD9WXlbZc \
dds/dredd \
/bin/bash

docker run -it \
-v /Users/nn/Dropbox/40-githubRrepos/duke-data-service/docker/builds/dredd/dredd_scripts:/dds \
-v /Users/nn/Dropbox/40-githubRrepos/duke-data-service/apiary.apib:/dds/apiary.apib \
--env HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1 \
--env MY_GENERATED_JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjRhYmZiNWYyLWRmMTItNDQ3ZC1hMGQ5LWU0NzgzMDg2N2FjZSIsInNlcnZpY2VfaWQiOiIzNDJjMDc1YS03YWNhLTRjMzUtYjNmNS0yOWYwNDM4ODRiNWIiLCJleHAiOjE0NTAzODI0MTR9.qC8V-pR35VPOMSOSde94dnqIkRovMinMyCHD9WXlbZc \
dds/dredd \
/bin/bash
