import std/[os, strutils, strformat, streams]
import yaml, yaml/style
import ./packageinfo,./linux

proc createScalableIconsDir(baseDir: string) =
  createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "scalable" / "appps")
  # icon.svg

proc createNonScalableIconsDir(baseDir: string) =
  createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "48x48" / "apps")
  # icon.png
  # in desktop file: Icon=/usr/share/icons/hicolor/48x48/apps/icon.png
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "16x16" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "32x32" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "256x256" / "apps")
  # createDir(baseDir / "usr" / "share" / "icons" / "hicolor" / "512x512" / "apps")

proc createAppImageTree*(baseDir: string) =
  ## https://docs.appimage.org/packaging-guide/manual.html#ref-manual
  ## https://docs.appimage.org/reference/appdir.html#root-icon
  # https://github.com/probonopd/linuxdeployqt#simplest-example
  createDir(baseDir / "usr" / "lib64")
  createLinuxTree(baseDir)

proc getAppRun*(pkgInfo: PackageInfo): string =
  result = fmt"""
  #!/bin/sh

  APPDIR=$(dirname "$(readlink -f "$0")")
  export PATH=$APPDIR/usr/bin:$PATH
  export LD_LIBRARY_PATH=$APPDIR/usr/lib:$APPDIR/usr/lib64:$LD_LIBRARY_PATH

  # Run the application binary
  $APPDIR/usr/bin/{pkgInfo.name} "$@"
  """.unindent

type
  AppInfo* = object
    id: string
    name: string
    icon: string
    version: string
    exec: string
    exec_args: string
  AppDir* = object
    app_info: AppInfo
  Recipe* = object
    version: int
    AppDir: AppDir

const AppImageBuilderConfName* = "AppImageBuilder.yml"

proc writeBuildConfig*(pkgInfo: PackageInfo, outDir: string) =
  var info = AppInfo()
  info.id = pkgInfo.name
  info.name = pkgInfo.name
  info.version = pkgInfo.version
  info.exec = "usr/bin/" & pkgInfo.name
  info.exec_args = "$@"
  var appDir = AppDir(app_info: info)
  var s = newFileStream(outDir / AppImageBuilderConfName, fmWrite)
  Dumper().dump(Recipe(version: 1, AppDir: appDir), s)
  s.close()
