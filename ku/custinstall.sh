echo -en "\n populate <D>$libdir/skel directory ... "

rm -rf $DESTDIR/$libdir/skel
cp -af skel $DESTDIR/$libdir/. || exit $?
chmod a+r -R $DESTDIR/$libdir/skel
find $DESTDIR/$libdir/skel -type d -exec chmod 775 {} \;

echo -e "ok\n"
