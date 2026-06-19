---
title: Vue 3 — 학습 경로 개요
description: ""
date: 2026-06-17T20:30:00.000Z
preview: ""
draft: false
tags:
    - Vue
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

Vue 3로 SPA를 만들 때 자주 거치는 레이어를 **한 시리즈**로 묶었다.
WebView·Python 아카이브와 별개로, **프론트 Vue + 선택적 PHP API** 패턴에 초점을 둔다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
특정 저장소나 연습 폴더를 전제하지 않는다. 0편에서 만든 `my-vue-app`에 각 편 스니펫을 적용하면 된다.

> **면책** — 학습·설계 패턴 공유 목적이다. 예제는 데모 값·목(mock) 응답만 사용한다. **본인이 관리·배포 권한이 있는 API·서버**에만 적용하고, 비밀키는 환경 변수로만 관리한다.

---

## 학습 경로

```
Options API — v-model, class/style 바인딩 (2편)
    → 컴포넌트·slot·디렉티브 (3편)
    → Composition API·플러그인 (4편)
    → Vue Router (5편)
    → Vuex (6편)
    → computed + 실시간 UI (7편)
    → Axios 다단계 폼 (8편)
    → PHP act 프록시 (9편)
```

2~6편은 **한 SPA 안에 주제별 view**를 두고 router로 나누는 구성을 권장한다. 7편은 단일 컴포넌트만으로도 충분하다.

---

## 권장 디렉터리 구조 (5편 이후)

```
src/
├── App.vue              # nav + router-view
├── main.js
├── router/index.js      # 5편
├── store.js             # 6편
├── composables/         # 4편 (useCalculator.js 등)
├── plugins/i18n.js      # 4편
├── components/          # 3편
└── views/               # 2~6편, 편마다 하나
```

새 주제를 연습할 때는 `views/`에 `.vue` 파일을 추가하고 `router/index.js`에 route만 등록하면 된다.

---

## Options API vs Composition API

| | Options API | Composition API |
|--|-------------|-----------------|
| 상태 | `data()` | `ref` / `reactive` |
| 파생 | `computed` | `computed()` |
| 로직 재사용 | mixin | composable |
| 2~3·6~7편 | 주로 사용 | — |
| 4·8편 | 혼용 가능 | composable 권장 |

신규 프로젝트는 `<script setup>` + composable이 일반적이지만, Options API 문법은 레거시 코드 읽기·Vuex 4 연동에 여전히 필요하다.

---

## 작성 원칙

- 실 API 키·실 URL·업체 전용 응답 코드 미사용
- 스니펫은 데모 값·목 응답만 사용
- `draft: true`, 시리즈 간 수동 next/prev 링크 없음

---

## 시리즈 목차

| # | 제목 |
|---|------|
| 0 | Vue 3 — Vue CLI·로컬 실행 |
| 1 | (이 글) Vue 3 — 학습 경로 개요 |
| 2 | v-model·속성 바인딩 |
| 3 | 컴포넌트·디렉티브 |
| 4 | Composition API·플러그인 |
| 5 | Vue Router |
| 6 | Vuex |
| 7 | computed·실시간 목록 강조 |
| 8 | Axios 다단계 폼 |
| 9 | PHP act 프록시 |
