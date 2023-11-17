# syntax = docker/dockerfile:1.6

# Copyright (c) 2018-present Ark
# Copyright (c) 2023 AkashiSN
# Released under the MIT license
# https://opensource.org/licenses/MIT

FROM ubuntu:22.04 as install-pygments

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NOWARNINGS=yes

RUN <<EOT
apt-get update
apt-get -y install --no-install-recommends \
    python3-pip

pip3 install pygments
EOT

FROM ubuntu:22.04

SHELL ["/bin/bash", "-e", "-c"]
ARG YEAR="2023"
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NOWARNINGS=yes \
    YEAR="${YEAR}" \
    PATH="/usr/local/bin/texlive:${PATH}" \
    CTAN_MIRROR="https://ftp.jaist.ac.jp/pub/CTAN"

RUN <<EOT
apt-get update
apt-get -y install --no-install-recommends \
    fontconfig \
    ghostscript \
    git \
    gosu \
    perl \
    python3 \
    wget

# for latexindent
apt-get -y install --no-install-recommends \
    libyaml-tiny-perl \
    libfile-homedir-perl

apt-get clean
rm -rf /var/lib/apt/lists/*

mkdir /tmp/install-tl-unx
wget -O - ftp://tug.org/historic/systems/texlive/${YEAR}/install-tl-unx.tar.gz \
    | tar -xzv -C /tmp/install-tl-unx --strip-components=1

cat << EOS >> /tmp/install-tl-unx/texlive.profile
selected_scheme scheme-basic

tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0

# install collection
collection-bibtexextra 1
collection-fontsextra 1
collection-fontsrecommended 1
collection-langenglish 1
collection-langjapanese 1
collection-latexextra 1
collection-luatex 1
collection-mathscience 1
collection-plaingeneric 1
collection-xetex 1

# texmf-dist/doc, texmf-dist/src
option_doc 0
option_src 0
EOS

/tmp/install-tl-unx/install-tl --profile /tmp/install-tl-unx/texlive.profile \
    --repository ${CTAN_MIRROR}/systems/texlive/tlnet
rm -r /tmp/install-tl-unx

ln -sf /usr/local/texlive/*/bin/* /usr/local/bin/texlive

tlmgr update --self
tlmgr update --all --reinstall-forcibly-removed

tlmgr install \
    latexdiff \
    latexindent \
    latexmk \
    pdfcrop
EOT

# Copy pygments
COPY --from=install-pygments /usr/local/bin/pygmentize /usr/local/bin/
COPY --from=install-pygments /usr/local/lib/python3.10/dist-packages/pygments/ \
                             /usr/local/lib/python3.10/dist-packages/pygments/

# Copy scripts
COPY .latexmkrc /tmp/latexmk/
COPY --chmod=755 bin/ /usr/local/bin/

# Additional packages
COPY packages/texmf-dist/ /usr/local/texlive/${YEAR}/texmf-dist

# Reload sty file
RUN mktexlsr

WORKDIR /workdir

ENTRYPOINT ["entrypoint.sh"]
CMD ["latexmk-ext"]
