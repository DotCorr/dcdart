FROM dart:3.12.2 AS dart-sdk
FROM docker.io/cloudflare/sandbox:0.12.9
USER root
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl python3 \
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key -o /usr/share/keyrings/llvm.asc \
    && echo "deb [signed-by=/usr/share/keyrings/llvm.asc] https://apt.llvm.org/jammy/ llvm-toolchain-jammy-21 main" > /etc/apt/sources.list.d/llvm.list \
    && apt-get update && apt-get install -y --no-install-recommends clang-21 lld-21 \
    && rm -rf /var/lib/apt/lists/*
ENV DCDART_CLANG=/usr/bin/clang-21 DCDART_WASM_LD=/usr/bin/wasm-ld-21
COPY --from=dart-sdk /usr/lib/dart /usr/lib/dart
ENV PATH="/usr/lib/dart/bin:${PATH}" DCDART_DART="/usr/lib/dart/bin/dart"
COPY toolchain-src/ /opt/dcdart/
COPY adapter.dart compile.py /opt/dcdart/
WORKDIR /opt/dcdart/core/dcc
RUN dart pub get && dart compile exe --packages=.dart_tool/package_config.json /opt/dcdart/adapter.dart -o /opt/dcdart/adapter
RUN python3 -c "import sys; sys.path.insert(0, '/opt/dcdart'); from compile import compile_source; r = compile_source('@bare u64 answer() { return u64(42); }'); assert r['functions'][0]['name'] == 'answer'"
WORKDIR /workspace
