# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils multilib qmake-utils autotools git-r3 desktop cmake-multilib

DESCRIPTION="A Qt program for syncing your MEGA account in your PC. This is the official app."
HOMEPAGE="http://mega.co.nz"
RTAG="_Linux"
if [[ ${PV} == *9999* ]];then
	EGIT_REPO_URI="https://github.com/meganz/MEGAsync"
	KEYWORDS=""
	EGIT_SUBMODULES=( '*' )
else
	EGIT_REPO_URI="https://github.com/meganz/MEGAsync"
	EGIT_COMMIT="v${PV}.0${RTAG}"
	EGIT_SUBMODULES=( '*' )
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="EULA"
LICENSE_URL="https://raw.githubusercontent.com/meganz/MEGAsync/master/LICENCE.md"
SLOT="0"
IUSE="dolphin nautilus thunar +cryptopp +sqlite +zlib +curl freeimage readline examples threads java php python gnome"

DEPEND="
	dev-lang/swig
	app-doc/doxygen
	media-libs/libmediainfo
	media-libs/libraw
	dev-qt/qtcore:5
	dev-qt/linguist-tools
	dev-qt/qtwidgets:5
	dev-qt/qtgui:5
	dev-qt/qtconcurrent:5
	dev-qt/qtnetwork:5
	dev-qt/qtdbus:5
	dev-qt/qtimageformats:5
	dev-qt/qtsvg:5
	dev-qt/qtx11extras:5
	"
RDEPEND="
		x11-themes/hicolor-icon-theme
		dev-libs/openssl
		dev-libs/libgcrypt
		media-libs/libpng
		net-dns/c-ares
		cryptopp? ( dev-libs/crypto++ )
		app-arch/xz-utils
		dev-libs/libuv
		sqlite? ( dev-db/sqlite:3 )
		dev-libs/libsodium
		zlib? ( sys-libs/zlib )
		curl? ( net-misc/curl[ssl,curl_ssl_openssl] )
		freeimage? ( media-libs/freeimage )
		readline? ( sys-libs/readline:0 )
		dolphin? ( kde-apps/dolphin )
		nautilus? ( >=gnome-base/nautilus-3 )
		thunar? ( xfce-base/thunar )
		"

PATCHES=( )

if [[ ${PV} != *9999* ]];then
	src_prepare(){
		if [ -e "${FILESDIR}/MEGAsync-${PV}.0_Linux.patch" ]; then
			EPATCH_OPTS="-p0" epatch "${FILESDIR}/MEGAsync-${PV}.0_Linux.patch"
		fi
		if [ ! -z ${PATCHES} ]; then
			epatch ${PATCHES}
		fi
		if use gnome; then
			if [ -e "${FILESDIR}${P}-gnome.patch" ]; then
				epatch "${FILESDIR}/${P}-gnome.patch"
			fi
		fi
		eapply_user
		cd src/MEGASync/mega
		eautoreconf
	}
fi

src_configure(){
	cd "${S}"/src/MEGASync/mega
	econf \
		"--disable-silent-rules" \
		"--disable-curl-checks" \
		"--disable-megaapi" \
		$(use_with zlib) \
		$(use_with sqlite) \
		$(use_with cryptopp) \
		"--with-cares" \
		$(use_with curl) \
		"--without-termcap" \
		$(use_enable threads posix-threads) \
		"--with-sodium" \
		$(use_with freeimage) \
		$(use_with readline) \
		$(use_enable examples) \
		$(use_enable java) \
		$(use_enable php) \
		$(use_enable python) \
		"--enable-chat" \
		"--enable-gcc-hardening"
	cd ../..
	local myeqmakeargs=(
		MEGA.pro
		CONFIG+="release"
	)
	grep --color=no -rl 'videoStream->s' | xargs sed -i 's/videoStream->s/\/\/videoStream->s/g'
	eqmake5 ${myeqmakeargs[@]}
	use dolphin && cmake-utils_src_configure
	$(qt5_get_bindir)/lrelease MEGASync/MEGASync.pro
}

src_compile(){
	emake -C src INSTALL_ROOT="${D}" || die
	use dolphin && cmake-utils_src_compile
}

src_install(){
	use dolphin && cmake-utils_src_install
	local DOCS=( CREDITS.md README.md )
	einstalldocs
	insinto usr/share/licenses/${PN}
	doins LICENCE.md installer/terms.txt
	cd src/MEGASync
	dobin ${PN}
	cd platform/linux/data
	insinto usr/share/applications
	doins ${PN}.desktop
	cd icons/hicolor
	for size in 16x16 32x32 48x48 128x128 256x256;do
		doicon -s $size $size/apps/mega.png
	done
}
