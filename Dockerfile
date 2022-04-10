FROM python:3.9-slim as ci

RUN pip install poetry && mkdir /app
WORKDIR /app

COPY ./poetry.lock .
COPY ./pyproject.toml .

RUN poetry install --no-root

COPY . /app

RUN poetry run poe protogen && poetry build -f sdist

FROM fedora:37 as buildgrpcio

RUN dnf install -y git rpmdevtools python3-devel make automake gcc gcc-c++
RUN python3 -m pip install -U pip setuptools Cython


# build from soruce grpcio...
# old rpm on repository
ENV GRPC_VER v1.45.2

RUN cd /tmp && \
    git clone -b $GRPC_VER https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init


RUN cd /tmp/grpc && \
    python3 setup.py bdist_rpm && \
    cd tools/distrib/python/grpcio_tools && \
    python3 ../make_grpcio_tools.py && \
    python3 setup.py bdist_rpm



FROM fedora:37 as buildrpm

RUN dnf install -y rpmdevtools 'dnf-command(builddep)'


ENV HOME /root/
RUN mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo '%_topdir %{getenv:HOME}/rpmbuild' > $HOME/.rpmmacros

WORKDIR $HOME

COPY ./buildfiles/app.spec $HOME/rpmbuild/SPECS

ENV SPEC=$HOME/rpmbuild/SPECS/app.spec

RUN dnf builddep -y --spec $SPEC

COPY --from=buildgrpcio /tmp/grpc/python_build/bdist.linux-x86_64/rpm/RPMS/* $HOME/rpmbuild/RPMS/

RUN dnf install -y $HOME/rpmbuild/RPMS/*.rpm

COPY --from=ci /app/dist/ $HOME/rpmbuild/SOURCES/

RUN rpmbuild -ba $SPEC || \
    dnf builddep -y $HOME/rpmbuild/SRPMS/* && \
    rpmbuild -bb $SPEC


FROM fedora:37 as app

COPY --from=buildrpm /root/rpmbuild/RPMS/ /tmp/

RUN dnf install -y systemd-units /tmp/noarch/*.rpm

EXPOSE 50051
CMD [ "/sbin/init" ]

STOPSIGNAL SIGRTMIN+3
