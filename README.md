# Habitat package: sqlwebadmin

An ASP.NET 2.0 application for administering SQL Server databases. The application is downloaded from the Microsoft Codeplex Archive and was last updated in 2007. This package is ideal for demonstrating legacy applications with Habitat. It even declares a dependency on a COM binary (`core/sql-dmo`). It's ideally run against our [`core/sqlserver2005`](https://github.com/habitat-sh/core-plans/tree/master/sqlserver2005) package.


## Running the demo

This will cover how to run this legacy demo in two ways:

1. Demoing in a single VM. This is the easiest and most straightforward way to demo the app since it can be done in any Windows Server VM environment like VirtualBox on a Mac or any cloud based VM. It also avoids some pain involved with installing the .Net 2.0 runtime in containers. However, this does lack some "wow factor" of seeing 2005 technology running is a container.

1. Demoing in Windows Containers. You will need to have either a Windows host with Docker installed or a AWS/Azure VM with a Server 2016 **with docker** image. There is a bit more work involved here but we will walk through everything in detail.

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

Setup a local default origin and key by running `hab setup`

### Demo in a Windows VM (no Docker)

**Important**: For a smooth demo in front of an audience, make sure to run through the initial install and loading of services once before the live demo and then `unload` the services when everything is confirmed working. The first load takes MUCH longer than subsequent loads because of the .Net 2.0 and SQL Server installation. Susequent loads will already have these in place and will be much faster.

Enter a local Habitat Studio and load `core/sqlserver2005`:

```
hab studio enter -w
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

For some reason, installing certain Windows features inside of a container (like the .Net 2.0 runtime) will not download on demand features from Windows Update like they do locally. So you will need to get the feature source files and mount them to the container. Download an Evaluation Windows Server 2016 ISO file by browsing to `https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2016` and choosing an English ISO file. Once that is downloaded, Mount the ISO and copy the .Net 2.0 runtime on demand feature sources to your local disk:


```
Mount-DiskImage -ImagePath 'C:\Users\Administrator\Downloads\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO'
mkdir c:\sxs
Copy-Item d:\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab c:\sxs
```

Export the `core/sqlserver2005` package to a docker image:

```
hab pkg export docker core/sqlserver2005
```

Run the SQL Server 2005 image:

```
$env:HAB_SQLSERVER2005="{`"netfx3_source`":`"c:/sxs`",`"svc_account`":`"NT AUTHORITY\\SYSTEM`"}"
docker run --memory 2gb -e HAB_SQLSERVER2005 --volume c:/sxs:c:/sxs -it core/sqlserver2005
```

The above will spawn a container and ensure that the `init` hook finds the offline source for the .Net 2.0 runtime that it will need in order to install SQL Server 2005. It also makes sure that SQL Server runs under the `SYSTEM` account necessary in many container scenarios. After you see `sqlserver2005.default hook[post-run]:(HK): 1> 2> 3> 4> 5> 6> Application user setup complete`, kill the container with `ctrl+c`.

We can vastly improve startup time of `core/sqlserver2005` containers if SQL Server is already installed into the container. Now that we have a stopped container with SQL Server installed, let's `commit` that container to a new image that we can run in subsequent demos resulting in a faster container startup:

```
docker commit $(docker ps -aql) sqlserver2005
```

Build our sqlwebadmin package (make sure you are still in `c:\sqlwebadmin`):

```
hab pkg build . -w
```

Export our `sqlwebadmin` hart to a docker image:

```
hab pkg export docker <path to HART file>
```

Now lets create a container from that image and just like we did with `sqlserver2005` we will mount our .Net 2.0 source:

```
docker run -e "HAB_SQLWEBADMIN=netfx3_source='c:/sxs'" --volume c:/sxs:c:/sxs -it <your origin>/sqlwebadmin
```

Once the console emits: `sqlwebadmin.default(O): sqlwebadmin is running`, kill the container with ctrl+c.

Just like we commited our `sqlserver2005` container to capture a new image with everything we need installed, we will do the same with this web application which also had to install the .Net 2.0 runtime and IIS features. That will make demoing the application in a container much faster:

```
docker commit $(docker ps -aql) sqlwebadmin
```

OK! Now lets bring these two containers together into a ring:

```
$sql = docker run -d --memory 2gb sqlserver2005
$ip = docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $sql
docker run -it sqlwebadmin --bind database:sqlserver2005.default --peer $ip
```

Grab the IP address of the `sqlwebadmin` container:

```
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aql)
```

Browsing to `http://<CONTAINER_IP>:8099/databases.aspx` should bring up the application.
