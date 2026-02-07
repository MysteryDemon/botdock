# -- Stage 1: av1an image (Arch-based) with ffmpeg, encoders, and av1an ----------
FROM masterofzen/av1an:latest AS av1an-base

# -- Stage 2: collect only the shared libs the av1an binaries actually need ------
FROM av1an-base AS av1an-deps
USER root
RUN mkdir -p /av1an-deps/bin /av1an-deps/lib && \
    for bin in \
    /usr/bin/ffmpeg /usr/bin/ffprobe \
    /usr/local/bin/av1an /usr/local/bin/rav1e \
    /usr/bin/aomenc /usr/bin/SvtAv1EncApp \
    /usr/bin/vpxenc /usr/bin/mkvmerge; do \
    [ -f "$bin" ] && cp "$bin" /av1an-deps/bin/ ; \
    done && \
    for bin in /av1an-deps/bin/*; do \
    ldd "$bin" 2>/dev/null | grep "=>" | awk '{print $3}' | sort -u | \
    while read -r lib; do \
    [ -f "$lib" ] && cp -nL "$lib" /av1an-deps/lib/ ; \
    done ; \
    done && \
    # Remove core glibc/system libs and OpenSSL – the host OS supplies these
    rm -f /av1an-deps/lib/libc.so* /av1an-deps/lib/libm.so* \
    /av1an-deps/lib/libpthread.so* /av1an-deps/lib/libdl.so* \
    /av1an-deps/lib/librt.so* /av1an-deps/lib/ld-linux* \
    /av1an-deps/lib/libcrypto.so* /av1an-deps/lib/libssl.so* \
    /av1an-deps/lib/libstdc++.so* /av1an-deps/lib/libgcc_s.so* \
    /av1an-deps/lib/libz.so*

# -- Stage 3: final image -------------------------------------------------------
FROM fedora:43

ARG PYTHON_VERSION=3.10
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN dnf -y update && \
    dnf -y install gcc gcc-c++ make wget pv git bash xz gawk patch \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-devel mediainfo psmisc procps-ng supervisor \
    zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel libffi-devel \
    xz-devel findutils libnsl2-devel libuuid-devel gdbm-devel ncurses-devel tar curl \
    pkgconfig aria2 && \
    dnf clean all

RUN python${PYTHON_VERSION} -m ensurepip --upgrade && \
    python${PYTHON_VERSION} -m pip install --upgrade pip setuptools && \
    alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip${PYTHON_VERSION} 1

ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN bash -c '\
    export PYENV_ROOT="/root/.pyenv" && \
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH" && \
    git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT && \
    git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv && \
    eval "$(pyenv init -)" && \
    eval "$(pyenv virtualenv-init -)" && \
    export PYTHON_CONFIGURE_OPTS="--without-tk" && \
    pyenv install -v 3.8.18 && \
    pyenv install -v 3.9.18 && \
    pyenv install -v 3.10.14 && \
    pyenv install -v 3.11.9 && \
    pyenv install -v 3.12.3 && \
    pyenv install -v 3.13.3 && \
    pyenv global 3.10.14 && \
    unset PYTHON_CONFIGURE_OPTS'

ENV SUPERVISORD_CONF_DIR=/etc/supervisor/conf.d
ENV SUPERVISORD_LOG_DIR=/var/log/supervisor

RUN mkdir -p ${SUPERVISORD_CONF_DIR} \
    ${SUPERVISORD_LOG_DIR} \
    /app

WORKDIR /app

# Copy av1an binaries from the av1an Docker image
COPY --from=av1an-deps /av1an-deps/bin/ffmpeg /bin/ffmpeg
COPY --from=av1an-deps /av1an-deps/bin/ffprobe /bin/ffprobe
COPY --from=av1an-deps /av1an-deps/bin/av1an /usr/local/bin/av1an
COPY --from=av1an-deps /av1an-deps/bin/rav1e /usr/local/bin/rav1e
COPY --from=av1an-deps /av1an-deps/bin/aomenc /usr/local/bin/aomenc
COPY --from=av1an-deps /av1an-deps/bin/SvtAv1EncApp /usr/local/bin/SvtAv1EncApp
COPY --from=av1an-deps /av1an-deps/bin/vpxenc /usr/local/bin/vpxenc
COPY --from=av1an-deps /av1an-deps/bin/mkvmerge /usr/local/bin/mkvmerge

# Copy shared libraries required by the above binaries (codec libs, etc.)
COPY --from=av1an-deps /av1an-deps/lib/ /usr/local/lib/av1an/
# Register av1an libs with ldconfig (NOT LD_LIBRARY_PATH) so they don't override system libs
RUN echo '/usr/local/lib/av1an' > /etc/ld.so.conf.d/av1an.conf && ldconfig

COPY . .
