FROM dart:3.12.2 AS dart-sdk
FROM docker.io/cloudflare/sandbox:0.12.9
USER root
RUN apt-get update && apt-get install -y --no-install-recommends clang lld python3 && rm -rf /var/lib/apt/lists/*
COPY --from=dart-sdk /usr/lib/dart /usr/lib/dart
ENV PATH="/usr/lib/dart/bin:${PATH}" DCDART_DART="/usr/lib/dart/bin/dart"
COPY toolchain-src/ /opt/dcdart/
COPY adapter.dart compile.py /opt/dcdart/
WORKDIR /opt/dcdart/core/dcc
RUN dart pub get && dart compile exe --packages=.dart_tool/package_config.json /opt/dcdart/adapter.dart -o /opt/dcdart/adapter
RUN python3 -c "import sys; sys.path.insert(0, '/opt/dcdart'); from compile import compile_source; r = compile_source('@bare u64 answer() { return u64(42); }'); assert r['functions'][0]['name'] == 'answer'"
WORKDIR /workspace
