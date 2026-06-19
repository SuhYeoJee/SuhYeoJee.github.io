---
title: Vue 3 — v-model·속성 바인딩
description: ""
date: 2026-06-17T21:00:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Options API
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

Vue 3 **Options API**에서 템플릿과 `data`를 연결하는 기본이다.
양방향 바인딩(`v-model`)과 DOM 속성·클래스·스타일 바인딩을 하나의 `BindingDemo.vue` view로 정리한다.

`src/views/BindingDemo.vue`를 만들고 5편에서 route `/binding`으로 등록하면 된다.

---

## v-model — 텍스트·숫자·select

`v-model`은 입력 요소와 `data`를 **양방향**으로 묶는다. 텍스트·숫자·select 세 가지 기본 패턴을 한 파일에 모아 둔다.

```vue
<template>
  <input type="text" v-model="valueModel" />
  <p>{{ valueModel }}</p>

  <input type="number" v-model.number="numberModel" />
  <p>{{ numberModel }}</p>

  <select v-model="selectModel">
    <option value="1">옵션1</option>
    <option value="2">옵션2</option>
  </select>
</template>

<script>
export default {
  data() {
    return {
      valueModel: 'text',
      numberModel: 13,
      selectModel: 2,
    };
  },
};
</script>
```

- `v-model="valueModel"` — 입력값 ↔ `data.valueModel` 자동 동기화
- `v-model.number` — 문자열 입력을 숫자로 캐스팅 (`.number` 수식어)
- `select`의 `option value`와 `selectModel` 타입(문자/숫자)을 일치시켜야 선택이 맞게 반영된다
- `{{ valueModel }}` — mustache로 현재 값을 화면에 즉시 표시

---

## checkbox·radio

체크박스는 **다중 선택(배열)**, 라디오는 **단일 선택(문자열)** 로 `v-model` 타입이 달라진다.

```vue
<label><input type="checkbox" v-model="checked" :value="ch1" /></label>
<p>체크: {{ checked }}</p>

<label><input type="radio" v-model="picked" :value="pi1" /></label>
<p>라디오: {{ picked }}</p>
```

- `v-model="checked"` + `:value="ch1"` — 체크 시 배열에 `ch1` 값이 push/pop
- `v-model="picked"` — 라디오 그룹 중 하나만 `picked`에 저장
- `:value` — `v-bind:value` 축약; 각 옵션의 실제 값을 지정

아래 `data`에서 초기 타입을 맞춰 둔다.

```javascript
data() {
  return {
    checked: [],   // checkbox 다중 → 배열
    ch1: '체크1',
    picked: '',    // radio 단일
    pi1: '라디오1',
  };
},
```

- `checked: []` — 체크박스 `v-model`은 배열이어야 다중 선택 가능
- `picked: ''` — 라디오는 단일 문자열(또는 숫자)로 하나만 유지
- `ch1`·`pi1` — 옵션 라벨과 별도로 실제 바인딩 값을 분리할 때 유용

---

## v-html

일반 mustache는 HTML을 **이스케이프**한다. 태그를 렌더링하려면 `v-html`을 쓴다.

```vue
<div>{{ raw_html_data }}</div>
<div v-html="raw_html_data"></div>
```

- `{{ raw_html_data }}` — `<p>` 등이 **문자 그대로** 출력됨
- `v-html="raw_html_data"` — 브라우저가 HTML로 파싱·렌더링

예시 데이터는 아래처럼 문자열로 둔다.

```javascript
raw_html_data: '<p style="color:red;">This is a red string.</p>',
```

- `raw_html_data` — 신뢰할 수 있는 HTML 문자열만 넣는다
- `v-html`은 **XSS 위험** — 사용자 입력·외부 API 응답에는 쓰지 않는다

---

## 속성·클래스·스타일 바인딩

정적 속성 대신 `data` 값에 따라 DOM 속성·클래스·스타일을 바꿀 때 `:`(v-bind)를 쓴다.

```vue
<img :src="imgSrc" />

<button :disabled="textValue === ''">Click</button>

<div :class="{ active: isActive, 'text-red': hasError }">Class Binding</div>
<div :class="[activeClass, errorClass]">Class Binding</div>
<div :style="inlineStyle">인라인 스타일</div>
```

- `:src="imgSrc"` — 이미지 URL을 동적으로 지정
- `:disabled="textValue === ''"` — 조건식 결과로 버튼 비활성화
- `:class="{ active: isActive }"` — 객체 문법: 키가 클래스명, 값이 true일 때 적용
- `:class="[activeClass, errorClass]"` — 배열 문법: 여러 클래스 문자열 결합
- `:style="inlineStyle"` — 객체 형태 인라인 스타일 바인딩

위 템플릿에 대응하는 `data` 예시다.

```javascript
data() {
  return {
    imgSrc: 'https://vuejs.org/images/logo.png',
    textValue: '',
    isActive: true,
    hasError: false,
    activeClass: 'active',
    errorClass: 'text-red',
    inlineStyle: { color: 'red', fontSize: '30px', fontWeight: 'bold' },
  };
},
```

- `imgSrc` — 외부 URL도 런타임에 교체 가능
- `textValue: ''` — 빈 문자열이면 버튼 `disabled`
- `inlineStyle` — camelCase 키(`fontSize`)로 CSS 속성 매핑
- 객체/class 배열/인라인 style 세 패턴 중 상황에 맞는 것을 선택한다

---

## 3편으로

커스텀 **디렉티브**(`v-pin`)는 3편에서 `directives` 옵션과 함께 다룬다. 2편 예제의 `select`에 붙일 수 있다.
