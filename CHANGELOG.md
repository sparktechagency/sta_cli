## 0.1.3

- Fixed Windows path quoting issue causing `FileSystemException` (errno 123)
- Added auto-increment folder naming when directory already exists (name_1, name_2, etc.)
- Improved directory existence handling with overwrite confirmation

## 0.1.2

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
