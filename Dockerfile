# syntax=docker/dockerfile:1.2

# example ci for packaging app
FROM python:3.9-slim as ci

RUN pip install poetry && mkdir /app
WORKDIR /app

COPY . /app

RUN poetry build -f sdist

# base for rpmbuild
FROM fedora:37 as buildrpmbase


RUN dnf install -y rpmdevtools 'dnf-command(builddep)'


ENV HOME /root/
RUN mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo '%_topdir %{getenv:HOME}/rpmbuild' > $HOME/.rpmmacros

WORKDIR $HOME

# build grpcio, grpciotools from source...
FROM buildrpmbase as buildgrpcio

RUN dnf install -y git

ENV GRPC_VER v1.45.2

RUN git clone -b $GRPC_VER https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init

WORKDIR $HOME/grpc

COPY ./buildfiles/grpcio.spec $HOME/rpmbuild/SPECS
ENV SPEC=$HOME/rpmbuild/SPECS/grpcio.spec

RUN dnf builddep -y --spec $SPEC

ENV GRPC_PYTHON_BUILD_WITH_CYTHON=1

RUN cd /tmp && \
    ln -s ~/grpc grpcio-1.45.2 && \
    tar -czf $HOME/rpmbuild/SOURCES/grpcio-1.45.2.tar.gz grpcio-1.45.2 && \
    rpmbuild -ba $SPEC || \
    dnf builddep -y $HOME/rpmbuild/SRPMS/* && \
    rpmbuild -bb $SPEC

# build grpcio_tools

RUN cd ~/grpc/tools/distrib/python/grpcio_tools && \
    python3 ../make_grpcio_tools.py && \
    python3 setup.py bdist_rpm --binary-only --dist-dir $HOME/rpmbuild/RPMS/$(uname -i)/


# build app rpm
FROM buildrpmbase as buildrpm

COPY --from=buildgrpcio $HOME/rpmbuild/RPMS/ $HOME/rpmbuild/RPMS
RUN dnf install -y $HOME/rpmbuild/RPMS/$(uname -i)/*.rpm

COPY ./buildfiles/app.spec $HOME/rpmbuild/SPECS

ENV SPEC=$HOME/rpmbuild/SPECS/app.spec
RUN dnf builddep -y --spec $SPEC

COPY --from=ci /app/dist/ $HOME/rpmbuild/SOURCES/

RUN rpmbuild -ba $SPEC || \
    dnf builddep -y $HOME/rpmbuild/SRPMS/* && \
    rpmbuild -bb $SPEC


# install app
FROM fedora:37 as app

EXPOSE 50051

RUN --mount=type=bind,from=buildrpm,source=/root/rpmbuild/RPMS/,target=/tmp/rpms dnf -y install /tmp/rpms/$(uname -i)/*.rpm && \
    dnf clean all

WORKDIR /tmp
CMD ["python3 -m app"]
