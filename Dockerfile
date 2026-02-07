# -- Stage 1: build av1an from source on Fedora ----------------------------------
FROM fedora:43 AS av1an-builder
RUN dnf -y update && \
    dnf -y install gcc gcc-c++ rust cargo clang nasm git \
    ffmpeg-free-devel libvpx-devel svt-av1-devel && \
    dnf clean all
RUN git clone https://github.com/master-of-zen/Av1an.git /tmp/Av1an && \
    cd /tmp/Av1an && \
    cargo build --release && \
    strip /tmp/Av1an/target/release/av1an

# -- Stage 2: final image -------------------------------------------------------
FROM fedora:43

ARG PYTHON_VERSION=3.10
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN dnf -y update && \
    dnf -y install gcc gcc-c++ make wget pv git bash xz gawk patch \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-devel mediainfo psmisc procps-ng supervisor \
    zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel libffi-devel \
    xz-devel findutils libnsl2-devel libuuid-devel gdbm-devel ncurses-devel tar curl \
    pkgconfig aria2 \
    ffmpeg-free aom svt-av1 libvpx mkvtoolnix && \
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

# Copy av1an binary built natively on Fedora
COPY --from=av1an-builder /tmp/Av1an/target/release/av1an /usr/local/bin/av1an

COPY . .
