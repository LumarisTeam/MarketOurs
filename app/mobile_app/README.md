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

### Android FCM 推送配置

系统通知已接入 Android + FCM。要让真机收到远程推送，还需要补齐以下本地配置：

1. 在 Firebase Console 中为 Android 应用注册包名 `com.luckyfish.lumalis`
2. 将 Firebase 下载得到的 `google-services.json` 放到：

   ```bash
   app/mobile_app/android/app/google-services.json
   ```

3. 用真实 Firebase 配置覆盖 [lib/firebase_options.dart](/Users/luckyfish/Documents/Project/MarketOurs/app/mobile_app/lib/firebase_options.dart) 里的占位值
   - 推荐使用 FlutterFire CLI 重新生成该文件
4. 重新执行：

   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

说明：
- 如果没有放置 `google-services.json` 或 `firebase_options.dart` 仍是占位值，应用仍可正常启动，只是会自动跳过推送初始化。
- 登录后会自动注册 FCM token；登出时会自动向后端清空该 token。

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
