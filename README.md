# Habitat package: sqlwebadmin

An ASP.NET 2.0 application for administering SQL Server databases. The application is downloaded from the Microsoft Codeplex Archive and was last updated in 2007. This package is ideal for demonstrating legacy applications with Habitat. It's ideally run against our `core/sqlserver2005` package.

## Running the demo

This will cover how to run this legacy demo in two ways:

1. Demoing in a single VM. This is the easiest and most straightforward way to demo the app since it can be done in any Windows Server VM environment like VirtualBox on a Mac or any cloud based VM. It also avoids some pain involved with installing the .Net 2.0 runtime in containers. However, this does lack some "wow factor" of seeing 2005 technology running is a container.

1. Demoing in Windows Containers. You will need to have either a Windows host with Docker installed or a AWS/Azure VM with a Server 2016 **with docker** image. There is a bit more work involved here but we will walk through everything in detail.

### Demo in a Windows VM

Make sure your VM is running Windows Server 2016 (4GB of Ram is advisable). Open a Powershell console and install Chocolatey and Habitat:

```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install habitat -y
```

