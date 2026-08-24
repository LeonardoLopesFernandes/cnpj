# Consulta CNPJ

App Flutter para consulta gratuita de **CNPJ**, com tema escuro, favoritos,
histórico, compartilhamento de imagem e exportação de **PDF**.

## Funcionalidades
- Consulta de CNPJ via API pública (Receita Federal).
- Histórico de consultas e favoritos (armazenados localmente).
- Compartilhar resultado como imagem ou **relatório em PDF**.
- Interface escura estilo GitHub.

## Plataforma alvo
- **Android arm64-v8a** (compatível com Poco X7 Pro e a maioria dos celulares).
- Build otimizado para gerar um APK menor: `--target-platform android-arm64 --split-per-abi`.

## Como gerar o APK

### Pelo GitHub (release automático, APK menor ~20MB)
1. Suba este repositório para o GitHub.
2. Crie uma tag `vX.Y.Z` e envie:
   ```bash
   git tag v3.0.0
   git push origin v3.0.0
   ```
3. O workflow `.github/workflows/build_apk.yml` compila o APK arm64-v8a de
   release e cria automaticamente um **Release** com o APK anexado.
4. Para testar sem tag: aba **Actions → Build & Release APK → Run workflow**
   (baixa o APK como artifact).

### Pelo PC (local)
```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```
Saída: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Instalar no celular
```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Estrutura
- `lib/` — código Dart (telas, modelos, serviços, widgets).
- `android/` — configuração nativa Android (Gradle/Kotlin).
- `pubspec.yaml` — dependências e versão do app.
