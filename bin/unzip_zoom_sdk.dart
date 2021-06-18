import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

///
/// Extract the required files from the iOS SDK.
///
/// The required are found in the following location:
///
///  - Sample&Libs-All (Development on Simulator)
///  - Sample&Libs-DeviceOnly (Production)
///
/// The folders that need to be copied to the ios folder are located in the libs subfolder:
///
///  - MobileRTC.framework
///  - MobileRTCResources.bundle
///  - MobileRTCScreenShare.framework
///
void processIOS({
  required List<FileSystemEntity> files,
  required bool devMode,
}) {
  // print('Processing iOS SDK');
  final Directory projectRoot =
      Directory.fromUri(Platform.script).parent.parent;

  // unzip the SDK
  final File? sdk = files.firstWhere(
    (f) => f.uri.pathSegments.last.startsWith('zoom-sdk-ios'),
  ) as File?;
  if (sdk == null) {
    // print(
    //     ' - iOS SDK not found. Please make sure it is copied into the sdk folder');
    exit(1);
  }
  // print(' - Decompressing ${p.basename(sdk.path)}');
  final Archive archive = ZipDecoder().decodeBytes(sdk.readAsBytesSync());

  // delete the existing folders
  // print(' - Deleting existing files');
  final List<String> folders = [
    'MobileRTC.framework',
    'MobileRTCResources.bundle',
    'MobileRTCScreenShare.framework',
  ];
  final Directory targetFolder = projectRoot
          .listSync()
          .firstWhere((e) => e is Directory && p.basename(e.path) == 'ios')
      as Directory;
  for (final FileSystemEntity entity in targetFolder.listSync()) {
    if (folders.contains(p.basename(entity.path))) {
      entity.deleteSync(recursive: true);
    }
  }

  // print(' - Extracting SDK files');
  for (final ArchiveFile file in archive) {
    final String prefix =
        '${devMode ? 'Sample&Libs-All' : 'Sample&Libs-DeviceOnly'}/lib';
    if (file.name.contains(prefix) && file.isFile) {
      final File targetFile = File(targetFolder.path +
          file.name.substring(file.name.indexOf(prefix) + prefix.length));
      targetFile.createSync(recursive: true);
      targetFile.writeAsBytesSync(file.content);
    }
  }
}

///
/// Extract the required files from the Android SDK.
///
/// The files to be extracted are located in the following location:
///
///  - mobilertc-android-studio/commonlib
///  - mobilertc-android-studio/mobilertc
///
/// They should be copied into the android/libs folder.
///
void processAndroid(List<FileSystemEntity> files) {
  // print('Processing Android SDK');
  final Directory projectRoot =
      Directory.fromUri(Platform.script).parent.parent;

  // unzip the SDK
  final File? sdk = files.firstWhere(
    (f) => f.uri.pathSegments.last.startsWith('zoom-sdk-android'),
  ) as File?;
  if (sdk == null) {
    // print(
    //     ' - Android SDK not found. Please make sure it is copied into the sdk folder');
    exit(1);
  }
  // print(' - Decompressing ${p.basename(sdk.path)}');
  final Archive archive = ZipDecoder().decodeBytes(sdk.readAsBytesSync());

  // delete the existing folders
  // print(' - Deleting existing files');
  final Directory targetFolder = projectRoot
          .listSync()
          .firstWhere((e) => e is Directory && p.basename(e.path) == 'android')
      as Directory;
  // print("targetFolder $targetFolder");
  // print("archive $archive");
  for (final FileSystemEntity entity in targetFolder.listSync()) {
    if (p.basename(entity.path) == 'libs') {
      entity.deleteSync(recursive: true);
    }
  }

  // print(' - Extracting SDK files');
  for (final ArchiveFile file in archive) {
    if (p.basename(file.name) == 'commonlib.aar' ||
        p.basename(file.name) == 'mobilertc.aar') {
      const String prefix = 'mobilertc-android-studio';
      final File targetFile = File(
        '${targetFolder.path}/libs${file.name.substring(file.name.indexOf(prefix) + prefix.length)}',
      );
      targetFile.createSync(recursive: true);
      targetFile.writeAsBytesSync(file.content);
    }
  }
}

void main(List<String> args) {
  final bool devMode = args.isNotEmpty && args[0] == 'dev';
  final Directory projectRoot =
      Directory.fromUri(Platform.script).parent.parent;
  final Directory sdkFolder = projectRoot
          .listSync()
          .firstWhere((e) => e is Directory && p.basename(e.path) == 'sdk')
      as Directory;
  final List<FileSystemEntity> files = sdkFolder.listSync();
  // print("files $files");

  processIOS(files: files, devMode: devMode);
  processAndroid(files);
}
