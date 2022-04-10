Name:           app
Version:        1.0.0
Release:        1%{?dist}
Summary:        Example Python app

License:        MIT
URL:            https://scm.x5.ru/app
Source:         %{url}/archive/v%{version}/app-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3dist(poetry-core)
BuildRequires:  python3dist(toml)
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

%post
%systemd_user_post %{name}.service

%preun
%systemd_user_preun %{name}.service

%build
%pyproject_wheel


%install
%pyproject_install
mv /usr/lib/python3.10/site-packages/buildfiles/%{name}.service %{_sysconfdir}/%{name}.service
rm -r /usr/lib/python3.10/site-packages/buildfiles

%pyproject_save_files app protofiles

%check
%pyproject_check_import


%files -n python3-app -f %{pyproject_files}
%{_sysconfdir}/%{name}.service


%changelog
