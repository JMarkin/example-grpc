Name:           app
Version:        1.0.0
Release:        1%{?dist}
Summary:        Example Python app

License:        MIT
URL:            https://github.com/jmarkin/app
Source:         %{url}/archive/v%{version}/app-%{version}.tar.gz

BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3dist(poetry-core)
BuildRequires:  python3dist(toml)
BuildRequires:  grpcio-tools
BuildRequires:  systemd-rpm-macros

%global _description %{expand:
    Какое-то описание
}

%description %_description

%package -n python3-app
Summary:        %{summary}

%description -n python3-app %_description


%prep
%autosetup -p1 -n app-%{version}

%generate_buildrequires
%pyproject_buildrequires

%global debug_package %{nil}

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service


%build
find . -name *.proto -exec python3 -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=.  {} \;
%pyproject_wheel


%install
%pyproject_install
%pyproject_save_files app protofiles

mkdir -p %{buildroot}/etc/systemd/system/
install %{buildroot}%{python3_sitelib}/buildfiles/%{name}.service %{buildroot}/etc/systemd/system/%{name}.service
rm %{buildroot}%{python3_sitelib}/buildfiles/%{name}.service

%check
%pyproject_check_import


%files -n python3-app -f %{pyproject_files}
/etc/systemd/system/%{name}.service


%changelog
