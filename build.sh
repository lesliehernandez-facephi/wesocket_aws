#!/bin/bash
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"
go build -o main main.go
 
go.exe install github.com/aws/aws-lambda-go/cmd/build-lambda-zip@latest

~\Go\Bin\build-lambda-zip.exe -o terraform/main.zip main 