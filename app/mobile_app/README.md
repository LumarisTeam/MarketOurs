## 部署

1. Windows (msix):

   ```bash
   dart run msix:create --store
   ```

2. Android (apk):
   ```bash
   flutter build apk --obfuscate --split-debug-info=xx --target-platform android-arm64 --split-per-abi
   ```

可以加入 `--dart-define=UPDATE_CHANNEL=appstore` 来表明使用应用商店版本

3. Android (aab):
   ```bash
   flutter build appbundle --obfuscate --split-debug-info=xx --target-platform android-arm64
   ```

4. Web (wasm):

   ```bash
   flutter build web--wasm
   ```

5. macOS

   ```bash
   flutter build macos --release
   ```

6. iOS (ipa):
   ```bash
   flutter build ipa
   ```

7. Linux
   ```bash
   flutter build linux --release
   ```

