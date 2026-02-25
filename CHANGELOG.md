## 0.1.1

- Fixed Windows compatibility for CLI detection
- Fixed command execution to use `cmd.exe` on Windows instead of `bash`
- Fixed `where` command usage for executable path resolution on Windows
- Fixed FVM Flutter detection when system Flutter is not installed
- Added `isViaFvm` flag to properly track Flutter source
- Fixed runner selection to use `fvm flutter` command when Flutter is only available via FVM
- Fixed `cd /d` usage on Windows for directory changes across drives
- Fixed FVM 4.x active version detection (● marker)

## 0.1.0

- Initial version.
