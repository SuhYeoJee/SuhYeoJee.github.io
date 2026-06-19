---
title: React Native WebView — 셸 개요
description: ""
date: 2026-06-17T14:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - WebView
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

React Native **WebView 하이브리드 셸**은 네이티브 UI를 직접 짜지 않고, 고정 **HOME URL**을 로드하는 앱 골격이다.
`.env`로 URL·기능을 바꿔 같은 골격을 재사용하는 패턴이 흔하고, 템플릿이 최소 셸부터 Navigation 듀얼·통합(Analytics·AdMob·FCM)까지 점진적으로 기능이 쌓인다.

이 글은 그 진화와 **빌드 프로젝트 4종**의 역할을 **기술 아카이브** 관점에서 정리한다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

> **면책** — 학습·설계 패턴 공유 목적이다. 예제는 데모 URL·Google 테스트 AdMob ID만 사용한다. **본인이 관리·배포 권한이 있는 앱**에만 적용하고, Play 정책·AdMob·Firebase 약관을 준수한다.

---

## 무엇을 하는 앱인가

1. 앱 실행 → 고정 **HOME URL** 로드
2. 같은 도메인은 WebView 안에서 이동
3. 외부 도메인·스토어 링크는 별도 WebView 스택 또는 외부 앱
4. 하드웨어 뒤로가기: `canGoBack`이면 `goBack()`, 아니면 종료 확인
5. (선택) `.env` 기능 플래그, Firebase Analytics, AdMob, FCM, 공유 FAB

[Flutter WebView 시리즈](../flutter-webview/README.md) 1편·[Kotlin WebView 시리즈](../kotlin-webview/README.md) 1편과 목표는 같다. 구현만 RN `react-native-webview` + Navigation에 맞춘다.

---

## 프로젝트 종류

| 종류 | 역할 | 이 시리즈 편 |
|------|------|-------------|
| **최소 템플릿** | WebView + 뒤로가기만, 의존성 최소 | 2~3편 |
| **설정형 템플릿** | `.env`, Firebase, Navigation, 듀얼 WV 진화 | 4~8편 |
| **Navigation 듀얼** | Main/Sub Navigation 스택 듀얼 WebView | 5편 |
| **통합 템플릿** | Firebase + AdMob + FCM + 공유 | 7~11편 |

내부 폴더명·버전 번호는 글에 쓰지 않는다.

---

## 템플릿 진화 (개념)

| 단계 | 특징 | 편 |
|------|------|-----|
| 외부 브라우저만 | 외부 URL → 항상 브라우저 | 7편 |
| 듀얼 (상태 비유지) | WebView/브라우저 선택, 홈 입력값 **유지 안 됨** | 6편 (대비) |
| 스크린 듀얼 | 듀얼 WebView, **홈 WebView 상태 유지** | 6편 |
| ref 배열 스택 | 스크린 듀얼 + WebView ref 배열(동적 스택) | 6편 보조 |
| Navigation 듀얼 | Main/Sub, `react-native-config` | 4~5편 |
| 통합 템플릿 | Analytics, AdMob, FCM, Notifee, 공유 | 8~11편 |

공통: 뒤로가기·종료 팝업, `.env` 옵션, 스플래시 시간 설정.

---

## 공통 파일 구조

```
프로젝트/
├── App.js                 # Navigation·WebView 화면
├── src/WebView.js         # (Navigation 듀얼) 공통 WebView 컴포넌트
├── .env                   # HOME_URL, 기능 플래그 (gitignore)
├── FCMService.js          # (통합 템플릿) 푸시
├── AdmobService.js        # (통합 템플릿) 전면 광고
└── android/               # SplashActivity 등 네이티브 훅
```

- **`.env`** — 앱마다 URL·기능 on/off (4편, 11편)
- **`react-native-config`** — JS에서 `Config.HOME_URL` 형태로 읽기
- **Navigation** — 듀얼 WebView를 스크린으로 나누는 Navigation 듀얼 패턴 (5편)

---

## 안 쓸 것 (시리즈 원칙)

- 실 서비스 URL, Firebase·AdMob 실 ID
- 내부 템플릿 코드명을 그대로 블로그 제목에 노출
- `node_modules` 복사본

데모 URL은 `https://example.com`, 도메인은 `example.com` placeholder만 사용한다.

---

## 시리즈 읽는 순서

| # | 제목 |
|---|------|
| 0 | React Native WebView — Android·Metro 실행 |
| 1 | (이 글) 셸 개요 |
| 2 | 최소 WebView 셸 |
| 3 | 하드웨어 뒤로가기·종료 |
| 4 | react-native-config |
| 5 | Navigation 듀얼 WebView |
| 6 | 스크린 듀얼 WebView |
| 7 | 외부 링크·공유 |
| 8 | Firebase Analytics·웹 브릿지 |
| 9 | AdMob |
| 10 | FCM·Notifee |
| 11 | 스플래시·보안·설정 |

**교차 참고**: [Kotlin 5편](../kotlin-webview/posts/05-dual-webview-domain-routing.md)·[Flutter 3편](../flutter-webview/posts/03-dual-webview.md) (듀얼 WebView), Kotlin 6~8편 (AdMob·FCM·설정).
