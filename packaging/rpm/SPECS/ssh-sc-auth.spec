# This instructs rpmbuild to ignore unpackaged files
%define _unpackaged_files_terminate_build 0

Name:           ssh-sc-auth
Version:        1.0.0
Release:        1%{?dist}
Summary:        SSH SmartCard Authentication
Vendor:         Foolean.org
Packager:       Foolean.org
Group:          Applications/Internet
License:        GPLv3
URL:            https://github.com/foolean/ssh-sc-auth
Source:         https://github.com/foolean/ssh-sc-auth
%description
ssh-sc-auth is a smart-card authentication handler for use with the
AuthorizedKeysCommand feature of SSH.  The program will return dynamic
authorized_keys entries for the user, based on either sshPublicKey or
SSL certificates stored in a remote LDAP server

BuildRequires: perl-Module-Build 
BuildRequires: perl-Test-Perl-Critic
BuildRequires: perl-Archive-Tar

%prep

%build
cd %{_topdir}/SOURCES
perl Build.PL
./Build
./Build test
./Build install --destdir "%{buildroot}"

%clean

%files
%defattr(0440,root,root,0750)
%config(noreplace) %attr(0640,root,root) %{_prefix}/ssh-sc/etc/ssh-sc-auth.conf
%attr(0750,root,root) %{_prefix}/ssh-sc/sbin/ssh-sc-auth
%attr(0644,root,root) %{_prefix}/ssh-sc/man/man1/ssh-sc-auth.1
%attr(0644,root,root) %{_prefix}/ssh-sc/man/man5/ssh-sc-auth.conf.5
%doc %attr(0644,root,root) %{_prefix}/ssh-sc/doc/README.dist
%doc %attr(0644,root,root) %{_prefix}/ssh-sc/doc/selinux/ssh-sc-auth.te
%doc %attr(0644,root,root) %{_prefix}/ssh-sc/etc/ssl

%post
useradd -d %{_prefix}/ssh-sc -s /usr/sbin/nologin -c "SSH AuthorizedKeysCommandUser" -r ssh-auth

chown -R root.ssh-auth %{_prefix}/ssh-sc
find %{_prefix}/ssh-sc -type d -exec chmod 750 {} \;
find %{_prefix}/ssh-sc -type f -exec chmod 640 {} \;
chmod 750 %{_prefix}/ssh-sc/sbin/*

%postun
USER_EXISTS=$(getent passwd ssh-auth)
if [ "${USER_EXISTS}" != "" ]
then
    userdel ssh-auth
fi
rm -rf %{_prefix}/ssh-sc

%changelog
* Wed Oct 18 2017 Bennett Samowich <bennett@foolean.org>
- Initial creation of .spec file
