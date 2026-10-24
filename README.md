# AnyChat

AnyChat — Android-приложение на Flutter для общения с LLM через **ваш собственный API-ключ**.
Аналог «своего ChatGPT» с фокусом на прозрачный контроль контекста и минималистичный Material 3 UI:
20 провайдеров, стриминг SSE, ветвление диалога, индикатор токенов и сжатие истории (handoff).

> 📸 Скриншот: TODO (добавить после первой публичной сборки)

## Установка

Сборка APK выполняется в GitHub Actions (без локальной подписи):

1. Откройте репозиторий → вкладку **Actions** → последний успешный прогон ветки `main`.
2. В блоке **Artifacts** скачайте артефакт `AnyChat-<короткий sha>`.
3. Распакуйте ZIP и установите `app-release.apk` на устройство
   (разрешите установку из неизвестных источников).

Требования: Android 7.0+ (minSdk 24), internet-соединение или локальный Ollama.

> Подпись release-сборки — debug-keystore Flutter (в репозитории сознательно
> нет keystore/`.jks`). Для Play Store подпишите свой ключом.

## Настройка провайдера

1. **Настройки → Провайдер и ключ → Провайдер** — выберите одного из 20 провайдеров.
2. В карточке провайдера введите **API-ключ** и нажмите **Сохранить ключ**.
   В UI показывается только маска вида `sk-...abcd`; сам ключ хранится в
   `flutter_secure_storage` (Keystore Android) и никогда не попадает в БД или лог.
3. (Опционально) укажите **Base URL override** — для селф-хостинга, прокси
   или Ollama (`http://10.0.2.2:11434/v1` для эмулятора, свой адрес — для устройства).
4. Нажмите **Проверить ключ** — AnyChat выполнит лёгкий запрос (список моделей,
   а для провайдеров без `/models` — минимальный chat-проба) и покажет ✅/❌.
5. Вкладка **Модели** — выберите модель из загруженного списка (есть поиск,
   цена за 1M токенов и размер контекста, если их отдаёт провайдер) либо
   введите ID модели вручную (поле «Своя модель»).
6. Вкладка **Чаты** → «+» — начните диалог. Ответ приходит по токенам (SSE),
   доступны **Стоп**, **Перегенерировать**, редактирование сообщений (создаёт
   ветку), откат к любому сообщению («Ветка отсюда»), переключение веток,
   полоска контекста сверху и **Сжать историю** (handoff) в меню чата.

## Поддерживаемые провайдеры

| #  | Провайдер           | Формат    | Base URL                                  | `/models` |
|----|---------------------|-----------|-------------------------------------------|-----------|
| 1  | OpenAI              | `openai`  | `https://api.openai.com/v1`               | да        |
| 2  | OpenRouter          | `openai`  | `https://openrouter.ai/api/v1`            | да        |
| 3  | DeepSeek            | `openai`  | `https://api.deepseek.com/v1`             | да        |
| 4  | Xiaomi MiMo         | `openai`  | `https://api.xiaomimimo.com/v1` (TODO)    | нет       |
| 5  | Together AI         | `openai`  | `https://api.together.xyz/v1`             | да        |
| 6  | Groq                | `openai`  | `https://api.groq.com/openai/v1`          | да        |
| 7  | Fireworks           | `openai`  | `https://api.fireworks.ai/inference/v1`   | да        |
| 8  | Novita AI           | `openai`  | `https://api.novita.ai/v3/openai`         | да        |
| 9  | DeepInfra           | `openai`  | `https://api.deepinfra.com/v1/openai`     | да        |
| 10 | Mistral             | `openai`  | `https://api.mistral.ai/v1`               | да        |
| 11 | xAI                 | `openai`  | `https://api.x.ai/v1`                     | да        |
| 12 | Perplexity          | `openai`  | `https://api.perplexity.ai`               | да        |
| 13 | Hyperbolic           | `openai`  | `https://api.hyperbolic.xyz/v1`           | нет       |
| 14 | Cerebras            | `openai`  | `https://api.cerebras.ai/v1`              | да        |
| 15 | SambaNova           | `openai`  | `https://api.sambanova.ai/v1`             | да        |
| 16 | Lambda              | `openai`  | `https://api.lambdalabs.com/v1`           | нет       |
| 17 | Cohere              | `openai`  | `https://api.cohere.com/compatibility/v1` | нет       |
| 18 | Ollama (локальный)  | `openai`  | `http://10.0.2.2:11434/v1`                | да        |
| 19 | Anthropic           | `anthropic` | `https://api.anthropic.com/v1`          | да        |
| 20 | Google Gemini       | `gemini`  | `https://generativelanguage.googleapis.com/v1beta` | да |

Для любого провайдера доступно переопределение Base URL в его карточке.
Если `/models` недоступен или запрос не удался — используется статический
список моделей из кода, а ID любой модели можно ввести вручную.

## Design decisions

Решения, принятые autonomно (и почему):

1. **Версии зафиксированы.** CI использует стабильный Flutter **3.47.8**
   (Dart 3.13.7); `pubspec.yaml` — актуальные совместимые версии пакетов
   (Riverpod 3.x + `riverpod_annotation` 4.x, drift 2.35, dio 5.11).
