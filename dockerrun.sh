#!/bin/bash
BASE_IMAGE=sqlstream/complete
: ${BASE_IMAGE_LABEL:=7.0.6}

# use generic blaze name for now
: ${CONTAINER_NAME:=blaze}

docker kill $CONTAINER_NAME
docker rm $CONTAINER_NAME

HERE=$(cd `dirname $0`; pwd -P)
cd $HERE

# mount the project itself rather than getting with git

docker run -v $(pwd -P):/home/sqlstream/cellcare \
           -e LOAD_SLAB_FILES= \
           -e SQLSTREAM_HEAP_MEMORY=${SQLSTREAM_HEAP_MEMORY:=4096m} \
           -e SQLSTREAM_SLEEP_SECS=${SQLSTREAM_SLEEP_SECS:=10} \
           -e SQLSTREAM_LICENSE_KEY="${SQLSTREAM_LICENSE_KEY}" \
           --entrypoint /home/sqlstream/cellcare/entrypoint.sh \
           -p 5580:5580 -p 5585:5585 -p 5590:5590 -p 5595:5595 \
           -d --name $CONTAINER_NAME -it $BASE_IMAGE:$BASE_IMAGE_LABEL

docker logs -f $CONTAINER_NAME
