#!/bin/bash

NETWORK_ROSCORE=$1
NUMID_DRONE=4
SESSION=$USER
IP="10.202.0.1"		#This IP is for simulated executions (with sphinx)
#IP="192.168.42.1" 	#This IP is for real world flights

MAV_NAME=bebop2

export AEROSTACK_PROJECT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/ros/melodic/lib/parrot_arsdk
. ${AEROSTACK_STACK}/config/mission/setup.sh

# if [ -z $NETWORK_ROSCORE ] # Check if NETWORK_ROSCORE is NULL
#   then
#       #Argument 2 is empty
# 	  . ${AEROSTACK_STACK}/setup.sh
#   else
#     . ${AEROSTACK_STACK}/setup.sh NETWORK_ROSCORE
# fi

# Kill any previous session (-t -> target session, -a -> all other sessions )


tmux kill-session -t $SESSION
tmux kill-session -a

# Create new session  (-2 allows 256 colors in the terminal, -s -> session name, -d -> not attach to the new session)
tmux -2 new-session -d -s $SESSION

# Create roscore 
# send-keys writes the string into the sesssion (-t -> target session , C-m -> press Enter Button)
tmux rename-window -t $SESSION:0 'roscore'
tmux send-keys -t $SESSION:0 "roscore" C-m
sleep 1

# Create one window per roslaunch (-t -> target session , -n -> window name) 

tmux new-window -t $SESSION:6 -n 'Localization With Simple EKF'
tmux send-keys "roslaunch localization_with_simple_ekf localization_with_simple_ekf.launch --wait \
drone_id_int:=$NUMID_DRONE drone_id_namespace:=drone$NUMID_DRONE my_stack_directory:=${AEROSTACK_STACK} config_file:=${AEROSTACK_PROJECT}/configs/drone$NUMID_DRONE/robot_localization.xml" C-m

tmux new-window -t $SESSION:1 -n 'viewer'
tmux send-keys "roslaunch alphanumeric_viewer alphanumeric_viewer.launch --wait \
    drone_id_namespace:=drone$NUMID_DRONE \
    my_stack_directory:=${AEROSTACK_PROJECT}" C-m
            
tmux new-window -t $SESSION:2 -n 'bebop autonomy'
tmux send-keys "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/ros/melodic/lib/parrot_arsdk;\
roslaunch bebop_driver bebop_node.launch ip:=$IP drone_type:=$MAV_NAME namespace:=drone4 --wait" C-m

tmux new-window -t $SESSION:3 -n 'bebop interface'
tmux send-keys "roslaunch driverBebopROSModule driverBebopROSModule.launch \
--wait drone_id_namespace:=drone$NUMID_DRONE" C-m

tmux new-window -t $SESSION:4 -n 'Quadrotor Motion With PID Control'
tmux send-keys "roslaunch quadrotor_motion_with_pid_control quadrotor_motion_with_pid_control.launch --wait \
    namespace:=drone$NUMID_DRONE \
    robot_config_path:=${AEROSTACK_PROJECT}/configs/drone$NUMID_DRONE" C-m

tmux new-window -t $SESSION:5 -n 'Basic Behaviors'
tmux send-keys "roslaunch basic_quadrotor_behaviors basic_quadrotor_behaviors.launch --wait \
    namespace:=drone$NUMID_DRONE" C-m

tmux new-window -t $SESSION:7 -n 'Python Interpreter'
tmux send-keys "roslaunch python_based_mission_interpreter_process python_based_mission_interpreter_process.launch --wait \
drone_id_namespace:=drone$NUMID_DRONE drone_id_int:=$NUMID_DRONE my_stack_directory:=${AEROSTACK_STACK} mission_configuration_folder:=${AEROSTACK_PROJECT}/configs/mission" C-m

tmux new-window -t $SESSION:8 -n 'Behavior Coordinator'
tmux send-keys "sleep 2; roslaunch behavior_coordinator behavior_coordinator.launch --wait \
robot_namespace:=drone$NUMID_DRONE catalog_path:=${AEROSTACK_PROJECT}/configs/mission/behavior_catalog.yaml" C-m

tmux attach-session -t $SESSION:1


