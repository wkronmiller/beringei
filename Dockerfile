# Pull base image.
FROM ubuntu:17.10

ENV WORKDIR /usr/local/beringei
ENV RUN_CMD ./beringei/service/beringei_main \
              -beringei_configuration_path $WORKDIR/beringei.json \
              -create_directories \
              -sleep_between_bucket_finalization_secs 60 \
              -allowed_timestamp_behind 300 \
              -bucket_size 600 \
              -buckets 144 \
              -logtostderr \
              -v=2

# Copy files from CircleCI into docker container.
COPY . $WORKDIR

# Define default command.
CMD ["bash"]

# Setup the docker container.
ENV FB_VERSION="2017.05.22.00"
ENV ZSTD_VERSION="1.1.1"

WORKDIR $WORKDIR

RUN apt update

RUN apt install --yes \
    autoconf \
    autoconf-archive \
    automake \
    binutils-dev \
    bison \
    clang-format-3.9 \
    cmake \
    flex \
    g++ \
    git \
    gperf \
    libboost-all-dev \
    libcap-dev \
    libdouble-conversion-dev \
    libevent-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libjemalloc-dev \
    libkrb5-dev \
    liblz4-dev \
    liblzma-dev \
    libnuma-dev \
    libsasl2-dev \
    libsnappy-dev \
    libssl-dev \
    libtool \
    make \
    pkg-config \
    scons \
    wget \
    zip \
    zlib1g-dev

RUN mkdir -pv /usr/local/facebook-${FB_VERSION}
RUN ln -sfT /usr/local/facebook-${FB_VERSION} /usr/local/facebook

ENV LDFLAGS="-L/usr/local/facebook/lib -Wl,-rpath=/usr/local/facebook/lib"
ENV CPPFLAGS="-I/usr/local/facebook/include"

WORKDIR /tmp

RUN wget -O /tmp/folly-${FB_VERSION}.tar.gz https://github.com/facebook/folly/archive/v${FB_VERSION}.tar.gz
RUN wget -O /tmp/wangle-${FB_VERSION}.tar.gz https://github.com/facebook/wangle/archive/v${FB_VERSION}.tar.gz
RUN wget -O /tmp/fbthrift-${FB_VERSION}.tar.gz https://github.com/facebook/fbthrift/archive/v${FB_VERSION}.tar.gz
RUN wget -O /tmp/proxygen-${FB_VERSION}.tar.gz https://github.com/facebook/proxygen/archive/v${FB_VERSION}.tar.gz
RUN wget -O /tmp/mstch-master.tar.gz https://github.com/no1msd/mstch/archive/master.tar.gz
RUN wget -O /tmp/zstd-${ZSTD_VERSION}.tar.gz https://github.com/facebook/zstd/archive/v${ZSTD_VERSION}.tar.gz
RUN 
RUN tar xzvf folly-${FB_VERSION}.tar.gz
RUN tar xzvf wangle-${FB_VERSION}.tar.gz
RUN tar xzvf fbthrift-${FB_VERSION}.tar.gz
RUN tar xzvf proxygen-${FB_VERSION}.tar.gz
RUN tar xzvf mstch-master.tar.gz
RUN tar xzvf zstd-${ZSTD_VERSION}.tar.gz

RUN $WORKDIR/setup_ubuntu.sh

WORKDIR $WORKDIR

# Create a build directory.
RUN mkdir $WORKDIR/build
WORKDIR $WORKDIR/build

# Compile and install
RUN cmake ..
RUN make install

RUN ./beringei/tools/beringei_configuration_generator --host_names localhost --file_path $WORKDIR/beringei.json

ENTRYPOINT $RUN_CMD
