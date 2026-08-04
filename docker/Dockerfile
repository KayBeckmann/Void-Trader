# Containerisierte Flutter/Dart-Toolchain für Void Trader.
# Flutter/Dart werden bewusst NICHT auf dem Host installiert (Kay-Entscheidung,
# siehe docs/ und Vault: Arbeitsstand_2026-08-04_Reboot).
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /workspace

RUN flutter config --no-analytics --enable-linux-desktop --enable-android &&     flutter precache --web --linux --android

CMD ["bash"]
