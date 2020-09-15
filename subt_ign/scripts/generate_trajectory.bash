#!/bin/bash
#
# Usage: ./generate_trajectory.bash <path_to_log_files> <output_path> <world_name> 
#
# Example usage:
#
# ./generate_trajectory.bash ~/Downloads/log /tmp/output/ cave_qual
#
# Notes:
#   1. You will need the path_tracer executable in your PATH.
#   2. Requires Ignition Citadel
#   3. If you kill this before docker full starts, then use
#      `docker kill <ID>` to kill the docker container.

logDir=$1
destDir=$2
worldName=$3

# Run the simulation world.
docker run -t \
  -l "subt-path" \
  -e DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e XAUTHORITY=$XAUTH \
  -e IGN_PARTITION=PATH_TRACER \
  -v "$XAUTH:$XAUTH" \
  -v "/tmp/.X11-unix:/tmp/.X11-unix" \
  -v "/etc/localtime:/etc/localtime:ro" \
  -v "/dev/input:/dev/input" \
  -v "$destDir:/tmp/ign/output" \
  --network host \
  --rm \
  --privileged \
  --security-opt seccomp=unconfined \
  --gpus all \
  osrf/subt-virtual-testbed:cloudsim_sim_citadel \
  -v 4 path_tracer.ign worldName:=$worldName &

# Wait for docker to start
sleep 10

# Get the docker ID
dockerid=`docker ps -f "label=subt-path" --format "{{.ID}}"`

# SIGNINT handler
trap handler INT
function handler() {
  # kill the docker container
  docker kill $dockerid 
  exit 1
}

# Move the camera to a good pose
IGN_PARTITION=PATH_TRACER ign service -s /gui/move_to/pose --reqtype ignition.msgs.Pose --reptype ignition.msgs.Boolean --timeout 2000 --req 'position: {x: 0, y: 0, z: 100}'

# Start video recording
IGN_PARTITION=PATH_TRACER ign service -s /gui/record_video --reqtype ignition.msgs.VideoRecord --reptype ignition.msgs.Boolean --timeout 2000 --req 'start: true, format: "mp4", save_filename: "/tmp/ign/output/0000-robot_paths.mp4"'

# Run the path tracer.
path_tracer $logDir 1000

# Stop video recording
IGN_PARTITION=PATH_TRACER ign service -s /gui/record_video --reqtype ignition.msgs.VideoRecord --reptype ignition.msgs.Boolean --timeout 2000 --req 'stop: true'

# kill the docker container
docker kill $dockerid 
