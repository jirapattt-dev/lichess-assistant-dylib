TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LichessAssistant

LichessAssistant_FILES = Tweak.m EngineBridge.m ArrowOverlay.m SettingsUI.m FloatingButton.m
LichessAssistant_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
LichessAssistant_FRAMEWORKS = UIKit QuartzCore Foundation
LichessAssistant_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
