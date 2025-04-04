#  FLAC - Free Lossless Audio Codec
#  Copyright (C) 2002-2009  Josh Coalson
#  Copyright (C) 2011-2025  Xiph.Org Foundation
#
#  This file is part the FLAC project.  FLAC is comprised of several
#  components distributed under different licenses.  The codec libraries
#  are distributed under Xiph.Org's BSD-like license (see the file
#  COPYING.Xiph in this distribution).  All other programs, libraries, and
#  plugins are distributed under the GPL (see COPYING.GPL).  The documentation
#  is distributed under the Gnu FDL (see COPYING.FDL).  Each file in the
#  FLAC distribution contains at the top the terms under which it may be
#  distributed.
#
#  Since this particular file is relevant to all components of FLAC,
#  it may be distributed under the Xiph.Org license, which is the least
#  restrictive of those mentioned above.  See the file COPYING.Xiph in this
#  distribution.

AUTOMAKE_OPTIONS = subdir-objects

AM_CPPFLAGS = -I$(top_builddir) -I$(srcdir)/include -I$(top_srcdir)/include

EXTRA_DIST = \
	README \
	getopt/CMakeLists.txt \
	grabbag/CMakeLists.txt \
	replaygain_analysis/CMakeLists.txt \
	replaygain_synthesis/CMakeLists.txt \
	utf8/CMakeLists.txt \
	utf8/charmaps.h \
	utf8/makemap.c \
	utf8/charset_test.c


noinst_LTLIBRARIES = \
	getopt/libgetopt.la \
	grabbag/libgrabbag.la \
	utf8/libutf8.la \
	$(libwin_utf8_io) \
	replaygain_analysis/libreplaygain_analysis.la \
	replaygain_synthesis/libreplaygain_synthesis.la


if OS_IS_WINDOWS
win_utf8_io_libwin_utf8_io_la_SOURCES =	win_utf8_io/win_utf8_io.c
libwin_utf8_io = win_utf8_io/libwin_utf8_io.la
else
win_utf8_io_libwin_utf8_io_la_SOURCES =
libwin_utf8_io =
endif

getopt_libgetopt_la_SOURCES = getopt/getopt.c getopt/getopt1.c

grabbag_libgrabbag_la_SOURCES = \
	grabbag/alloc.c \
	grabbag/cuesheet.c \
	grabbag/file.c \
	grabbag/picture.c \
	grabbag/replaygain.c \
	grabbag/seektable.c \
	grabbag/snprintf.c

utf8_libutf8_la_SOURCES = \
	utf8/charset.c \
	utf8/charset.h \
	utf8/iconvert.c \
	utf8/iconvert.h \
	utf8/utf8.c

replaygain_analysis_libreplaygain_analysis_la_SOURCES = replaygain_analysis/replaygain_analysis.c

replaygain_synthesis_libreplaygain_synthesis_la_CFLAGS = -I $(top_srcdir)/src/share/replaygain_synthesis/include
replaygain_synthesis_libreplaygain_synthesis_la_SOURCES = replaygain_synthesis/replaygain_synthesis.c
