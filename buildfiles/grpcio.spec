%define name grpcio
%define modname grpc
%define version 1.45.2
%define unmangled_version 1.45.2
%define release 1
%define summary HTTP/2-based RPC framework
%define package_name python3-%{name}

Summary: %{summary}
Name: %{name}
Version: %{version}
Release: %{release}
Source0: %{name}-%{unmangled_version}.tar.gz
License: Apache License 2.0
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
Vendor: The gRPC Authors <grpc-io@googlegroups.com>
Url: https://grpc.io

BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3dist(wheel)
BuildRequires:  python3-Cython
BuildRequires:  gcc
BuildRequires:  gcc-c++

%global _description %{expand:
gRPC Python
Package for gRPC Python.

full readme https://github.com/grpc/grpc/tree/master/src/python/grpcio
}

%description %_description


%package -n %{package_name}
Summary: %{summary}
%description -n %{package_name} %_description


%prep
%autosetup -p1 -n %{name}-%{unmangled_version}

%generate_buildrequires
%pyproject_buildrequires


%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files %{modname}

%files -n %{package_name} -f %{pyproject_files}

%changelog
