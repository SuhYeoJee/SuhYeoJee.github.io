---
title: Vue 3 — Composition API·플러그인
description: ""
date: 2026-06-17T22:00:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Composition API
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

Vue 3 **Composition API**는 로직을 함수(composable) 단위로 재사용한다.
`setup()` / `<script setup>`, 앱 **플러그인**, (레거시) **global mixin** 패턴을 정리한다.

---

## composable — useCalculator

상태·파생 값을 함수로 묶어 여러 컴포넌트에서 import해 쓴다.

```javascript
// composables/useCalculator.js
import { reactive, computed, toRefs } from 'vue';

export function useCalculator() {
  const state = reactive({
    num1: 0,
    num2: 0,
    sum: computed(() => Number(state.num1) + Number(state.num2)),
  });
  return toRefs(state);
}
```

- `reactive` — 객체 형태 reactive state; 프로퍼티 변경 시 반응
- `computed(() => ...)` — `num1`·`num2` 변경 시 `sum` 자동 재계산
- `toRefs(state)` — destructuring 후에도 각 ref가 reactivity 유지
- `export function` — composable은 이름 규칙 `useXxx`로 통일하면 찾기 쉽다

---

## Options API + setup()

`setup()`에서 composable을 호출하고, 반환값을 template에 노출한다.

```vue
<template>
  <input v-model="num1" v-focus />
  <span> + </span>
  <input v-model="num2" />
  <span> = {{ sum }}</span>
</template>

<script>
import { useCalculator } from '@/composables/useCalculator';

export default {
  setup() {
    const { num1, num2, sum } = useCalculator();
    return { num1, num2, sum };
  },
};
</script>
```

- `setup()` — `data`·`computed` 대신 Composition API 진입점
- `return { num1, num2, sum }` — 반환한 ref가 template에서 자동 unwrap
- `v-focus` — 3편 커스텀 디렉티브; 마운트 시 첫 입력에 포커스

`<script setup>`이면 `return` 없이 top-level binding이 template에 노출된다.

```vue
<script setup>
import { useCalculator } from '@/composables/useCalculator';
const { num1, num2, sum } = useCalculator();
</script>
```

- `<script setup>` — 보일러플레이트 제거; import·변수가 곧 template 바인딩
- `return` 불필요 — 컴파일러가 자동으로 노출 처리
- 신규 Vue 3 코드에서는 이 문법을 우선 권장

---

## 플러그인 — 간단 i18n

`app.use()`로 전역 `$t` 헬퍼와 `provide`를 한 번에 등록한다.

```javascript
// plugins/i18n.js
export default {
  install(app, messages) {
    app.config.globalProperties.$t = (key) =>
      key.split('.').reduce((obj, part) => obj?.[part], messages);
    app.provide('i18n', messages);
  },
};
```

- `install(app, messages)` — 플러그인 표준 시그니처; 두 번째 인자는 옵션
- `globalProperties.$t` — Options API에서 `this.$t('ko.greeting')` 사용
- `key.split('.').reduce(...)` — `'ko.greeting'`처럼 점 경로로 중첩 객체 탐색
- `app.provide('i18n', messages)` — Composition·inject 쪽에서도 동일 데이터 공유

`main.js`에서 메시지 객체와 함께 등록한다.

```javascript
// main.js
import i18nPlugin from './plugins/i18n';

const messages = {
  en: { greeting: 'Hello' },
  ko: { greeting: '안녕하세요' },
};

createApp(App).use(i18nPlugin, messages).mount('#app');
```

- `.use(i18nPlugin, messages)` — `install`의 `messages` 인자로 전달
- `messages` — 언어 코드별 중첩 객체; 실제 프로젝트는 JSON 파일로 분리 가능

템플릿·inject 두 가지 소비 방식이다.

```vue
<h2>{{ $t('ko.greeting') }}</h2>
```

- `$t('ko.greeting')` — globalProperties 경로; setup 없이 template에서 직접 호출

```javascript
export default { inject: ['i18n'] };
// template: {{ i18n.ko.greeting }}
```

- `inject: ['i18n']` — provide로 넣은 `messages` 전체를 컴포넌트에서 수신
- template에서 `i18n.ko.greeting` — Options API·Composition 모두 inject 가능

---

## global mixin (레거시) — HTTP 헬퍼

모든 컴포넌트에 `methods`를 주입하는 옛 패턴이다. 신규 코드에는 composable을 권장한다.

```javascript
// mixins/http.js
import axios from 'axios';

export default {
  methods: {
    async $fetch(url, method = 'GET', data) {
      const res = await axios({ method, url, data }).catch(console.error);
      return res?.data;
    },
  },
};
```

- `methods.$fetch` — 모든 컴포넌트에서 `this.$fetch(...)` 호출 가능
- `axios({ method, url, data })` — 공통 HTTP 래퍼
- `.catch(console.error)` — 실패 시 `undefined` 반환; 호출부에서 null 체크 필요

앱 생성 직후 mixin을 등록한다.

```javascript
app.mixin(httpMixin);
```

- `app.mixin` — **전역** 적용; 어느 컴포넌트에서 주입됐는지 추적이 어렵다
- 전역 mixin은 **추적이 어렵다**. 신규 코드는 `composables/useFetch.js`를 권장한다

---

## Options vs Composition

| | Options API | Composition API |
|--|-------------|-----------------|
| 상태 | `data()` | `ref` / `reactive` |
| 파생 | `computed` | `computed()` |
| 재사용 | mixin | composable |
| 8편 다단계 폼 | async methods | `useRegistrationFlow()`로 분리 가능 |

---

## 5편으로

화면 전환은 Vue Router로 분리한다.
