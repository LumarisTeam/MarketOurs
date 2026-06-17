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

### Android 极光推送配置

系统通知已接入 Android + JPush。要让真机收到远程推送，还需要补齐以下本地配置：

1. 在极光控制台创建 Android 应用，包名填写 `com.luckyfish.lumalis`
2. 推荐在本地私有文件 `app/mobile_app/android/local.properties` 中提供：

   ```bash
   JPUSH_APPKEY=你的极光 AppKey
   JPUSH_CHANNEL=developer-default
   ```

   `local.properties` 已被 Git 忽略，不会提交到仓库。

   也支持放在 `gradle.properties` 或环境变量中：

   ```bash
   JPUSH_APPKEY=你的极光 AppKey
   JPUSH_CHANNEL=developer-default
   ```

3. 重新执行：

   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

说明：
- 如果没有配置 `JPUSH_APPKEY`，应用仍可正常启动，只是会自动跳过推送初始化。
- 登录后会自动注册极光 `registrationId`；登出时会自动向后端清空该 token。

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
