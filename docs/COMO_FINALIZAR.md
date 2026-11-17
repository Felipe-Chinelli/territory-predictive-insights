# Como finalizar e entregar (passo a passo)

Este código foi escrito **sem acesso ao SDK do Flutter**, então ainda **não foi compilado nem executado**. Faça os passos 1 a 3 primeiro e me mande qualquer erro que aparecer.

## 1. Criar o projeto Flutter e copiar o código

```bash
flutter create --org br.com.fiap --project-name territory_predictive_insights --platforms=android,ios territory_predictive_insights
cd territory_predictive_insights
```

Copie para dentro da pasta criada (sobrescrevendo): `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `README.md`, `docs/` e `assets/`. Apague o `test/widget_test.dart` gerado pelo `flutter create` se ele sobrar (o nosso já substitui).

## 2. Permissão de internet no Android (importante para o APK de release)

Em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` e antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Sem isso, o APK de release não consegue buscar o clima (o app cai no cache/simulado).

## 3. Rodar, analisar e testar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Se `flutter analyze` ou `flutter test` mostrarem erros, me envie a saída completa.

## 4. Capturar os prints (obrigatório no README)

Salve em `assets/screenshots/` com os nomes usados no README (`01-consentimento.png` ... `16-alto-contraste.png`). README sem prints de todas as telas é penalizado. Teste também em **2 tamanhos de tela** (ex.: celular pequeno e tablet/emulador maior) e com fonte ampliada.

## 5. Preencher placeholders

- `README.md`: tabela de integrantes (nome e RM, máx. 3 pessoas) e link do vídeo.
- `docs/ENTREGA.txt`: nomes, RMs, link do GitHub e do vídeo.

## 6. GitHub

- Repositório **público**, com `.gitignore` (já incluso) e commits descritivos ao longo do trabalho (ex.: `feat: painel de clima`, `test: motor de alertas`).
- Opcional (diferencial): `flutter build apk --release` e anexar o `app-release.apk` em **Releases**.

## 7. Vídeo e entrega

- Siga `docs/ROTEIRO_VIDEO.md` (máx. 3 min, link público).
- Envie no portal da FIAP o `.txt` (`docs/ENTREGA.txt` preenchido), **até 19/11/2026, 23h55**.

## Critérios que zeram a nota (confira)

App que não roda · repositório privado/link inválido · vídeo ausente ou inacessível · grupo com 4 ou mais pessoas · decisões automáticas de alto impacto (o app só sugere; a decisão é humana) · entrega fora do prazo.
