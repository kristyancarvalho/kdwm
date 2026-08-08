# Maintainer: Thule <vincenzo.frascino@proton.me>
# Contributor: Neptune <neptune650@proton.me>
# Contributor: Sergej Pupykin <pupykin.s+arch@gmail.com>
# Contributor: Dag Odenhall <dag.odenhall@gmail.com>
# Contributor: Grigorios Bouzakis <grbzks@gmail.com>

pkgname=dwm
pkgver=6.8
pkgrel=6
pkgdesc="A dynamic window manager for X"
url="https://dwm.suckless.org"
arch=('i686' 'x86_64' 'arm' 'armv7h' 'armv6h' 'aarch64')
license=('MIT')
options=(zipman)
depends=('libx11' 'libxinerama' 'libxft' 'freetype2')
install=dwm.install
source=(https://dl.suckless.org/dwm/dwm-$pkgver.tar.gz)
sha256sums=('bcf540589ad174d4073f4efa658828411e2f5ba63196cfaf6b71363700f590b7')

prepare() {
  cd "$srcdir/$pkgname-$pkgver"
  patch -Np1 -i "$startdir/dwm/patches/0001-gaps-and-xresources-reload.diff"
  patch -Np1 -i "$startdir/dwm/patches/0002-ignore-desktop-panel.diff"
  patch -Np1 -i "$startdir/dwm/patches/0003-clean-status-and-restart.diff"
  cp -fv "$startdir/dwm/config.h" config.h
}

build() {
  cd "$srcdir/$pkgname-$pkgver"
  make X11INC=/usr/include/X11 X11LIB=/usr/lib/X11 FREETYPEINC=/usr/include/freetype2
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  make PREFIX=/usr DESTDIR="$pkgdir" install
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README "$pkgdir/usr/share/doc/$pkgname/README"
  install -Dm644 "$startdir/system/dwm.desktop" "$pkgdir/usr/share/xsessions/dwm.desktop"
}
