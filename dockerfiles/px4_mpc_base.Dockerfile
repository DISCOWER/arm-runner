# Dockerfile.base
FROM ros:jazzy

RUN apt-get update && apt-get install -y \
    git python3-pip curl build-essential cmake \
    && rm -rf /var/lib/apt/lists/*

# make a base workspace
WORKDIR /ros2_base_ws/src

# clone stuff that is STABLE / slow-changing
# (example: px4-offboard + px4_msgs are pretty stable for you?)
RUN git clone https://github.com/Jaeyoung-Lim/px4-offboard.git && \
    git clone https://github.com/DISCOWER/px4_msgs.git

WORKDIR /ros2_base_ws
RUN bash -c "source /opt/ros/jazzy/setup.bash && colcon build --symlink-install"

# install extras once
RUN pip3 install mavsdk --break-system-packages
