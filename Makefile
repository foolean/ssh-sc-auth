# Makefile for package building

package = ssh-sc
version := $(shell grep "^our.*\$VERSION" Build.PL | cut -f2 -d\')

distpkg = $(package)-$(version)
disttar = $(distpkg).tar.gz

dist:
	perl Build.PL
	./Build
	./Build dist

debian-package:
	debian/rules build && debian/rules binary;

rpm_topdir=`cd . && pwd`/packaging/rpm
rpm-package: dist
	cd $(rpm_topdir);                                                 \
	mkdir -p BUILD RPMS SOURCES SRPMS;                                \
	cd BUILD;                                                         \
	ln -sf ../../../$(distpkg).tar.gz;                                \
	cd ..;                                                            \
	/bin/tar -C "SOURCES" --strip-components=1                        \
		-xzf "BUILD/$(disttar)";                                  \
	mkdir "SOURCES/ssh-sc-auth";                                      \
	rpmbuild --define "_topdir `cd . && pwd`" --define "_prefix /opt" \
		--buildroot="`cd . && pwd`/BUILDROOT/$(distpkg)"          \
		-ba SPECS/ssh-sc-auth.spec &&                             \
		echo "Package successfully built in `pwd`/RPMS." &&       \
		rm -f BUILD/$(disttar) $(disttar); 

deb: debian-package
	true

rpm: rpm-package
	true

distclean:
	rm -rf "$(rpm_topdir)/BUILD"
	rm -rf "$(rpm_topdir)/BUILDROOT"
	rm -rf "$(rpm_topdir)/RPMS"
	rm -rf "$(rpm_topdir)/SOURCES"
	rm -rf "$(rpm_topdir)/SRPMS"
	rm -f "$(distpkg).tar.gz"
	./Build distclean	
