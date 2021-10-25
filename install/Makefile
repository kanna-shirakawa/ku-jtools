# based on KU packages template 1.4 (2021-10-25)

# default, preprocess control files
#
controls:
	ku/install.sh make_controls

build:

install: build
	DESTDIR=$(DESTDIR) ku/install.sh

clean:
	rm -rf $(DESTDIR)

doc:

mrproper: clean clean_controls

clean_controls:
	for file in `ls debian.in 2>/dev/null`; do rm -f debian/$$file; done
	[ -f ku/history ] && rm -f debian.in/changelog

# a clean debian package
debianize:
	$(MAKE) mrproper
	$(MAKE) controls
	jtdeb-clean
