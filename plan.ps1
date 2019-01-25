$pkg_name="sqlwebadmin"
$pkg_origin="mwrock"
$pkg_version="0.1.0"
$pkg_maintainer="Matt Wrock"
$pkg_license=@('MS-PL')
$pkg_description="Web based SQL Server Administrator"
$pkg_deps=@("core/dsc-core", "core/sql-dmo", "core/iis-webserverrole", "core/dotnet-35sp1-runtime", "core/iis-aspnet35")
$pkg_source="https://codeplexarchive.blob.core.windows.net/archive/projects/SqlWebAdmin/SqlWebAdmin.zip"
$pkg_shasum="ea888026a989951a62e5ac0f4f9819ee0662f5e4d99edeb4896a628430bb9075"
$pkg_upstream_url="https://archive.codeplex.com/?p=sqlwebadmin"

$pkg_binds_optional=@{
  "database"="instance username password port"
}

function Invoke-Unpack {
  Invoke-DefaultUnpack

  $lastRelease = (Get-ChildItem "$HAB_CACHE_SRC_PATH/$pkg_dirname/releases" -Directory)[-1]
  $release = (Get-ChildItem $lastRelease.FullName)[0]
  Expand-Archive $release.FullName -DestinationPath "$HAB_CACHE_SRC_PATH/$pkg_dirname/app"
}

function Invoke-Install {
    Copy-Item "$HAB_CACHE_SRC_PATH/$pkg_dirname/app/sqlwebadmin/sqlwebadmin" $pkg_prefix -recurse
    Remove-Item $pkg_prefix/sqlwebadmin/Web.config
    Remove-Item $pkg_prefix/sqlwebadmin/App_Code/Global.asax.cs
}
