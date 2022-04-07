FROM python:3.9-slim as pbuild

RUN pip install poetry && mkdir /app
WORKDIR /app
COPY . /app

RUN poetry build -f sdist

FROM fedora:35 as build

RUN dnf install -y rpmdevtools

ENV HOME /root/
RUN mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo '%_topdir %{getenv:HOME}/rpmbuild' > $HOME/.rpmmacros

WORKDIR $HOME

COPY ./build/app.spec $HOME/rpmbuild/SPECS
COPY --from=pbuild /app/dist/ $HOME/rpmbuild/SOURCES/

RUN rpmbuild -bs $HOME/rpmbuild/SPECS/app.spec

# RUN dnf install -y \
#     $(rpmspec -P $HOME/rpmbuild/SPECS/app.spec | grep BuildRequires | awk '{print $2}' | xargs)  && \
#     rpmbuild -bb $HOME/rpmbuild/SPECS/app.spec


# FROM fedora:35 as app
#
# COPY --from=build /home/rpmbuild/rpmbuild/SRPMS/ /tmp
#
# EXPOSE 50051
# CMD [ "/sbin/init" ]
#
# STOPSIGNAL SIGRTMIN+3
