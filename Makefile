PREFIX ?= $(HOME)

.PHONY: install uninstall

install:
	swift build -c release
	install -d $(PREFIX)/bin
	install .build/release/wakeup $(PREFIX)/bin/wakeup
	$(PREFIX)/bin/wakeup --install

uninstall:
	wakeup --uninstall || true
	rm -f $(PREFIX)/bin/wakeup
