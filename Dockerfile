FROM alpine:3.12

LABEL org.label-schema.name = "gdal-python-alpine-3-12"
LABEL org.label-schema.description = "Inspired by https://github.com/petr-k/gdal-python-alpine, Alpine-based image with Python, GDAL/OGR & GEOS, compiled with selected additional drivers for 2021 Python Projects."
LABEL org.label-schema.vcs-url = "https://github.com/ararage/gdal-python-alpine-3-12"
LABEL org.label-schema.vendor = "José Ricardo Pérez"

ENV PYTHONUNBUFFERED 1
ENV PROCESSOR_COUNT 1
ENV GEOS http://download.osgeo.org/geos/geos-3.8.1.tar.bz2

ARG LIBKML_VERSION=1.3.0
RUN \
  apk update && \
  apk -U upgrade && \
  apk add --virtual build-dependencies \
    # to reach GitHub's https
    openssl ca-certificates \
    build-base cmake musl-dev linux-headers \
    # for libkml compilation
    zlib-dev minizip-dev expat-dev uriparser-dev boost-dev && \
  apk add \
    # libkml runtime
    zlib minizip expat uriparser boost && \
  update-ca-certificates && \
  mkdir /build && cd /build && \
  apk --update add tar && \
  # libkml
  wget -O libkml.tar.gz "https://github.com/libkml/libkml/archive/${LIBKML_VERSION}.tar.gz" && \
  tar --extract --file libkml.tar.gz && \
  cd libkml-${LIBKML_VERSION} && mkdir build && cd build && cmake .. && make && make install && cd ../.. \
  && apk add gdal \
  #Python
  && apk add python3 \
  # psycopg2 dependencies
  && apk add --virtual build-deps gcc python3-dev musl-dev \
  && apk add postgresql-dev \
  # Pillow dependencies
  && apk add jpeg-dev zlib-dev freetype-dev lcms2-dev openjpeg-dev tiff-dev tk-dev tcl-dev \
  # CFFI dependencies
  && apk add libffi-dev py-cffi \
  # Translations dependencies
  && apk add gettext \
  # Cryptography
  && apk add --no-cache openssl-dev \
  && apk add gcc cargo \
  && apk add rust \
  # https://docs.djangoproject.com/en/dev/ref/django-admin/#dbshell
  && apk add postgresql-client \
  && apk add g++ \
  && apk add make 

WORKDIR /geos
ADD $GEOS /geos.tar.bz2
RUN tar xf /geos.tar.bz2 -C /geos --strip-components=1
RUN ./configure && make -j $PROCESSOR_COUNT && make install
RUN ldconfig /etc/ld.so.conf.d
