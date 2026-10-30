# بیلد اندروید

همه کامندها را از پوشه `mobile` اجرا کن. هر بیلد و اجرا باید `--flavor` داشته باشد: `bazaar` برای کافه‌بازار و `myket` برای مایکت. `applicationId` هر دو `ir.directoo.directoo` است.

قبل از بیلد release این فایل‌ها باید موجود باشند و وارد git نشوند:

- `android/key.properties` و `android/app/directoo-release.jks` (alias برابر `directoo`)
- `android/store.properties`، کپی از `android/store.properties.example`، با کلید RSA هر فروشگاه

## اجرا روی دستگاه

```bash
flutter run --flavor bazaar
flutter run --flavor myket
```

## دیباگ

```bash
flutter build apk --flavor bazaar --debug --target-platform android-arm64
flutter build apk --flavor myket --debug --target-platform android-arm64
```

خروجی:

- `build/app/outputs/flutter-apk/app-bazaar-debug.apk`
- `build/app/outputs/flutter-apk/app-myket-debug.apk`

## کافه‌بازار

کافه‌بازار باندل امضاشده و فایل `.bin` همان باندل را می‌گیرد. `.bin` فقط برای همان فایل AAB معتبر است. اگر AAB را دوباره بسازی، `genbin` را هم دوباره بزن.

```bash
flutter build appbundle --flavor bazaar --release
```

خروجی: `build/app/outputs/bundle/bazaarRelease/app-bazaar-release.aab`

ابزار امضای باندل، نسخه `0.1.14`:

```bash
curl -L -o /tmp/bundlesigner-0.1.14.jar \
  https://github.com/cafebazaar/bundle-signer/releases/download/v0.1.14/bundlesigner-0.1.14.jar

java -jar /tmp/bundlesigner-0.1.14.jar genbin -v \
  --bundle build/app/outputs/bundle/bazaarRelease/app-bazaar-release.aab \
  --bin build/app/outputs/bundle/bazaarRelease \
  --v2-signing-enabled true \
  --v3-signing-enabled false \
  --ks android/app/directoo-release.jks \
  --ks-key-alias directoo
```

رمز keystore را ابزار می‌پرسد. مقدار `storePassword` و `keyPassword` در `android/key.properties` است. فایل ساخته‌شده کنار باندل است: `app-bazaar-release.bin`.

اگر به‌جای پرسش رمز بخواهی از فایل بخواند، هر رمز را در یک خط از یک فایل بیرون از git بگذار و این دو فلگ را اضافه کن:

```bash
--ks-pass file:android/store-pass.txt --key-pass file:android/key-pass.txt
```

### APKهای جدا از روی همان باندل

این خروجی برای آپلود کافه‌بازار لازم نیست. خود کافه‌بازار از AAB و `.bin` بسته‌های دستگاه را می‌سازد. برای تست محلی:

```bash
curl -L -o /tmp/bundletool-all-1.18.3.jar \
  https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar

rm -rf build/app/outputs/apk-splits/bazaar
mkdir -p build/app/outputs/apk-splits/bazaar

java -jar /tmp/bundletool-all-1.18.3.jar build-apks \
  --bundle=build/app/outputs/bundle/bazaarRelease/app-bazaar-release.aab \
  --output=build/app/outputs/apk-splits/bazaar \
  --output-format=DIRECTORY \
  --mode=default \
  --ks=android/app/directoo-release.jks \
  --ks-key-alias=directoo \
  --ks-pass=file:android/store-pass.txt \
  --key-pass=file:android/key-pass.txt
```

با `--output-format=DIRECTORY` فلگ `--overwrite` مجاز نیست. اگر پوشه خروجی از قبل پر است، اول پاکش کن.

## مایکت

مایکت APK امضاشده می‌گیرد.

```bash
flutter build apk --flavor myket --release
```

خروجی: `build/app/outputs/flutter-apk/app-myket-release.apk`

اگر بخواهی برای هر معماری یک APK جدا باشد:

```bash
flutter build apk --flavor myket --release --split-per-abi
```

خروجی‌ها در `build/app/outputs/flutter-apk/`:

- `app-myket-armeabi-v7a-release.apk`
- `app-myket-arm64-v8a-release.apk`
- `app-myket-x86_64-release.apk`

برای آپلود مایکت همان `app-myket-release.apk` کافی است.
