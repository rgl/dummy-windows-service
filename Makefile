dist: dummy-windows-service.zip

build: dummy-windows-service.exe

dummy-windows-service.exe: go.* *.go
	GOOS=windows GOARCH=amd64 go build -v -o $@ -ldflags="-s -w"

dummy-windows-service.zip: dummy-windows-service.exe run.ps1
	rm -f $@
	zip $@ $^

clean:
	rm -rf dummy-windows-service*

.PHONY: dist build clean
