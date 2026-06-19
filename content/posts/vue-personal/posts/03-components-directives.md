---
title: Vue 3 — 컴포넌트·디렉티브
description: ""
date: 2026-06-17T21:30:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Components
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

단일 `.vue` 파일을 넘어 **부모·자식 컴포넌트**, **slot**, **provide/inject**, **커스텀 디렉티브**를 다룬다.
Vue 3에서는 디렉티브 훅 이름이 Vue 2와 다르다 (`mounted` 등).

---

## 자식 컴포넌트와 template ref

부모가 자식 컴포넌트 인스턴스에 `ref`로 접근해 내부 `data`를 읽는 패턴이다.

```vue
<!-- ParentView.vue -->
<template>
  <ChildPanel ref="childPanel" />
  <button type="button" @click="logChildMessage">로그 출력</button>
</template>

<script>
import ChildPanel from '@/components/ChildPanel.vue';

export default {
  components: { ChildPanel },
  computed: {
    childMessage() {
      return this.$refs.childPanel?.message;
    },
  },
  methods: {
    logChildMessage() {
      console.log(this.childMessage);
    },
  },
};
</script>
```

- `ref="childPanel"` — 템플릿 ref 이름; `this.$refs.childPanel`로 접근
- `components: { ChildPanel }` — 로컬 컴포넌트 등록
- `this.$refs.childPanel?.message` — optional chaining; 자식 `mounted` 전에는 `undefined`
- computed에서 `$refs`는 **자식 mounted 이후**에만 안정적으로 유효

자식은 노출할 `data`만 두면 된다.

```vue
<!-- ChildPanel.vue -->
<script>
export default {
  data() {
    return { message: 'hello from child' };
  },
};
</script>
```

- `message` — 부모가 `$refs`로 읽을 수 있는 인스턴스 프로퍼티
- 자식 템플릿이 없어도 `data`만으로 동작 가능

---

## slot — 레이아웃 컴포넌트

부모가 자식 레이아웃의 **빈 칸**에 마크업을 끼워 넣을 때 named slot을 쓴다.

```vue
<!-- 사용 측 -->
<ModalLayout>
  <template #header>
    <h1>제목</h1>
  </template>
  <template #default>
    <p>본문</p>
  </template>
  <template #footer>
    <button type="button">닫기</button>
  </template>
</ModalLayout>
```

- `#header` — `v-slot:header` 축약; named slot에 콘텐츠 전달
- `#default` — 이름 없는 기본 slot (생략 가능)
- `#footer` — 푸터 영역만 부모가 커스터마이즈

레이아웃 컴포넌트는 `<slot>`으로 받을 위치를 정의한다.

```vue
<!-- ModalLayout.vue -->
<template>
  <div class="modal">
    <header><slot name="header" /></header>
    <main><slot /></main>
    <footer><slot name="footer" /></footer>
  </div>
</template>
```

- `<slot name="header" />` — `#header`로 넘긴 내용이 여기 렌더링
- `<slot />` — default slot; `#default` 또는 이름 없는 자식 콘텐츠
- 레이아웃(껍데기)과 콘텐츠(내용)를 파일 단위로 분리할 수 있다

---

## provide / inject

props를 여러 단계 내려보내지 않을 때 조상이 `provide`, 후손이 `inject`로 값을 받는다.

```javascript
// ancestor
export default {
  data() {
    return { theme: 'dark' };
  },
  provide() {
    return { theme: this.theme };
  },
};

// descendant
export default {
  inject: ['theme'],
};
```

- `provide()` — 반환 객체의 키가 inject 키와 매칭
- `inject: ['theme']` — 조상 트리에서 `theme`를 찾아 인스턴스에 주입
- `this.theme`를 provide에 넣으면 **반응형 참조**로 전달 가능 (4편 i18n과 동일 메커니즘)

4편 i18n 플러그인도 `app.provide('i18n', options)`로 같은 메커니즘을 쓴다.

---

## 커스텀 디렉티브 — v-pin

요소를 viewport 기준 고정 좌표에 둘 때 커스텀 디렉티브로 DOM을 직접 조작한다.

```vue
<select v-model="value" v-pin="position" />
```

- `v-pin="position"` — `binding.value`로 `{ top, left }` 객체 전달
- `v-model`과 함께 써도 디렉티브는 독립적으로 동작

디렉티브 정의와 좌표 `data`는 같은 컴포넌트에 둔다.

```javascript
export default {
  directives: {
    pin: {
      mounted(el, binding) {
        el.style.position = 'fixed';
        el.style.top = `${binding.value.top}px`;
        el.style.left = `${binding.value.left}px`;
      },
    },
  },
  data() {
    return { value: '', position: { top: 50, left: 100 } };
  },
};
```

- `directives.pin` — 로컬 디렉티브; 템플릿에서 `v-pin`으로 사용
- `mounted(el, binding)` — Vue 3 훅; 요소가 DOM에 붙은 뒤 한 번 실행
- `binding.value` — `v-pin="position"`에 넘긴 객체
- `el.style.position = 'fixed'` — 스크롤과 무관하게 화면 좌표에 고정

---

## v-focus

마운트 시 입력 요소에 포커스를 주는 재사용 디렉티브다.

```javascript
directives: {
  focus: {
    mounted(el) {
      el.focus();
    },
  },
},
```

- `mounted(el)` — 연결된 DOM 요소(`input` 등)에 `focus()` 호출
- 로컬 `directives`에 두면 해당 컴포넌트에서만 `v-focus` 사용 가능

여러 컴포넌트에서 쓰면 `src/directives/focus.js`로 분리해 전역 등록한다.

```javascript
// main.js
import { focus } from './directives/focus';
app.directive('focus', focus);
```

- `app.directive('focus', focus)` — 앱 전역에서 `v-focus` 사용
- 디렉티브 객체를 export해 `mounted` 훅만 공유하는 패턴

---

## 4편으로

`<script setup>`·composable·플러그인은 Composition API 편에서 다룬다.
