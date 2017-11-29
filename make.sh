#!/bin/sh

set -ue

IMG_NAMESPACE=deployable
IMG_NAME=rsyslog
IMG_TAG=$IMG_NAMESPACE/$IMG_NAME
CONTAINER_NAME=rsyslog

rundir=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)")
canonical="$rundir/$(basename -- "$0")"

if [ -n "${1:-}" ]; then
  cmd=$1
  shift
else
  cmd=build
fi

cd "$rundir"

####

run_rebuild(){
   docker rm -f $CONTAINER_NAME
   run_build
   run_run
}

run_build(){
  cd "$rundir"
  BUILD_ARGS=${BUILD_ARGS:-}
  docker build -t $IMG_TAG $BUILD_ARGS .
}

run_build_proxy(){
  cd "$rundir"
  BUILD_ARGS='--build-arg DOCKER_BUILD_PROXY=http://10.8.8.8:3142' run_build
}

run_run(){
  CID=$(docker run --detach --name $CONTAINER_NAME -p 1023:123/udp $IMG_TAG)
  echo $CID
  docker ps --filter name=$CONTAINER_NAME
}

####

run_help(){
  echo "Commands:"
  awk '/  ".*"/{ print "  "substr($1,2,length($1)-3) }' make.sh
}

set -x

case $cmd in
  "build")          run_build "$@";;
  "build:proxy")    run_build_proxy "$@";;
  "rebuild")        run_rebuild "$@";;
  "run")            run_run "$@";;
  '-h'|'--help'|'h'|'help') run_help;;
esac


