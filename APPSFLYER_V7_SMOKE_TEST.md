# AppsFlyer iOS SDK 7.0.1 — чекліст ручного smoke-тесту

Міграція `CoreIntegrations` з AppsFlyer 6.14.0 на 7.0.1.

**Оновлено для 3.0.4.** Правила про старт сесії та про `appsflyerWeb2AppHandled` змінені після
фіксу дублювання `start()`: тепер 1 наш `start()` на foreground-цикл, а результат старту більше не
впливає на крок атрибуції. Виміряна поведінка SDK 7.0.1, на якій це тримається, — у розділі 1.

Усі рядки логів нижче **вилучені зі самого бінарника** `AppsFlyerLib.framework` 7.0.1
(`strings`), а не з документації — тобто вони гарантовано існують у цій версії.

## Підготовка

1. Збірка в конфігурації **Debug** — `isDebug = true` виставляється під `#if DEBUG`
   ([AppfslyerManager.swift:63](Sources/AppsflyerIntegration/AppfslyerManager.swift#L63)).
2. Xcode → Console, фільтр `AppsFlyer`.
3. **Кожен пункт з позначкою «cold» вимагає видалення застосунку з девайса**
   (не просто перезапуск) — інакше не перевіряється ні перший інстал, ні ATT-промпт,
   ні deferred deep link.
4. Тестувати на **реальному девайсі**. У симуляторі немає IDFA і ATT-промпт поводиться
   інакше.

---

## 1. Сесія реально відправляється при холодному старті

> Найгірший сценарій міграції: SDK не стартує взагалі і зникають усі інстали.

**Кроки:** видалити апку → встановити → запустити → відповісти на ATT-промпт (будь-як) →
дочекатися першого екрана.

**Очікувані логи (мусять бути ВСІ):**

```
[START] Initial start of the application
[START] isFirstLaunch: true, timestamp: <...>
[HTTP] Operation start: `https://launches.appsflyer.com/api/v<N>/ios<...>?app_id=<APP_ID>&buildnumber=<...>`
```

`[START] Initial start of the application` — це і є доказ, що `start()` дійшов до SDK.
Якщо його немає — сесія не пішла, гейти не зійшлися. Дивись діагностику нижче.

**Правило старту: не більше 1 нашого виклику `start()` на foreground-цикл.** Кожен наш виклик
SDK логує рівно 1 рядком `[START] isFirstLaunch: ...` — і прийнятий, і відхилений; далі для
прийнятого йде `Initial start of the application` або `Time from last start(session): <X>`, для
відхиленого — `[WARNING] Skip launch`. Рахувати треба саме рядки `isFirstLaunch:` між виходом
у фон і наступним виходом у фон: 2 такі рядки в одному циклі — блокер.

Чому так. SDK 7.0.1 викликає session-ready listener на **кожному** `didBecomeActive` того самого
foreground-циклу — закриття ATT-алерту, Control Center, системне вікно, — а не 1 раз на цикл, як
обіцяє його хедер. До 3.0.4 кожен такий виклик відкривав новий `start()`, і другий виклик у межах
`minTimeBetweenSessions` (5 с від попереднього відправленого старту) SDK відхиляв локально:
`com.appsflyer.sdk.event / 10`, `Skip launch`. З 3.0.4 listener лише позначає готовність, а
можливість старту відкриває тільки перехід через фон. Повторний listener без фону нового
старту давати **не повинен**.

**Червоні прапорці:**

| Лог | Що означає |
|---|---|
| `devKey and appleAppID must be set before calling registerSessionReadyListener:` | Порушено порядок ініціалізації — `initialize()` мусить бути до реєстрації листенера |
| немає жодного `[START]` протягом 20 с | Гейт не зійшовся. Перевір Sentry — див. нижче |
| `[SRD] WARNING: deeplink timed out (<X>s)` | Не помилка сама по собі — readiness спрацював по таймауту, deep link не зарезолвився. Очікувано для звичайного органічного запуску |

**Діагностика «немає `[START]`» — три гейти:**

| Гейт | Бекстоп | Сигнал, якщо завис |
|---|---|---|
| ATT | polling кожні 0.5 с + fallback 5 с | якщо `[START]` немає і через 5 с — гейт не ATT |
| session ready (SDK) | внутрішній таймаут SDK | `[SRD] WARNING: deeplink timed out` показує, що SDK свій таймаут відпрацював |
| customer user ID | **бекстопу немає** | Sentry: `coreintegrations.appsflyer.noCustomerUserID` |

Якщо ж `start()` дійшов до SDK, але completion повернув помилку, це видно **без Sentry** —
окремою Amplitude-подією `framework_appsflyer_start_failed` на **кожен** такий completion, у будь-який
момент життя процесу:

| Поле | Значення |
|---|---|
| `kind` | `rate_limited` — пара `com.appsflyer.sdk.event` / 10, очікуване обмеження SDK; `error` — усе інше |
| `error_domain`, `error_code`, `error_description` | сирі дані помилки SDK |
| `attempt` | номер виклику `start()` у процесі, з 1 |
| `seconds_since_previous_attempt` | інтервал від попереднього нашого виклику; немає для першого |
| `connection`, `connection_type` | стан мережі в момент події |

Результат старту **не завершує** крок `appsflyerWeb2AppHandled` і не блокує GCD — крок завершують
лише GCD або таймер конфігурації. Значення `error: 1002` у `framework_attribution` /
`framework_finished` з 3.0.4 не існує: якщо воно з'явилось — це регресія.

Відомі коди в completion `start()` (виміряно на 7.0.1):

| Domain / code | `error_description` | Що означає |
|---|---|---|
| `com.appsflyer.sdk.event` / 10 | `Event timeout. Check minTimeBetweenSessions param` | виклик раніше ніж через 5 с після попереднього відправленого старту; локально, без мережі; `kind = rate_limited` |
| `com.appsflyer.sdk.network` / 40 | `Status code failure: <HTTP>` | сервер відповів помилкою; запит з кешу видалено, остаточно |
| `com.appsflyer.sdk.network` / 40 | `Network failure` | транспортний збій; launch лишається в кеші SDK і досилається з наступним `start()` або подією; completion для наступних стартів може прийти через десятки секунд або не прийти, доки кеш не досланий |

**Скільки разів це летить у Sentry.** Максимум **один раз на інстал**, і тільки поки
AppsFlyer жодного разу не стартував успішно. Щойно сесія хоч раз пройшла — подальші провали
в Sentry не йдуть узагалі. Стан персистентний (`UserDefaults`), тобто перезапуск його не
скидає; повторний репорт можливий лише після перевстановлення апки.

Важливо для QA: **в аналітиці сигнал лишається повним** — `framework_appsflyer_start_failed`
іде на кожен completion з помилкою, обмежений тільки Sentry-канал, і `kind = rate_limited` у Sentry
не йде ніколи. Тобто якщо Sentry мовчить, а в аналітиці є подія — це не суперечність, а очікувана
робота дедуплікації. Поява в Sentry `Appsflyer_session_start_error` з underlying
`com.appsflyer.sdk.event / 10` — регресія.

**Kill switch для Sentry.** Помилка старту сесії летить у Sentry з типом
`Appsflyer_session_start_error`. Якщо навіть один репорт на інстал виявиться завеликим
обсягом — Sentry → Project Settings → **Inbound Filters** → Custom Filters →
Error Message → додати:

```
*Appsflyer_session_start_error*
```

Це відрубає подію на боці Sentry без релізу апки, і **відфільтровані події не жеруть квоту**.
Оригінальна помилка SDK лишається вкладеною в звіті, тож діагностика не втрачається.
Домен NSError у коді **є** цим рядком фільтра — не перейменовувати.

Третій гейт бекстопу не має **свідомо** — це та сама умова, що була в 6.x
(`if customerUserID != nil { start() }`), поведінка збережена. Але це означає, що
Sentry-подія `coreintegrations.appsflyer.noCustomerUserID` є **єдиним** сигналом саме для
цього гейта — на відміну від провалу відправки сесії, який тепер видно в аналітиці.

**Ключовий негативний тест (обов'язковий!):** запустити апку і **не торкатися ATT-промпту**
взагалі. Через **~5 с** `[START]` мусить з'явитися все одно — це hard fallback у
`CoreManager.requestATT()`. До fallback CoreManager кожні 0.5 с перевіряє
`ATTrackingManager.trackingAuthorizationStatus`, тому вже відому відповідь підхоплює навіть
якщо системний callback Apple не прийшов.
Якщо не з'явився — сесія блокується назавжди, це блокер релізу.

**Тест межі fallback:** відповісти **Allow** на 2–4 секунді. Перша `launches`-сесія мусить
містити IDFA. Якщо відповісти вже після 5-секундного fallback, перша сесія очікувано може
піти без IDFA: це свідомий компроміс проти вічного `.notDetermined`, а не регресія.

**Warm start:** згорнути апку → зачекати >5 с → розгорнути. Мусить з'явитися:

```
[START] Time from last start(session): <X>
```

Це перевіряє скидання гейта старту, яке з 3.0.4 робить **лише** перехід через фон
(`didEnterBackground`, `AppsFlyerSessionStartPolicy.sessionBecameUnavailable()`); listener SDK
тільки позначає готовність. **Якщо warm-start сесій немає — це тиха регресія, блокер.** На кожне
розгортання після фону має бути рівно 1 рядок `[START] isFirstLaunch:`. Повторити 2-3 рази.

**Швидке повернення з фону (менше ніж через 5 с після попереднього відправленого старту):** наш
`start()` іде, SDK відхиляє його локально — `Skip launch`, подія `framework_appsflyer_start_failed`
з `kind = rate_limited`. Це очікувано; 1002 і Sentry бути не повинно.

**«Короткий» вихід з фокусу без фону** — шторка нотифікацій, Control Center, дзвінок, системний
алерт, навіть довше 5 с: нового старту **не буде**. Це свідома зміна 3.0.4: до неї така активація
давала ще одну сесію AppsFlyer, тепер сесія 1 на foreground-цикл. Другий рядок
`[START] isFirstLaunch:` у такому сценарії — блокер.

---

## 2. Deep link / deferred deep link

### 2a. Cold start по Universal Link (клік по OneLink з нотаток/Safari)

**Кроки:** видалити апку → встановити → **не запускати** → клікнути OneLink.

```
UniversalLink/Deeplink found: <url>
[START] Initial start of the application
[GCD-A02] -[<Class> onConversionDataSuccess:]:
```

`handleLaunchOptions` протягнутий саме для цього кейсу — до міграції він не викликався
взагалі. Якщо `UniversalLink/Deeplink found:` не з'являється при cold-start кліку —
`launchOptions` не доходить до SDK.

### 2b. Warm start по Universal Link

Апка в бекграунді → клік по OneLink. Ті самі рядки, крім `Initial start`.

### 2c. Deferred deep link (реклама → App Store → перший запуск)

```
Loading conversion data
[GCD-A02] -[<Class> onConversionDataSuccess:]:
```

У дампі `conversionInfo` мусять бути `media_source` / `campaign` / `af_dp`.

### 2d. Очікуваний і нормальний лог

```
[DDL] Delegate doesn't respond to `didResolveDeepLink:`
```

**Це НЕ помилка.** Ця кодова база свідомо не використовує UDL (`AppsFlyerDeepLinkDelegate`) —
deep link і атрибуція читаються з `onConversionDataSuccess`. QA не повинен це репортити.

---

## 3. Кастомний хост

**Не застосовно.** `setHost` у цій кодовій базі не використовується — трафік іде на дефолтні
ендпоінти `*.appsflyer.com`. Це саме той пункт, де v7 змінив порядок аргументів
(`setHost:withHostPrefix:` → `setHost:hostName:`) і зламав би все тихо, якби використовувався.

Перевірка того, що хост не з'їхав — з логів п.1:

```
[HTTP] Operation start: `https://launches.appsflyer.com/...`
```

Жодних префіксів у домені бути не має.

---

## 4. IDFA доступний SDK після рішення ATT

> Це головний ризик міграції: `waitForATTUserAuthorization` більше не тримає сесію,
> тому `start()` **мусить** відбутися після відповіді на ATT.

**Кроки:** видалити апку → встановити → запустити → **Allow** на ATT-промпті.

```
[ATT] Tracking authorization update from `oldStatus`: 0 to `newStatus`: 3
```

`0` = `notDetermined`, `3` = `authorized`.

### Головна перевірка (саме вона є критерієм)

У дампі запиту сесії (`[HTTP]` з п.1) знайти поля payload — імена ключів вилучені з
бінарника 7.0.1:

```
advertiserId / advertiser_id   ← мусить бути непорожній UUID, не нулі
attStatus / att_status         ← мусить відповідати відповіді юзера (3 = authorized)
```

**Порожній або нульовий `advertiserId`, якщо Allow натиснуто до 5-секундного fallback, —
IDFA втрачено на цьому інсталі. Блокер релізу.** Після hard fallback перша сесія вже могла
піти без IDFA за прийнятою продуктовою політикою.

### Додатково (довідково, НЕ критерій)

```
[ATT] Tracking authorization update ... `newStatus`: 3
[START] Initial start of the application
```

Логічно `[ATT]` має йти перед `[START]`. Але цей рядок — це **власне спостереження SDK за
зміною статусу**, а не наш гейт, і SDK може залогувати його ліниво, вже після коректно
впорядкованого `start()`. **Порядок цих двох рядків сам собою блокером не є** — репортити
тільки якщо не сходиться головна перевірка вище.

**Червоний прапорець:**

```
IDFA disabled
```

Означає, що `disableAdvertisingIdentifier` десь виставлено — у цьому коді такого немає,
тож поява цього рядка вимагає розслідування.

**Повторити з Deny** — `newStatus: 2`. Сесія мусить піти так само, просто без IDFA.

---

## 5. GCD-колбеки і споживачі першого екрана

```
Loading conversion data
[GCD-A02] -[<Class> onConversionDataSuccess:]:
```

**Червоні прапорці:**

| Лог | Що означає |
|---|---|
| `[GCD-E01] Delegate is 'nil' or does not respond to -[AppsFlyerLibDelegate onConversionDataSuccess:]` | `delegate` не виставлений або втратився. Конфігурація зависне до таймауту |
| `[GCD-A02] -[<Class> onConversionDataFail:]:` | GCD не вдався — має піти в `coreConfiguration(handleDeeplinkError:)` і дати `appsflyerWeb2AppHandled: error: <код SDK>` |
| `[GCD-E02] Cached conversion data expired` | Норма на повторних запусках |

**Перевірка на рівні продукту (обов'язкова):** мусить бути виклик
`coreConfigurationFinished` / показ першого екрана. Подія `appsflyerWeb2AppHandled` — одна
з трьох, що гейтять завершення конфігурації, і **точно одне** з
`onConversionDataSuccess` / `onConversionDataFail` мусить її закрити. Якщо перший екран
з'являється рівно через `configurationTimeout` (дефолт 6 с) — жодного колбека не прийшло,
конфігурація доїхала по таймауту. Причину дивитись у `appsflyerSession` (нижче): при живій мережі
й `appsflyerSession: started` це регресія; при `failed` з мережевою помилкою в
`framework_appsflyer_start_failed` — очікувана поведінка, так само працювала 3.0.1.

**Перевірка статусів модулів в аналітиці (обов'язкова).** В івентах `framework_attribution`
і `framework_finished` подивитися значення ключа `appsflyerWeb2AppHandled`:

| Значення | Що означає |
|---|---|
| `finished` | ✅ норма — GCD прийшов |
| `error: <код SDK>` | 🟡 GCD провалився, код помилки SDK |
| `not finished` | GCD не встиг до таймера — причину каже `appsflyerSession` |
| `error: 1002` | 🔴 з 3.0.4 не існує; поява = регресія |

Поруч у тих самих івентах з 3.0.4 є ключ `appsflyerSession` — стан наших викликів `start()` у
цьому процесі на момент відправки івента:

| `appsflyerSession` | Що означає | Разом з `not finished` |
|---|---|---|
| `started` | хоча б 1 completion без помилки | 🟡 сесія є, GCD не встиг — дивитись мережу й `[GCD-...]` |
| `starting` | є виклик без відповіді, успішних ще немає | 🟡 completion відстає; при живій мережі й повторюваності — розбиратись |
| `failed` | усі виклики завершились помилкою, включно з `rate_limited` | 🔴 якщо `kind = error` з живою мережею; ⚪️ якщо мережі не було |
| `not started` | жодного виклику `start()` не було | 🔴 гейт не зійшовся — див. діагностику 3 гейтів у розділі 1 |

Нюанс: `finished` разом із `starting` можливий у нормі — GCD прийшов раніше за completion старту.

**Функціональна перевірка `CoreUserSource`:** пройти по OneLink з `media_source=Full_Access`
і перевірити, що юзер отримує `test_premium`. Це наскрізь перевіряє
`onConversionDataSuccess` → `parseDeepLink` → `getAttributionResult()`.

---

## 6. Окремо: `getAppsFlyerUID()` до `start()` (відкрите питання)

> Хедери 7.0.1 на це не відповідають, а перевірити треба обов'язково.

`appsflyerID` читається під час конфігурації (`CoreManager.swift:193`) — **до** того, як
сесія відправлена — і йде на attribution-сервер. `AttributionServerManager` жорстко гейтить
на `appsflyerId.isEmpty == false`.

**Перевірка:** брейкпоінт на `CoreManager.swift:193` (`let appsflyerToken = ...`) на
**першому** запуску після видалення апки. Перевірити, що `appsflyerToken` — непорожній UUID,
а не `""` / `nil`.

**Якщо порожній** — запит `/install-application` піде без `appsflyerId`, а `/app-transaction`
буде тихо скіпнутий, і server-side matching деградує. Тоді потрібне окреме рішення:
читати UID після старту сесії.

---

## Прийняті обмеження 3.0.4 (не репортити як баги)

- Активації без переходу через фон — ATT, дозволи, Control Center, дзвінок — нової сесії AppsFlyer
  не дають. Кількість сесій у дашбордах AppsFlyer може бути меншою, ніж у 2.6.0.
- Після мережевого збою launch досилає сам SDK — з наступним `start()` (наступний foreground-цикл)
  або подією, наприклад покупкою. Власних повторів немає.
- Китай, «немає інтернету», реконфігурація без виходу у фон: нового `start()` немає, крок чекає
  GCD наступного циклу; вже отриманий у цьому процесі успішний GCD використовується повторно.

## Зведена таблиця «блокер / не блокер»

| Симптом | Вердикт |
|---|---|
| Немає `[START]` при cold start | 🔴 блокер |
| 2 рядки `[START] isFirstLaunch:` в одному foreground-циклі | 🔴 блокер |
| Немає `[START]` при cold start без відповіді на ATT (через 5 с) | 🔴 блокер |
| Порожній / нульовий `advertiserId` при Allow до 5-секундного fallback | 🔴 блокер |
| Порожній / нульовий `advertiserId` при Allow після fallback | ⚪️ прийнятий компроміс |
| `[START]` раніше за `[ATT] ... newStatus` | ⚪️ довідково, не блокер |
| Немає warm-start `[START] Time from last start` | 🔴 блокер |
| Немає сесії після короткої втрати фокуса без фону | ⚪️ очікувано з 3.0.4: 1 старт на цикл |
| `Skip launch` і подія `kind = rate_limited` при поверненні з фону раніше ніж через 5 с | ✅ норма |
| `devKey and appleAppID must be set before...` | 🔴 блокер |
| `[GCD-E01] Delegate is 'nil'...` | 🔴 блокер |
| Перший екран рівно через 6 с при живій мережі й `appsflyerSession: started` | 🔴 блокер |
| `appsflyerWeb2AppHandled: error: 1002` в `framework_finished` | 🔴 регресія: значення з 3.0.4 не існує |
| `appsflyerWeb2AppHandled: not finished` з `appsflyerSession: not started` | 🔴 блокер |
| `appsflyerWeb2AppHandled: not finished` з `appsflyerSession: started` / `starting` при живій мережі | 🟡 розбиратись |
| `framework_appsflyer_start_failed` з `kind = error` при живій мережі на першому запуску | 🔴 блокер |
| Sentry `Appsflyer_session_start_error` з underlying `com.appsflyer.sdk.event / 10` | 🔴 регресія |
| Порожній `appsflyerToken` на першому запуску | 🟡 потрібне рішення |
| `[DDL] Delegate doesn't respond to didResolveDeepLink:` | ✅ норма |
| `[SRD] WARNING: deeplink timed out` на органічному запуску | ✅ норма |
| `[GCD-E02] Cached conversion data expired` на повторному запуску | ✅ норма |
