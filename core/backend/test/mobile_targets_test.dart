import '../lib/targets.dart';

void require(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  for (final target in DCTarget.all) {
    require(
      identical(
        DCTarget.parse(
          target.alias!,
          hostOsName: 'macos',
          hostArchName: 'arm64',
        ),
        target,
      ),
      'alias ${target.alias}',
    );
    require(
      identical(
        DCTarget.parse(
          target.triple,
          hostOsName: 'macos',
          hostArchName: 'arm64',
        ),
        target,
      ),
      'triple ${target.triple}',
    );
  }
  for (final target in [
    DCTarget.iosArm64,
    DCTarget.iosSimulatorArm64,
    DCTarget.androidArm64,
  ]) {
    require(!target.isFreestanding, 'mobile has an OS');
    require(target.arch == TargetArch.aarch64, 'mobile arm64 architecture');
    var rejected = false;
    try {
      checkFeatureSupport(target, usesPortIo: true);
    } on UnsupportedTargetError {
      rejected = true;
    }
    require(rejected, 'mobile rejects x86 port I/O');
  }
  require(DCTarget.iosArm64.objectFormat == ObjectFormat.machO, 'iOS Mach-O');
  require(
    DCTarget.androidArm64.objectFormat == ObjectFormat.elf,
    'Android ELF',
  );
  require(
    DCTarget.iosArm64.triple != DCTarget.iosSimulatorArm64.triple,
    'device and simulator are distinct platforms',
  );
  require(DCTarget.defaultTarget == DCTarget.bareX86_64, 'default preserved');
  print(
    'mobile targets: aliases, triples, feature guards and existing default passed',
  );
}
