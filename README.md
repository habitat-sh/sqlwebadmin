# Habitat package: sqlwebadmin

An ASP.NET 2.0 application for administering SQL Server databases. The application is downloaded from the Microsoft Codeplex Archive and was last updated in 2007. This package is ideal for demonstrating legacy applications with Habitat. It even declares a dependency on a COM binary (`core/sql-dmo`). It's ideally run against our [`core/sqlserver2005`](https://github.com/habitat-sh/core-plans/tree/master/sqlserver2005) package.


## Running the demo

This will cover how to run this legacy demo in two ways:

1. Demoing in a single VM. This is the easiest and most straightforward way to demo the app since it can be done in any Windows Server VM environment like VirtualBox on a Mac or any cloud based VM. However, this does lack some "wow factor" of seeing 2005 technology running is a container.

1. Demoing in Windows Containers. You will need to have either a Windows host with Docker installed or a AWS/Azure VM with a Server 2016 **with docker** image.

### Setup steps to run in any environment

Make sure your VM is running Windows Server 2016 (4GB of Ram is advisable). Open a Powershell console and install Chocolatey, git, chrome and Habitat:

```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install habitat -y
choco install git -y
choco install googlechrome -y
```

Close and reopen your Powershell console to refresh the changed `PATH`.

Navigate to `c:\`. The SQL Server installer can fail if the install path is too long. Entering into a local studio at `c:\users\administrators\sqlwebadmin` will result in a much longer install path than entering from `c:\sqlwebadmin`. Clone this repo and `cd` into the top level directory:

```
cd c:\
git clone https://github.com/habitat-sh/sqlwebadmin
cd sqlwebadmin
```

Setup a local default origin and key by running `hab setup` then enable the `INSTALL_HOOK` feature:

```
$env:HAB_FEAT_INSTALL_HOOK=$true
```

This plan takes advantage of several dependencies that use this feature to run an `install` hook when the dependency is installed for things like enabling windows features and registering a COM component.

### Demo in a Windows VM (no Docker)

**Important**: For a smooth demo in front of an audience, make sure to run through the initial install and loading of services once before the live demo and then `unload` the services when everything is confirmed working. The first load takes MUCH longer than subsequent loads because of the .Net 2.0 and SQL Server installation. Susequent loads will already have these in place and will be much faster.

Enter a local Habitat Studio and load `core/sqlserver2005`:

```
hab studio enter
hab svc load core/sqlserver2005
```

This will take several minutes to load since it is downloading and installing the .Net 2.0 runtime and installing SQL Server 2005. While its loading, build this plan:

```
build
```

Now we need to wait for SQL Server's `post-run` hook to complete. View the Supervisor output with `Get-SupervisorLog` and wait for the message:

```
sqlserver2005.default hook[post-run]:(HK): 1> 2> 3> 4> 5> 6> Application user setup complete
```

Now load `<your_origin>/sqlwebadmin`:

```
hab svc load <your_origin>/sqlwebadmin --bind database:sqlserver2005.default
```

In the Supervisor log wait for:

```
sqlwebadmin.default(O): sqlwebadmin is running
```

The website should now be accessible. Browse to `http://localhost:8099/databases.aspx`. Enjoy administering SQL Server 2005!

### Demo with containers

**Important**: You must have [Docker for Windows](https://www.docker.com/docker-windows) running in Windows container mode. If you have launched an AWS or Azure image with Docker preinstalled, you should be good to go but make sure the instance has at least 50GB of disk space.

Export the `core/sqlserver2005` package to a docker image:

```
$env:HAB_SQLSERVER2005="{`"svc_account`":`"NT AUTHORITY\\SYSTEM`"}"
hab pkg export docker --memory 2gb core/sqlserver2005
```

The first line above will make sure that the SQL Server install sets the `svc_account` to the `SYSTEM` account instead of the default `NETWORK SERVICE` account which is advisable in a container environment.

Build our sqlwebadmin package (make sure you are still in `c:\sqlwebadmin`):

```
hab pkg build .
```

Export our `sqlwebadmin` hart to a docker image:

```
hab pkg export docker --memory 2gb <path to HART file>
```

OK! Now lets bring these two containers together into a ring:

```
$sql = docker run -d --memory 2gb core/sqlserver2005
$ip = docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $sql
docker run -it <your_origin>/sqlwebadmin --bind database:sqlserver2005.default --peer $ip
```

Alternatively you can use Docker Compose along with the provided `docker-compose.yml` to bring up the containers:

```
docker-compose up
```

Grab the IP address of the `sqlwebadmin` container:

```
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aql)
```

Browsing to `http://<CONTAINER_IP>:8099/databases.aspx` should bring up the application.
