---
title: Vue 3 — Vue CLI·로컬 실행
description: ""
date: 2026-06-17T20:00:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Setup
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

이 시리즈는 **Vue CLI 5 + Vue 3** 기준이다.
각 편의 스니펫은 빈 Vue 프로젝트를 만든 뒤, 해당 편에서 안내하는 파일에 붙여 넣어 실행한다.

> **참고** — Vue 공식은 [create-vue](https://github.com/vuejs/create-vue)(Vite) 스캐폴딩을 권장한다. 이 시리즈는 **Vue CLI 5** 기준 스니펫이지만, Router·Vuex·Axios 패턴은 Vite 프로젝트에도 동일하게 적용할 수 있다.

---

## Node.js

Node 18 LTS 권장. 아래로 설치 여부와 npm 버전을 확인한다.

```bash
node --version
npm --version
```

- `node --version` — Node.js 런타임 버전 (18.x 권장)
- `npm --version` — 패키지 매니저; Vue CLI·의존성 설치에 사용

---

## Vue CLI 설치

프로젝트 스캐폴딩·개발 서버·빌드를 한 번에 제공하는 CLI를 전역 설치한다.

```bash
npm install -g @vue/cli
vue --version
```

- `npm install -g` — 시스템 전역에 CLI 설치 (한 번만 하면 됨)
- `vue --version` — `@vue/cli` 5.x가 잡혔는지 확인

---

## 프로젝트 생성

대화형 프롬프트에서 **Vue 3**·**Babel**을 선택한다. Router·Vuex는 5·6편 직전에 추가해도 된다.

```bash
vue create my-vue-app
# Vue 3, Babel 선택
# Router / Vuex는 5·6편 직전에 추가하거나 생성 시 함께 선택
cd my-vue-app
npm run serve
```

- `vue create my-vue-app` — `my-vue-app` 폴더에 기본 SPA 골격 생성
- `npm run serve` — Webpack dev server 기동; 기본 `http://localhost:8080`
- 파일 저장 시 **hot-reload** — 브라우저가 자동으로 갱신된다

---

## 편별 의존성

| 편 | 추가 패키지 |
|----|-------------|
| 2~4 | (없음, Vue CLI 기본) |
| 5 | `vue-router` |
| 6 | `vuex` |
| 8 | `axios` |
| 9 | PHP 웹서버 (Apache/Nginx + PHP) |

5·6·8편 진입 전에 한 번에 설치할 수 있다.

```bash
npm install vue-router@4 vuex@4 axios
```

- `vue-router@4` — Vue 3용 Router (5편)
- `vuex@4` — Vue 3용 전역 store (6편)
- `axios` — HTTP 클라이언트 (8편); 9편 PHP 게이트웨이와 통신

8~9편은 프론트(Vue)와 백엔드(PHP)를 분리해 두고, 8편만 진행할 때는 **목(mock) API**로 대체해도 된다.

---

## ESLint

Vue CLI 기본 템플릿에는 ESLint가 포함되어 있다.

```bash
npm run lint
```

- `npm run lint` — `.vue`·`.js` 파일의 문법·스타일 규칙 검사
- CI나 커밋 전에 실행해 스니펫 붙여 넣기 실수를 줄인다

---

## 1편으로

시리즈 전체 학습 순서와 권장 디렉터리 구조는 1편에서 정리한다.
