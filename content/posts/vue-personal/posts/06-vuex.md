---
title: Vue 3 — Vuex
description: ""
date: 2026-06-17T23:00:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Vuex
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

**Vuex 4**는 Vue 3와 함께 쓰는 전역 상태 저장소다.
`state → getters → mutations` 단방향 흐름만 다룬다. `actions`·`modules`는 필요 시 확장한다.

---

## store.js

전역 `count`와 파생 `score`, 변경용 `increment` mutation을 정의한다.

```javascript
import { createStore } from 'vuex';

export default createStore({
  state() {
    return { count: 0 };
  },
  getters: {
    score: (state) => state.count * 100,
  },
  mutations: {
    increment(state) {
      state.count += 1;
    },
  },
});
```

- `state()` — 함수 형태; 모듈 복제 시 독립 state 보장
- `getters.score` — `state.count`에서 파생; 컴포넌트 `computed`와 유사
- `mutations.increment` — **유일한** state 변경 경로; 동기 함수만

앱에 store를 등록한다.

```javascript
// main.js
import store from './store';
createApp(App).use(store).mount('#app');
```

- `.use(store)` — 모든 하위 컴포넌트에 `$store` 주입
- Router와 마찬가지로 `mount` 전에 등록

---

## Options API 컴포넌트

`$store`로 state·getter를 읽고, `commit`으로 mutation을 호출한다.

```vue
<template>
  <h1>{{ count }}</h1>
  <button type="button" @click="inc">+1</button>
  <p>score: {{ score }}</p>
</template>

<script>
export default {
  computed: {
    count() {
      return this.$store.state.count;
    },
    score() {
      return this.$store.getters.score;
    },
  },
  methods: {
    inc() {
      this.$store.commit('increment');
    },
  },
};
</script>
```

- `this.$store.state.count` — state 직접 읽기 (대입은 금지)
- `this.$store.getters.score` — 파생 값 조회
- `this.$store.commit('increment')` — mutation 이름으로 변경 요청
- state는 **직접 대입하지 않음** → `commit`으로 mutation 호출

---

## Composition API — useStore

`setup()` 안에서는 `useStore()`로 동일한 store에 접근한다.

```javascript
import { useStore } from 'vuex';
import { computed } from 'vue';

export default {
  setup() {
    const store = useStore();
    const count = computed(() => store.state.count);
    const inc = () => store.commit('increment');
    return { count, inc };
  },
};
```

- `useStore()` — inject된 store 인스턴스; `setup`·`<script setup>` 전용
- `computed(() => store.state.count)` — store state를 반응형 ref로 래핑
- `store.commit('increment')` — Options API와 동일한 mutation 호출

---

## Pinia

Vue 3 **신규** 프로젝트는 Pinia가 공식 권장이다.

| | Vuex 4 | Pinia |
|--|--------|-------|
| 변경 | mutations 필수 | store action에서 직접 변경 |
| 분할 | namespaced modules | domain별 store 파일 |

Vuex 문법은 기존 코드베이스 유지보수에 필요하다.

---

## 7편으로

전역 store 없이 **computed + 단일 컴포넌트**만으로 UI를 만드는 패턴을 7편에서 다룬다.
