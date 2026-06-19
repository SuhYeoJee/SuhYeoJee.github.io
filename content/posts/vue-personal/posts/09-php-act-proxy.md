---
title: Vue 3 — PHP act 프록시
description: ""
date: 2026-06-18T00:30:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - PHP
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

Vue SPA는 **비밀키·외부 API URL**을 브라우저에 두기 어렵다.
PHP **게이트웨이**가 JSON body의 `act` 필드로 핸들러를 디스패치하고, 토큰·DB·제3자 API 호출을 서버 뒤에 숨긴다.

8편 Axios 폼의 `apiUrl`이 호출하는 층이다. `client_secret`, DB URL 등은 환경 변수로만 관리한다.

---

## 진입점 — act 디스패치

POST JSON의 `act`를 화이트리스트 검사 후 해당 private 메서드로 라우팅한다.

```php
<?php
class ApiGateway
{
    private array $allowedActs = [
        'check_status',
        'register',
        'fetch_profile',
    ];

    public function run(): void
    {
        $body = json_decode(file_get_contents('php://input'));
        $act = $body->act ?? $_GET['act'] ?? null;

        if (!$act || !in_array($act, $this->allowedActs, true)) {
            http_response_code(404);
            echo json_encode(['error' => 'unknown act']);
            return;
        }

        $this->{$act}($body);
    }

    private function check_status(object $body): void
    {
        // 외부 API / DB 조회
        echo json_encode(['registered' => false]);
    }

    private function register(object $body): void
    {
        $form = $body->payload->form ?? null;
        $auth = $body->payload->authSession ?? null;
        // 2차 인증 분기 ...
        echo json_encode(['needSmsAuth' => true]);
    }

    private function fetch_profile(object $body): void
    {
        echo json_encode(['profile' => ['name' => 'demo']]);
    }
}

(new ApiGateway())->run();
```

- `file_get_contents('php://input')` — POST raw JSON body 읽기
- `json_decode` — stdClass 객체; 8편 `payload.form` 구조와 매칭
- `$allowedActs` — 허용 `act` 화이트리스트; 없으면 404
- `$this->{$act}($body)` — **화이트리스트 통과 후만** dynamic call
- `check_status` / `register` / `fetch_profile` — 8편 Axios `act` 값과 1:1
- `register`의 `needSmsAuth` — 2차 인증 분기 응답; 프론트 `formLocked`와 연동
- 화이트리스트 없이 dynamic call 하면 **RCE 위험**

---

## 외부 API 클라이언트

토큰 발급·POST 요청을 캡슐화해 게이트웨이 핸들러에서 재사용한다.

```php
class ExternalApiClient
{
    public function __construct(
        private string $clientId,
        private string $clientSecret,
        private ?string $accessToken = null,
    ) {}

    public function requestToken(): string { /* curl ... */ }
    public function post(string $path, array $payload): array { /* curl ... */ }
}
```

- `clientId`·`clientSecret` — 서버 환경 변수에서만 주입; 브라우저에 노출 안 됨
- `requestToken()` — OAuth 등 액세스 토큰 선발급
- `post($path, $payload)` — 업체 API 공통 HTTP 래퍼

Vue는 `ExternalApiClient`를 알 필요 없다. `act=register`와 payload schema만 알면 된다.

---

## DB 큐 (선택) — 리소스 할당

이메일·계정 등 **풀에서 하나 할당**할 때 FIFO 큐 패턴을 쓴다.

```php
function pickFromQueue(PDO $db): ?array
{
    $stmt = $db->query(
        'SELECT * FROM resource_queue WHERE assigned = 0 ORDER BY created_at ASC LIMIT 1'
    );
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        // UPDATE assigned = 1 ...
    }
    return $row ?: null;
}
```

- `assigned = 0` — 미할당 리소스만 조회
- `ORDER BY created_at ASC LIMIT 1` — 가장 오래된 항목부터 할당
- `UPDATE assigned = 1` — 동시 요청 시 트랜잭션·락 고려 필요

8편 `assignEmail()`에 대응하는 서버 로직. 데모에서는 고정 문자열을 반환해도 된다.

---

## 설정 분리

비밀값은 `config.php`로 분리하고 저장소에서 제외한다.

```php
// config.php — gitignore
return [
    'client_id' => getenv('API_CLIENT_ID'),
    'client_secret' => getenv('API_CLIENT_SECRET'),
    'db_dsn' => getenv('DB_DSN'),
];
```

- `getenv(...)` — Apache/Nginx·`.env`에서 주입; 코드에 하드코딩 금지
- `gitignore` — `config.php` 또는 `.env`가 커밋되지 않도록 설정
- 비밀값은 저장소에 넣지 않는다

---

## Vue ↔ PHP 계약 (데모)

| act | 요청 body | 응답 |
|-----|-----------|------|
| `check_status` | `{ payload: { form } }` | `{ registered: bool }` |
| `register` | `{ payload: { form, authSession } }` | `{ needSmsAuth?, success? }` |
| `fetch_profile` | `{ payload: { form } }` | `{ profile: object }` |

필드명을 문서화해 두면 프론트·백엔드를 독립적으로 교체하기 쉽다.

---

## 시리즈 마무리

| # | 주제 |
|---|------|
| 0~1 | 환경·학습 경로 |
| 2~6 | Vue 3 SPA 기초 |
| 7 | computed·실시간 UI |
| 8 | Axios 다단계 폼 |
| 9 | (이 글) PHP act 게이트웨이 |

WebView·Python 아카이브와 병행하면 **SPA + 레거시 PHP API** 스택까지 기술 문서로 정리할 수 있다.

**교차 참고**: [Python 자동화 아카이브](../python-automation/README.md), [Kotlin WebView 시리즈](../kotlin-webview/README.md), [Flutter WebView 시리즈](../flutter-webview/README.md), [React Native WebView 시리즈](../react-native-webview/README.md).
