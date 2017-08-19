# Dummy Windows Service

This shows how to run a dummy golang service under a dedicated `NT SERVICE\dummy` Windows account.

These types of accounts are automatically managed by Windows and do not need a password.

They also have a predictable SID in the form of `S-1-5-80-<SHA-1(uppercase(service name))>` (e.g. `S-1-5-80-908493856-1104173099-1205760238-637266923-2292294691`).

# Usage

[Download the binary from the releases page](https://github.com/rgl/dummy-windows-service/releases).

Install, run, and uninstall the service and respective account:

```powershell
./run.ps1
```

# Development

Install the dependencies:

```bash
go get -u github.com/kardianos/service
go get -u golang.org/x/sys/windows
```

Build:

```bash
make
```
