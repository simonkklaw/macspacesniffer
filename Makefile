BINARY   = .build/release/MacSpaceSniffer
APP      = MacSpaceSniffer.app
ICON_SRC = make_icon.swift
ICON     = Resources/AppIcon.icns

build:
	swift build -c release

icon: $(ICON)

$(ICON): $(ICON_SRC)
	swift $(ICON_SRC)

bundle: build $(ICON)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	mkdir -p $(APP)/Contents/Resources
	cp $(BINARY) $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/
	cp $(ICON) $(APP)/Contents/Resources/
	codesign --deep --sign - $(APP)

dmg: bundle
	bash make_dmg.sh $(APP)

run-bundle: bundle
	open $(APP)

debug:
	swift build
	.build/debug/MacSpaceSniffer

test:
	swift test

clean:
	swift package clean
	rm -rf $(APP) MacSpaceSniffer.dmg MacSpaceSniffer-scratch.dmg
