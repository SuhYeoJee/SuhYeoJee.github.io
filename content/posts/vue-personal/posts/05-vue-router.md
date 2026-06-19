---
title: Vue 3 — Vue Router
description: ""
date: 2026-06-17T22:30:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Vue Router
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

SPA에서 **URL ↔ 화면** 매핑은 Vue Router 4가 담당한다.
`App.vue`는 네비게이션 + `<router-view>`, 각 화면은 `views/` 아래 컴포넌트 하나씩 두는 구조가 일반적이다.

---

## router/index.js

경로·컴포넌트 매핑과 History 모드를 한 파일에 정의한다.

```javascript
import { createRouter, createWebHistory } from 'vue-router';
import HomeView from '@/views/HomeView.vue';
import BindingDemo from '@/views/BindingDemo.vue';

const routes = [
  { path: '/', name: 'home', component: HomeView },
  { path: '/binding', name: 'binding', component: BindingDemo },
  {
    path: '/about',
    name: 'about',
    component: () => import('@/views/AboutView.vue'),
  },
];

export default createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});
```

- `createWebHistory` — HTML5 History API (`/about` 등 깔끔한 URL)
- `path` + `component` — URL 패턴과 렌더할 뷰 컴포넌트
- `name: 'binding'` — `router-link :to="{ name: 'binding' }"` 등 프로그래밍 네비게이션에 사용
- `() => import(...)` — dynamic import; 해당 route 진입 시에만 청크 로드 (code splitting)
- `import.meta.env.BASE_URL` — Vite 기준 public path; Vue CLI는 `process.env.BASE_URL`

Vue CLI(Webpack) 프로젝트는 `process.env.BASE_URL`을 쓴다.

---

## App.vue · main.js

네비게이션 링크와 `<router-view>`로 현재 route 컴포넌트를 표시한다.

```vue
<template>
  <nav>
    <router-link to="/">Home</router-link>
    |
    <router-link to="/binding">Binding</router-link>
  </nav>
  <router-view />
</template>
```

- `<router-link to="/">` — 클릭 시 history push; 기본 `<a>` 대신 사용
- `<router-view />` — 현재 route에 맞는 컴포넌트가 여기 마운트
- 활성 링크에는 `router-link-active` 클래스가 자동 부여

Router를 Vue 앱에 플러그인으로 연결한다.

```javascript
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

createApp(App).use(router).mount('#app');
```

- `import router from './router'` — `createRouter`로 만든 인스턴스
- `.use(router)` — `$router`·`$route`·`<router-link>` 등 전역 등록
- `.mount('#app')` — Router 등록 후 마운트해야 navigation이 동작

활성 링크 스타일: `.router-link-exact-active { color: #42b983; }`

---

## 새 화면 추가 절차

1. `src/views/NewPage.vue` 작성
2. `router/index.js`에 `{ path, component }` 추가
3. `App.vue` nav에 `<router-link>` 추가

단일 화면 앱(7편 일정 목록, 8편 폼 only)은 router 없이 `App.vue` → 자식 하나만 두어도 된다.

---

## 6편으로

여러 화면이 공유하는 상태는 Vuex(또는 Pinia)로 분리한다.
