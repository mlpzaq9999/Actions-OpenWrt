#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=koolproxy
PKG_VERSION:=3.8.5
PKG_RELEASE:=1

ifeq ($(ARCH),i386)
	PKG_ARCH:=386
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),mips)
	PKG_ARCH:=mips
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsel
endif

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=KoolProxy
	DEPENDS:=@(i386||x86_64||arm||aarch64||mipsel||mips)
	URL:=https://github.com/user1121114685/koolproxyR
endef

define Package/$(PKG_NAME)/description
	This package for koolproxy.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/koolproxy
	$(INSTALL_BIN) ./files/$(PKG_ARCH)/koolproxy $(1)/usr/share/koolproxy/koolproxy
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