2. **Без `flutter create`.** Каталог `android/` написан вручную по шаблону
   `flutter create` для 3.47 (Kotlin DSL, AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1,
   флаги `android.newDsl=false` / `android.builtInKotlin=false`). Gradle-wrapper
   (`gradlew`, `gradle-wrapper.jar`) не коммитится — Flutter сам докачивает его
   из кеша SDK при сборке.
3. **Без бинарников.** Иконка приложения — векторный `drawable/ic_launcher.xml`
   вместо PNG-mipmaps; никаких keystore, `.env` и ключей в репозитории.
4. **Ключи и конфиг разделены.** API-ключи — только в
   `flutter_secure_storage`; drift хранит `providers_config` (Base URL),
   чаты, ветки и сообщения.
5. **Доменные модели отделены от drift-строк.** `riverpod_generator` не может
   разрешить типы, сгенерированные в `db.g.dart` (это `part`-файл): генерация
   падала с `InvalidTypeException`. Поэтому `Chat/Message/Branch` — обычные
   неизменяемые классы в `features/chat/domain/models.dart`, а репозитории
   маппят строки через `fromRow`. Плюс: кодогенерация drift и riverpod больше
   не зависит от порядка выполнения (в CI всё равно сначала создаётся
   `db.g.dart`).
6. **`drift_flutter` вместо `sqlite3_flutter_libs`.** Так рекомендует
   документация drift: `driftDatabase(name:)` сам настраивает путь и
   нативные библиотеки.
7. **Собственный SSE-парсер** (`sse_parser.dart`) вместо `flutter_client_sse`:
   ~100 строк, покрыт тестами на разрезанные чанки и не тянет зависимости.
8. **Эвристика токенов.** Латиница /4, кириллица /2, прочие символы — 1/символ,
   +4 на сообщение. Лимит контекста берётся из метаданных модели, иначе 128k
   и пометка «приблизительно».
9. **Riverpod наполовину вручную.** `@riverpod` (codegen) — для нотифаеров и
   стрим-провайдеров; простые синглтоны (БД, репозитории, key-store) — обычные
   `Provider`, чтобы не плодить генерацию без нужды.
10. **Ошибки.** Один `ApiErrorType` на три wire-формата, локализация через ARB
    (en/ru/uk), сырые тела — только в кольцевом debug-логе (последние 50,
    экран «Отладочный лог ошибок» в настройках).
11. **Ветвление через копирование.** Fork ветки копирует её сообщения
    (транзакция drift) — проще и надёжнее переиспользования `parentId`,
    чаты в v1 небольшие.
12. **Проверка ключа:** `/models` если у провайдера есть endpoint, иначе
    минимальный chat-проба (`max_tokens: 1`).
13. **Навигация без роутера:** `NavigationBar`/`NavigationRail` (порог 840dp)
    + обычный `Navigator` — для трёх экранов и перехода «сжал историю → новый чат»
    go_router избыточен.
14. **`gen-l10n` c `nullable-getter: false`:** `AppLocalizations.of(context)`
    не-nullable, меньше `!` в UI-коде. Сгенерированные файлы не коммитятся —
    создаются в CI до `flutter analyze`.
15. **cleartext HTTP разрешён** (`android:usesCleartextTraffic="true"`) —
    нужен для локального Ollama по `http://`.
16. **JDK 21 в CI** — Gradle 9.3 / AGP 9.1 требуют 17+, 21 — стабильный LTS.

## Ограничения v1

- Только Android (iOS/web/desktop не поддерживаются).
- Нет рендеринга Markdown в ответах (обычный текст), нет копирования блоками.
- Нет tool calling / функций, изображений, голоса и вложений.
- Нет экспорта/импорта чатов, поиска по истории, пагинации — чаты целиком
  грузятся в память.
- Лог ошибок хранится только в памяти процесса.
- Индикатор контекста — эвристика (без токенизатора), значения «приблизительно».
- Fork ветки копирует сообщения — на экстремально длинных историях может
  быть заметной задержкой.
- Иконка приложения упрощённая (вектор), release-сборка подписана debug-ключом.
- Для Xiaomi MiMo базовый URL помечен TODO и требует подтверждения.
- Локализация UI: en/ru/uk; названия провайдеров и моделей не переводятся.

## Разработка

Политика CI: **`flutter analyze` должен давать 0 issues** (любые error /
warning / info валит прогон), `flutter test` — зелёный, `flutter build apk
--release` — собирается и выкладывается как артефакт `AnyChat-<sha>`.

Локально (нужен Flutter SDK) команда для итераций:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Структура:

```
lib/
  main.dart, app.dart           # точка входа, темы, локализация
  core/                         # ошибки, SSE, токены, drift, secure storage
  features/
    chat/                       # data (репозитории), domain, presentation
    providers/                  # реестр 20 провайдеров + адаптеры форматов
    models/                     # выбор модели
    settings/                   # настройки + контроллер
  l10n/                         # ARB: app_en / app_ru / app_uk
test/                           # unit-тесты ядра (ошибки, SSE, адаптеры)
```

## Лицензия

MIT — см. [LICENSE](LICENSE).
