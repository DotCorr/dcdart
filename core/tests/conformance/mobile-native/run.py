#!/usr/bin/env python3
"""Real mobile object/link conformance; never silently skips requested targets."""
import argparse
import json
import os
from pathlib import Path
import subprocess


def run(args):
    result = subprocess.run([str(a) for a in args], check=True, capture_output=True, text=True)
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dart', required=True, help='Dart SDK 3.12.2 executable')
    parser.add_argument('--nm', default='llvm-nm')
    parser.add_argument('--readelf', default='llvm-readelf')
    parser.add_argument('--android-clang', required=True, help='NDK aarch64-linux-android26-clang')
    parser.add_argument('--run-ios', action='store_true', help='Requires a booted arm64 iOS Simulator')
    parser.add_argument('--output', default='build/mobile-conformance')
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    core = here.parents[2]
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    os.environ['DCDART_DART'] = str(Path(args.dart).resolve())
    results = []
    for target in ['host', 'ios-arm64', 'ios-simulator-arm64', 'android-arm64']:
        folder = output / target
        folder.mkdir(exist_ok=True)
        obj, hdr, exe = folder / 'logic.o', folder / 'logic.h', folder / 'verify'
        run([args.dart, core / 'dcc/bin/dcc.dart', 'build', '--mode', 'bare', '--target', target,
             here / 'logic.dart', '-o', obj, '--emit-header', hdr])
        symbols = run([args.nm, '--undefined-only', '--just-symbol-name', obj])
        if symbols:
            raise RuntimeError(f'{target} introduces undefined symbols: {symbols}')
        compiler = ['clang']
        if target.startswith('ios'):
            sdk = 'iphonesimulator' if 'simulator' in target else 'iphoneos'
            triple = 'arm64-apple-ios16.0-simulator' if 'simulator' in target else 'arm64-apple-ios16.0'
            compiler = ['xcrun', '--sdk', sdk, 'clang', '-target', triple]
        elif target == 'android-arm64':
            compiler = [args.android_clang]
        run(compiler + ['-I', folder, here / 'main.c', obj, '-o', exe])
        result = {'target': target, 'undefinedSymbols': [], 'linked': str(exe)}
        if target == 'android-arm64':
            library = folder / 'liblogic.so'
            run([args.android_clang, '-shared', '-Wl,--no-undefined', obj, '-o', library])
            dynamic = run([args.readelf, '--dynamic', library])
            result['sharedLibrary'] = str(library)
            result['dynamicDependencies'] = [line.strip() for line in dynamic.splitlines() if 'NEEDED' in line]
            if any(not any(name in line for name in ['[libc.so]', '[libm.so]', '[libdl.so]']) for line in result['dynamicDependencies']):
                raise RuntimeError('Unexpected Android runtime dependency: ' + dynamic)
        if target == 'host':
            result['execution'] = run([exe])
        elif target == 'ios-simulator-arm64' and args.run_ios:
            result['execution'] = run(['xcrun', 'simctl', 'spawn', 'booted', exe])
        results.append(result)
    report = output / 'report.json'
    report.write_text(json.dumps(results, indent=2) + '\n')
    print(report)


if __name__ == '__main__':
    main()
