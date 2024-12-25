# Use a lightweight Linux base image
FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    ASTERISK_VERSION=20 \
    BUILD_DEPS="curl gnupg2 build-essential libxml2-dev libsqlite3-dev libjansson-dev uuid-dev libssl-dev libedit-dev" \
    RUNTIME_DEPS="dahdi-linux libjansson4 libsqlite3-0 uuid-runtime libssl1.1" 

# Update system and install dependencies
RUN apt-get update && \
    apt-get install -y $BUILD_DEPS $RUNTIME_DEPS && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Asterisk source
WORKDIR /usr/src
RUN curl -sSL https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz | tar xz && \
    cd asterisk-${ASTERISK_VERSION}* && \
    ./configure --with-jansson-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable app_meetme menuselect.makeopts && \
    make -j$(nproc) && \
    make install && \
    make samples && \
    make config && \
    ldconfig && \
    rm -rf /usr/src/asterisk-${ASTERISK_VERSION}* && \
    apt remove -y BUILD_DEPS

# Expose necessary ports
EXPOSE 5060/udp 5060/tcp 10000-20000/udp

# Copy custom configurations (optional)
# COPY ./config/sip.conf /etc/asterisk/sip.conf
# COPY ./config/extensions.conf /etc/asterisk/extensions.conf

# Set entrypoint and default command
ENTRYPOINT ["/usr/sbin/asterisk"]
CMD ["-f", "-vvv"]
