# syntax = docker/dockerfile:1.4

# Copyright (c) 2018-present Ark
# Released under the MIT license
# https://opensource.org/licenses/MIT

FROM ubuntu:22.04

SHELL ["/bin/bash", "-e", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NOWARNINGS=yes
ENV YEAR="2022"
ENV PATH="/usr/local/texlive/${YEAR}/bin/x86_64-linux:$PATH"

RUN <<EOT
apt-get update
apt-get -y install \
    build-essential \
    wget \
    git \
    gosu \
    libfontconfig1-dev \
    libfreetype6-dev \
    ghostscript \
    perl \
    python3-pip \
    python3-dev
apt-get clean
rm -rf /var/lib/apt/lists/*
pip3 install pygments

mkdir /tmp/install-tl-unx
wget -O - ftp://tug.org/historic/systems/texlive/${YEAR}/install-tl-unx.tar.gz \
    | tar -xzv -C /tmp/install-tl-unx --strip-components=1

cat << EOS >> /tmp/install-tl-unx/texlive.profile
selected_scheme scheme-basic

tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0

# install collection
collection-basic 1
collection-bibtexextra 1
collection-binextra 1
collection-fontsextra 1
collection-fontsrecommended 1
collection-langenglish 1
collection-langjapanese 1
collection-latexextra 1
collection-latexrecommended 1
collection-luatex 1
collection-mathscience 1
collection-plaingeneric 1
collection-xetex 1

# texmf-dist/doc, texmf-dist/src
option_doc 0
option_src 0
EOS

/tmp/install-tl-unx/install-tl --profile /tmp/install-tl-unx/texlive.profile
rm -r /tmp/install-tl-unx

tlmgr update --self
tlmgr update --all --reinstall-forcibly-removed

mkdir /tmp/latexmk
EOT

COPY .latexmkrc /tmp/latexmk/
COPY --chmod=755 bin/entrypoint.sh /usr/local/bin/
COPY --chmod=755 bin/latexmk-ext /usr/local/bin/

WORKDIR /workdir

ENTRYPOINT ["entrypoint.sh"]
CMD ["latexmk-ext"]
