FROM fedora:42

ARG PYTHON_VERSION=3.10
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN dnf -y update && \
    dnf -y install g++ make wget pv git bash xz gawk \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-devel mediainfo psmisc procps-ng supervisor \
    zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel libffi-devel \
    xz-devel findutils libnsl2-devel libuuid-devel gdbm-devel ncurses-devel tar curl && \
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
    pyenv install 3.8.18 && \
    pyenv install 3.9.18 && \
    pyenv install 3.10.14 && \
    pyenv install 3.11.9 && \
    pyenv install 3.12.3 && \
    pyenv install 3.13.3 && \
    unset PYTHON_CONFIGURE_OPTS'

ENV SUPERVISORD_CONF_DIR=/etc/supervisor/conf.d
ENV SUPERVISORD_LOG_DIR=/var/log/supervisor

RUN mkdir -p ${SUPERVISORD_CONF_DIR} \
    ${SUPERVISORD_LOG_DIR} \
    /app

WORKDIR /app
COPY . .
