import std/[os, strformat, strutils, osproc, sequtils]
import ./packageinfo
import parseini

proc isExecutable(path: string): bool =
  let p = getFilePermissions(path)
  result = fpUserExec in p and fpGroupExec in p and fpOthersExec in p

proc findExes*(baseDir: string): seq[string] =
  toSeq(walkDirRec(baseDir)).filterIt(it.isExecutable)

proc collectDeps*(exes:seq[string]): string =
  var outputs = newSeq[string]()
  const Prefix = "shlibs:Depends=".len
  for file in exes:
    let cmd = fmt"dpkg-shlibdeps -e{file} -O"
    debugEcho cmd
    let (output, exitCode) = execCmdEx(cmd)
    debugEcho output
    if not exitCode == 0:
      quit(output)
    else:
      outputs.add output.substr(Prefix).strip()
  result = outputs.join(",")

proc getDirectorySize*(directory: string): int =
  ## get directory size in bytes
  var totalSize = 0

  for file in walkDirRec(directory):
    totalSize += getFileSize(file)

  return totalSize

proc getControlBasic*(pkgInfo: PackageInfo): string =
  ## size in kb
  let arch = hostCPU
  result = fmt"""
  Source: {pkgInfo.name}
  Package: {pkgInfo.name}
  Version: {pkgInfo.version}
  Description: {pkgInfo.desc}
  Architecture: {arch}
  Maintainer: YOUR NAME <EMAIL>
  """.unindent

proc getControl*(pkgInfo: PackageInfo, depends: string, size: int): string =
  ## size in kb
  let arch = hostCPU
  result = fmt"""
  Source: {pkgInfo.name}
  Package: {pkgInfo.name}
  Version: {pkgInfo.version}
  Description: {pkgInfo.desc}
  Architecture: {arch}
  Maintainer: YOUR NAME <EMAIL>
  Installed-Size: {size}
  Depends: {depends}
  """.unindent

proc createDebianTree*(baseDir: string) =
  createDir(baseDir / "debian")
  # debian/control
  createDir(baseDir / "usr" / "bin")
  createDir(baseDir / "usr" / "share" / "applications")
  # usr/share/applications/{pkgInof.name}.desktop
  createDir(baseDir / "usr" / "share" / "icons")
  # /usr/share/icons/{pkgInfo.name}.png
  # dpkg-deb --build

proc getDesktop*(pkgInfo: PackageInfo): string =
  var dict = newConfig()
  dict.setSectionKey("Desktop Entry", "Name", pkgInfo.name, false)
  dict.setSectionKey("Desktop Entry", "Comment", pkgInfo.desc, false)
  dict.setSectionKey("Desktop Entry", "Exec", pkgInfo.name , false)
  dict.setSectionKey("Desktop Entry", "Icon", fmt"/usr/share/icons/{pkgInfo.name}.png", false)
  dict.setSectionKey("Desktop Entry", "Terminal", "false", false)
  dict.setSectionKey("Desktop Entry", "Type", "Application", false)
  dict.setSectionKey("Desktop Entry", "Categories", "Office", false)
  dict.setSectionKey("Desktop Entry", "Version", pkgInfo.version, false)
  result = $dict

when isMainModule:
  let version = "1.0.0"
  let desc = "my app desc"
  let pkgInfo = PackageInfo(name: "myapp", version: version, desc: desc)
  echo getDesktop(pkgInfo)
  echo getDirectorySize(".")

