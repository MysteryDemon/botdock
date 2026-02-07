FROM archlinux:latest

ARG PYTHON_VERSION=3.10
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm gcc make wget pv git bash xz gawk \
    python python-pip mediainfo psmisc procps-ng supervisor \
    zlib bzip2 readline sqlite openssl libffi \
    findutils gdbm ncurses tar curl \
    aria2 base-devel tk \
    rust nasm clang vapoursynth && \
    pacman -Scc --noconfirm

ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN bash -c '\
    export PYENV_ROOT="/root/.pyenv" && \
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH" && \
    git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT && \
    git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv && \
    eval "$(pyenv init -)" && \
    eval "$(pyenv virtualenv-init -)" && \
    pyenv install 3.8.18 && \
    pyenv install 3.9.18 && \
    pyenv install 3.10.14 && \
    pyenv install 3.11.9 && \
    pyenv install 3.12.3 && \
    pyenv install 3.13.3 && \
    pyenv global 3.10.14' && \
    echo '\''eval "$(${PYENV_ROOT}/bin/pyenv init -)"'\'' >> /root/.bashrc && \
    echo '\''eval "$(${PYENV_ROOT}/bin/pyenv virtualenv-init -)"'\'' >> /root/.bashrc

RUN git clone https://github.com/master-of-zen/Av1an /tmp/Av1an && \
    cd /tmp/Av1an && \
    cargo build --release && \
    cp target/release/av1an /usr/local/bin/av1an && \
    rm -rf /tmp/Av1an

ENV SUPERVISORD_CONF_DIR=/etc/supervisor/conf.d
ENV SUPERVISORD_LOG_DIR=/var/log/supervisor

RUN mkdir -p ${SUPERVISORD_CONF_DIR} \
    ${SUPERVISORD_LOG_DIR} \
    /app

WORKDIR /app
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /bin/ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffprobe /bin/ffprobe
COPY --from=mwader/static-ffmpeg:latest /doc /doc
COPY --from=mwader/static-ffmpeg:latest /versions.json /versions.json
COPY --from=mwader/static-ffmpeg:latest /etc/ssl/cert.pem /etc/ssl/cert.pem
COPY --from=mwader/static-ffmpeg:latest /etc/fonts /etc/fonts
COPY --from=mwader/static-ffmpeg:latest /usr/share/fonts /usr/share/fonts
COPY --from=mwader/static-ffmpeg:latest /usr/share/consolefonts /usr/share/consolefonts
COPY --from=mwader/static-ffmpeg:latest /var/cache/fontconfig /var/cache/fontconfig
COPY . .
