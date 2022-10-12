
# bump: openjpeg /OPENJPEG_VERSION=([\d.]+)/ https://github.com/uclouvain/openjpeg.git|*
# bump: openjpeg after ./hashupdate Dockerfile OPENJPEG $LATEST
# bump: openjpeg link "CHANGELOG" https://github.com/uclouvain/openjpeg/blob/master/CHANGELOG.md
ARG OPENJPEG_VERSION=2.5.0
ARG OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz"
ARG OPENJPEG_SHA256=0333806d6adecc6f7a91243b2b839ff4d2053823634d4f6ed7a59bc87409122a

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

FROM base AS download
ARG OPENJPEG_URL
ARG OPENJPEG_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O openjpeg.tar.gz "$OPENJPEG_URL" && \
  echo "$OPENJPEG_SHA256  openjpeg.tar.gz" | sha256sum --status -c - && \
  mkdir openjpeg && \
  tar xf openjpeg.tar.gz -C openjpeg --strip-components=1 && \
  rm openjpeg.tar.gz && \
  apk del download

FROM base AS build
COPY --from=download /tmp/openjpeg/ /tmp/openjpeg/
WORKDIR /tmp/openjpeg/build
RUN \
  apk add --no-cache --virtual build \
    build-base cmake && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PKGCONFIG_FILES=ON \
    -DBUILD_CODEC=OFF \
    -DWITH_ASTYLE=OFF \
    -DBUILD_TESTING=OFF \
    .. && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG OPENJPEG_VERSION
COPY --from=build /usr/local/lib/pkgconfig/libopenjp2.pc /usr/local/lib/pkgconfig/libopenjp2.pc
COPY --from=build /usr/local/lib/libopenjp2.a /usr/local/lib/libopenjp2.a
COPY --from=build /usr/local/include/openjpeg-2.5/ /usr/local/include/openjpeg-2.5/
