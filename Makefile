THEOS_DEVICE_IP = 192.168.1.132

ARCHS = armv7 armv7s arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapTapTime

TapTapTime_FILES = Tweak.x
TapTapTime_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
