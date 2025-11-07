
FROM ros:jazzy

# Install any necessary dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    curl \
    build-essential


# Install rustup and the latest stable version of Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# 3) make sure cargo/rustup is on PATH for later layers
ENV PATH="/root/.cargo/bin:${PATH}"

# 4) now call rustup by its full path (no sourcing)
RUN /root/.cargo/bin/rustup update stable
# Install Acados
RUN git clone https://github.com/acados/acados.git && cd acados && git submodule update --recursive --init
RUN mkdir -p build
WORKDIR /acados/build
RUN cmake -DACADOS_WITH_QPOASES=ON .. 
RUN make install -j4
WORKDIR /acados
RUN pip3 install -e interfaces/acados_template --break-system-packages
ENV LD_LIBRARY_PATH="/acados/lib"
ENV ACADOS_SOURCE_DIR="/acados"

RUN git clone https://github.com/acados/tera_renderer.git
WORKDIR /acados/tera_renderer
RUN rustup update stable
RUN cargo build --verbose --release

WORKDIR /acados
RUN mv tera_renderer/target/release/t_renderer bin/

# Clone packages into the workspace
WORKDIR /ros2_ws/src
RUN git clone --branch dev-docker_run https://github.com/DISCOWER/px4-mpc.git temp_folder_name_for_px4_mpc_repo && \
    cd temp_folder_name_for_px4_mpc_repo && \
    git clone https://github.com/Jaeyoung-Lim/px4-offboard.git && \
    git clone https://github.com/DISCOWER/px4_msgs.git

WORKDIR /ros2_ws
# Build the package(s)
RUN bash -c "set -e \
    && source /opt/ros/jazzy/setup.bash \
    && colcon build --symlink-install --event-handlers console_direct+"
RUN pip3 install mavsdk --break-system-packages
ENV MPC_NAMESPACE=snap

# Start the package at container start up
ENTRYPOINT ["bash", "-c", "source /opt/ros/jazzy/setup.bash && source /ros2_ws/install/setup.bash && export DOCKER_ENV=1 && ros2 launch px4_mpc mpc_spacecraft_launch.py namespace:=${MPC_NAMESPACE:-snap} setpoint_from_rviz:=False"]
# CMD ["ros2", "launch", "px4_mpc", "mpc_spacecraft_launch.py", "setpoint_from_rviz:=False"]

# "ros2", "launch", "px4_mpc", "mpc_spacecraft_launch.py", "setpoint_from_rviz:=False"