# Consulta CNPJ

App Flutter para consulta gratuita de CNPJ.

## Plataforma alvo
- **Android arm64-v8a** (compatível com o Poco X7 Pro e a maioria dos celulares atuais).
- Build otimizado para gerar um APK menor (`--target-platform android-arm64 --split-per-abi`).

## Como gerar o APK

### Pelo PC (local)
1. Instale o [Flutter](https://docs.flutter.dev/get-started/install) 3.38.5 e o Java 17.
2. Configure o `JAVA_HOME` para o Java 17 (ex.: `/usr/lib/jvm/java-17-openjdk-arm64`).
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Gere o APK de release arm64-v8a:
   ```bash
   flutter build apk --release --target-platform android-arm64 --split-per-abi
   ```
   O arquivo será `build/app/outputs/apk/release/app-arm64-v8a-release.apk`.

### Pelo GitHub (release automático)
1. Faça o push deste repositório para o GitHub.
2. Crie uma **tag** no formato `vX.Y.Z` (ex.: `v3.0.0`) e envie:
   ```bash
   git tag v3.0.0
   git push origin v3.0.0
   ```
3. O workflow `.github/workflows/build_apk.yml` compila o APK e cria automaticamente
   um **Release** no GitHub com o APK anexado para download.
4. Para gerar manualmente sem tag, use a aba **Actions → Build & Release APK → Run workflow**.

## Instalar no celular
```bash
adb install build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

## Estrutura
- `lib/` — código Dart (telas, modelos, serviços, widgets).
- `android/` — configuração nativa Android (Gradle/Kotlin).
- `pubspec.yaml` — dependências e versão do app.
