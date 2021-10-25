# -*- coding: utf-8 -*-
%ifos linux
%define _bindir /bin
%endif

Summary: __description__
Name: ku-__TOOLKIT__
Version: __TOOLKIT_VERSION__
Release: __TOOLKIT_RELEASE__
License: LGPL2
URL: __homepage__
Source0: http://www.kubiclabs.com/sources/ku-__TOOLKIT_____TOOLKIT_VERSION__-__drelease__.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
A small set of tools for projects development and management:
.
 - project directory structure maintenance
 - shell environment auto setup based on concept of 'current project'
 - debian packages build and repo maintenance utils/frontends

%prep
%setup -q

%build
make build

%check

%install
rm -rf ${RPM_BUILD_ROOT}
fakeroot make DESTDIR=$RPM_BUILD_ROOT install

%post

%preun

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root,-)
/

%changelog
* Sat Sep 18 2021 Lorenzo Canovi (KUBiC Labs, CH) <packager@kubiclabs.com>
- production release ku21.05
* Wed Apr 21 2021 KUBiC Labs (CH) <packager@kubiclabs.com>
- meta: package owner
  - mod: Allblue SA dismissed, now is KUBiC Labs only
  - mod: from now releases uses the scheme YY.mm[patchlevel], where patchlevel
  	   usually is a locase letter; releases YY.mm (w/out patchlevel) are
	   production ones

* Tue Dec 03 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- bin/jtcj
  - add: list mode (option --list), scans directories in $JTPATH env var, or
  	   ones used as arguments, and searches for projects; only the subdirs
	   on first levels are scanned; the output is a list (one per line) of
	   project names or, if --fullpath option is used, the full directory
	   path of each found project
- bin/jtconf, jtconf-functions.pl
  - fix: env defaults
  	   - HOME to /nonexistent
	   - LOGNAME to nobody
- bin/jtmkpath
  - fix: fails on undefined owner if relative path was used

* Wed Oct 30 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku19.06

* Mon Oct 28 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- lib/_jt_truncate_cwd.sh
  - mod: moved to package ku-base, renamed to /lib/ku-base/ku_truncate_cwd.sh
- jtcj
  - mod: replaced code snipped to set $PS1, to reflect changes in lib dir
- debian/control
  - mod: requires ku-base >= 1.2-19-9, due changes to ku_truncate_cwd.sh
- bin/jtmkpath
  - fix: wrong user:group used on missing directory in paths

* Sun Jun 30 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku19.04

* Fri Jun 28 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- jtcj
  - fix: $PRJBATCHMODE not exported to current environment
- jtreset
  - fix: removes $PRJBATCHMODE from env
  - add: saves and exports to env current project path and name, in $PRJ_OLD and
  	   $PRJ_OLDNAME vars
- jtscm-autosync
  - fix: conflict resolv fails on git repos when there are untracked files
  - fix: didn't stop on first stage (update) errors
  - mod: CMDVER, CMDSTR; improved some messages, cleaned code (removed bash-isms,
  	   changed all backticks with $() notation)

* Fri Apr 12 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku19.02

* Fri Apr 12 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- jtrepo-rebuild
  - add: gpg key signature, full creation of Packages, Release.gpg, InRelease files;
         packager name can be set in file $PRJ/etc/packager_name (default: packager);
         gpg key file name can be set in file $PRJ/etc/gpg_key_filename (default:
	   $PRJ/gpg/KEY.pgp)

* Sat Mar 02 2019 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku19.00

* Mon Jul 30 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- bin/jtwiki-updatepage
  - mod: pages are no more generated in foswiki format
- bin/jtdeb-make
  - add: -nc flag to avoid cleanup at end
- bin/jtdeb-rebuild
  - add: additional options after packagename are passed to dpkg-buildpackage
  - add: -nc flag to avoid cleanup at end (passed to jtdeb-make)
  - add: --nomove flag to keep .deb files inplace instead of moving them to
  	   final destination
  - mod: now uses dh_listpackages to obtain the correct list of contained packages
  	   instead of guessing based from package filename
  - mod: messages aestetical changes and minor bug fixes

* Tue Jun 12 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku0.10

* Tue Jun 12 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- jtinstall
  - fix: all modification tests fails on symlinked files; added --dereference
	   option to all 'stat' invocations
  - fix: improved modification tests to avoid useless commands invocations
  	   (chown and chgrp)
  - fix: standard signature vars and usage
- jtconf
  - fix: standard signature vars and usage
  - add: --flat option to produce dump in flat format (section embedded in
  	   variable name)

* Sun May 13 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku0.8

* Mon Mar 12 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- jtgit-ignore-update
  - new: command to add standard entries in current .gitignore project file
- jtnewprj
  - fix: standard CMD env vars
  - add: jtgit-ignore-update on git project setup
- jtcj
  - fix: $interactive_flag variable undefined, replaced with string '-i'
- jtdeb-rebuild, jtdeb-make, jtdeb-clean
  - fix: commands header vars (CMD*) as stadard
- jtdeb-rebuild
  - fix: now calls jdeb-clean for a *real* cleanup

* Fri Sep 14 2018 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- production release 1.1-ku0.6

* Wed Sep 13 2017 KUBiC Labs, Allblue SA (CH) <packager@kubiclabs.com>
- jtdeb-port
  - fix: fails to detect working source directory because don't uses version
  - mod: now always copy/extract to a tempdir, to speedup building, avoiding
  	   nfs delays
- jtdeb-cache

