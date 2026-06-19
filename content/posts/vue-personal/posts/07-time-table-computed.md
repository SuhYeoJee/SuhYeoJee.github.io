---
title: Vue 3 — computed·실시간 목록 강조
description: ""
date: 2026-06-17T23:30:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - computed
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

Router·Vuex 없이 **단일 컴포넌트**로 “현재 시각 기준 다음 일정 한 줄 강조” UI를 만든다.
`data`의 시각이 바뀔 때 **computed**가 목록 파싱 결과를 자동 갱신하는 패턴이 핵심이다.

`App.vue`를 아래 내용으로 교체하거나 `ScheduleView.vue`로 분리해도 된다.

---

## 템플릿

현재 시각과 파싱된 일정 목록을 렌더링한다. `isNext`인 행만 강조 클래스를 붙인다.

```vue
<template>
  <div class="schedule">
    <h1>{{ nowTime }}</h1>
    <ul>
      <li
        v-for="(row, idx) in parsedRows"
        :key="idx"
        :class="{ highlight: row.isNext }"
      >
        {{ row.text }}
      </li>
    </ul>
  </div>
</template>
```

- `{{ nowTime }}` — 0.5초마다 갱신되는 현재 시각 표시
- `v-for="(row, idx) in parsedRows"` — computed가 만든 행 배열 순회
- `:key="idx"` — 리스트 렌더링 시 Vue diff 힌트 (데모에서는 인덱스 사용)
- `:class="{ highlight: row.isNext }"` — 다음 일정 한 줄만 `highlight` 클래스

---

## data · lifecycle · timer

`nowTime`을 주기적으로 갱신하면 연쇄적으로 `parsedRows` computed가 다시 계산된다.

```javascript
function formatTime(date) {
  const h = String(date.getHours()).padStart(2, '0');
  const m = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${h}:${m}:${s}`;
}

export default {
  data() {
    return {
      nowTime: formatTime(new Date()),
      scheduleText:
        '\n09:00 팀 미팅\n09:30 스탠드업\n10:00 코드 리뷰\n11:00 점심\n13:00 개발\n',
      timerId: null,
    };
  },
  created() {
    this.timerId = setInterval(() => {
      this.nowTime = formatTime(new Date());
    }, 500);
  },
  beforeUnmount() {
    clearInterval(this.timerId);
  },
};
```

- `formatTime` — `HH:MM:SS` zero-pad; 문자열 비교에 활용
- `scheduleText` — 줄바꿈 구분 원시 텍스트; 실제 앱에서는 API 응답으로 대체
- `setInterval(..., 500)` — 0.5초마다 `nowTime` 갱신 → computed 트리거
- `beforeUnmount` + `clearInterval` — 컴포넌트 제거 시 타이머 누수 방지

`nowTime` 변경 → `parsedRows` computed 재실행.

---

## computed — parsedRows

`scheduleText`를 줄 단위로 나누고, 현재 시각보다 뒤인 **첫 줄**만 `isNext`로 표시한다.

```javascript
computed: {
  parsedRows() {
    let marked = false;
    const hhmm = this.nowTime.slice(0, 5); // "HH:MM"

    return this.scheduleText.split('\n').map((line) => {
      const row = { text: line, isNext: false };
      const lineTime = line.trim().split(' ')[0];

      if (!marked && lineTime && lineTime > hhmm) {
        marked = true;
        row.isNext = true;
      }
      return row;
    });
  },
},
```

- `this.nowTime.slice(0, 5)` — 초 단위 제외 `HH:MM`만 추출
- `split('\n')` — 멀티라인 문자열을 행 배열로 변환
- `lineTime` — 각 줄 앞의 `09:00` 같은 시각 토큰
- `lineTime > hhmm` — zero-pad된 문자열이라 **사전식 비교 = 시간 순서**
- `marked` — 다음 일정 **한 줄만** 강조; 이후 행은 `isNext` false 유지

---

## 스타일

`scoped`로 이 컴포넌트에만 적용되는 강조 스타일을 정의한다.

```vue
<style scoped>
.schedule {
  text-align: left;
}
ul {
  list-style: none;
  padding: 0;
}
li {
  font-size: 1.25rem;
}
.highlight {
  background: #ffeb3b;
}
</style>
```

- `scoped` — 다른 컴포넌트의 `ul`·`li`에 스타일이 새지 않음
- `.highlight` — `isNext` 행의 배경색; 접근성이 필요하면 대비율 조정

---

## 확장

| 방향 | 방법 |
|------|------|
| 데이터 소스 | `scheduleText` → API/JSON fetch |
| 지난 일정 | `lineTime <= hhmm`이면 `opacity: 0.5` |
| Composition API | `ref(nowTime)` + `computed(parsedRows)` |

---

## 8편으로

서버와 통신하는 **다단계 폼**은 Axios 편에서 다룬다.
