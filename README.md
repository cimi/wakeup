# wakeup

A macOS utility that runs a script when your Mac wakes from sleep.

When running, `wakeup` listens for `NSWorkspace.didWakeNotification` and executes `~/.wakeup` on each wake event.

## Install

```sh
make install
```

This builds a release binary, copies it to `~/bin/wakeup`, and registers a LaunchAgent (`com.github.wakeup`) so it starts automatically on login.

To install to a different prefix:

```sh
make install PREFIX=/usr/local
```

## Setup

Create an executable script at `~/.wakeup`:

```sh
touch ~/.wakeup
chmod +x ~/.wakeup
```

The script runs synchronously — stdout and stderr go to `~/Library/Logs/wakeup.log` and `~/Library/Logs/wakeup.error.log`.

## Uninstall

```sh
make uninstall
```

This unloads the LaunchAgent and removes the binary.

## Requirements

- macOS
- Swift 5.9+
