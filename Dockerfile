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
    python3 setup.py bdist_rpm --binary-only --dist-dir $HOME/rpmbuild/RPMS/x86_64/


# build app rpm
FROM buildrpmbase as buildrpm

COPY --from=buildgrpcio $HOME/rpmbuild/RPMS/x86_64/ $HOME/rpmbuild/RPMS/x86_64/
RUN dnf install -y $HOME/rpmbuild/RPMS/x86_64/*.rpm

COPY ./buildfiles/app.spec $HOME/rpmbuild/SPECS

ENV SPEC=$HOME/rpmbuild/SPECS/app.spec
RUN dnf builddep -y --spec $SPEC

COPY --from=ci /app/dist/ $HOME/rpmbuild/SOURCES/

RUN rpmbuild -ba $SPEC || \
    dnf builddep -y $HOME/rpmbuild/SRPMS/* && \
    rpmbuild -bb $SPEC


# install app
FROM fedora:37 as app

COPY --from=buildrpm /root/rpmbuild/RPMS/x86_64/python3-app-* /tmp/
COPY --from=buildrpm /root/rpmbuild/RPMS/x86_64/python3-grpcio-* /tmp/

VOLUME ["/sys/fs/cgroup"]
CMD ["/sbin/init"]

EXPOSE 50051


RUN dnf -y install systemd /tmp/*.rpm && dnf clean all && \
    (cd /lib/systemd/system/sysinit.target.wants/ ; for i in * ; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i ; done) ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ;\
    rm -f /etc/systemd/system/*.wants/* ;\
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ;\
    rm -f /lib/systemd/system/anaconda.target.wants/* && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/* && \
    systemctl enable app

STOPSIGNAL SIGRTMIN+3

