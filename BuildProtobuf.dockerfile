FROM fedora:35

RUN dnf install -y rpmdevtools make automake gcc gcc-c++ cmake autoconf libtool python3-setuptools python-devel git
RUN git clone -b v3.20.0 https://github.com/protocolbuffers/protobuf
WORKDIR /protobuf
RUN ./autogen.sh
RUN ./configure
RUN make -j$(nproc)
RUN echo '%debug_package %{nil}' > /etc/rpm/macros
WORKDIR /protobuf/python
RUN echo "__version__='3.20.0'" > google/protobuf/__init__.py
RUN python3 setup.py build --cpp_implementation
RUN python3 setup.py bdist_rpm --cpp_implementation -d /tmp/
RUN ls /tmp
