---
title: Vue 3 — Axios 다단계 폼
description: ""
date: 2026-06-18T00:00:00.000Z
preview: ""
draft: false
tags:
    - Vue
    - Axios
categories:
    - Manual
series: ["Vue 3 아카이브"]
---

## 개요

외부 API 연동 폼은 **한 번의 클릭 → 여러 HTTP 단계**로 이어지는 경우가 많다.
가입 여부 확인 → (미가입) 등록·2차 인증 → (가입) 정보 조회처럼 **상태 머신**을 async/await로 직렬화하는 패턴을 정리한다.

백엔드는 9편 PHP `act` 프록시 또는 목(mock) JSON API를 사용한다. 실 API 키·업체 코드는 다루지 않는다.

---

## App · RegistrationForm

폼 로직은 전용 컴포넌트로 분리하고 `App.vue`는 껍데기만 둔다.

```vue
<!-- App.vue -->
<template>
  <RegistrationForm />
</template>

<script>
import RegistrationForm from '@/components/RegistrationForm.vue';
export default { components: { RegistrationForm } };
</script>
```

- `<RegistrationForm />` — 다단계 폼·API 호출을 한 컴포넌트에 캡슐화
- `components: { RegistrationForm }` — 로컬 등록; 라우터 없이 단일 화면 앱 가능

로직이 길어지면 `composables/useRegistrationFlow.js`로 분리한다.

---

## state 구조

폼 입력·잠금 플래그·2차 인증 세션을 `data`에 명시적으로 나눈다.

```javascript
data() {
  return {
    apiUrl: '/api/gateway.php',
    debugJson: '',
    formLocked: false,
    form: {
      userName: '',
      phoneNo: '',
      email: '',
    },
    authSession: {
      sessionId: '',
      method: '',
      smsCode: '',
      emailCode: '',
    },
  };
},
```

- `apiUrl` — 9편 PHP 게이트웨이 단일 엔드포인트
- `formLocked` — 2차 인증 대기 중 입력·재제출 방지
- `form` — 사용자 입력; 모든 `act` 요청의 `payload.form`에 포함
- `authSession` — 서버가 돌려준 **추가 인증 세션**; 다음 요청에 그대로 재전송
- `debugJson` — 개발 중 raw 응답을 textarea에 표시

| 필드 | 역할 |
|------|------|
| `formLocked` | 2차 인증 대기 중 입력 비활성 |
| `authSession` | 서버가 돌려준 **추가 인증 세션** — 다음 요청에 그대로 재전송 |

---

## 오케스트레이션 — handleSubmit

클릭 한 번으로 등록 확인 → 분기 → 재귀 조회까지 이어지는 **상태 머신**이다.

```javascript
async handleSubmit(isRegistered = null) {
  if (isRegistered === null) {
    this.debugJson = 'checking registration...';
    isRegistered = await this.checkRegistration();
  }

  if (isRegistered) {
    const data = await this.fetchProfile();
    this.debugJson = JSON.stringify(data, null, 2);
    return;
  }

  if (!this.form.email) {
    await this.assignEmail();
  }

  isRegistered = await this.submitRegistration();
  if (isRegistered) {
    await this.handleSubmit(true);
  }
},
```

- `isRegistered === null` — 최초 진입; 가입 여부 API 호출
- `isRegistered === true` — 가입 완료 → 프로필 조회 후 종료
- `!this.form.email` — 이메일 미할당 시 서버·큐에서 할당 (`assignEmail`)
- `submitRegistration` 성공 후 `handleSubmit(true)` — 재귀 호출로 조회 플로우 진입
- 분기 순서: **등록 여부 → 조회 또는 등록 플로우 → 성공 시 재귀 조회**

---

## Axios — act 기반 POST

프론트는 URL 하나, body의 `act`로 동작을 구분한다 (9편 백엔드와 계약).

```javascript
import axios from 'axios';

async checkRegistration() {
  const { data } = await axios.post(this.apiUrl, {
    act: 'check_status',
    payload: { form: this.form },
  });
  return data.registered === true;
},

async submitRegistration() {
  this.formLocked = true;
  const { data } = await axios.post(this.apiUrl, {
    act: 'register',
    payload: { form: this.form, authSession: this.authSession },
  });

  if (data.needSmsAuth) {
    alert('SMS 인증번호를 입력하세요');
    return false;
  }
  if (data.success) {
    this.formLocked = false;
    return true;
  }
  this.formLocked = false;
  return false;
},
```

- `act: 'check_status'` — 서버 디스패치 키; 9편 `ApiGateway` 메서드명과 1:1
- `payload: { form }` — Vue·PHP 간 공통 스키마
- `data.registered === true` — 업체 `CF-xxxxx` 코드를 boolean으로 래핑한 예
- `formLocked = true` — 장시간 API 구간에서 중복 제출 방지
- `needSmsAuth` — 2차 인증 필요; UI에서 코드 입력 후 `submitRegistration` 재호출
- `authSession` — SMS·이메일 코드를 다음 `register` 요청에 전달

업체 API는 `CF-xxxxx` 같은 **결과 코드**로 분기하는 경우가 많다. 프론트에서는 `needSmsAuth`, `success`처럼 **의미 있는 boolean**으로 래핑하는 편이 읽기 쉽다.

---

## 2차 인증 UI

인증번호 입력과 디버그 출력용 textarea를 template에 둔다.

```vue
<input v-model="authSession.smsCode" />
<button type="button" @click="handleSubmit(false)">SMS 인증</button>

<textarea v-model="debugJson" readonly />
```

- `v-model="authSession.smsCode"` — 2차 인증 코드를 세션 객체에 보관
- `@click="handleSubmit(false)"` — 가입 완료가 아닌 등록·인증 플로우 재개
- `readonly` + `debugJson` — API 응답 확인용; 프로덕션에서는 제거

인증번호 입력 후 같은 `submitRegistration`을 재호출해 `authSession`을 서버에 넘긴다.

---

## 패턴 요약

| 패턴 | 설명 |
|------|------|
| `act` 파라미터 | 단일 엔드포인트, 서버 측 디스패치 |
| `formLocked` | 장시간 API 구간 UX |
| `authSession` 보존 | 멀티 스텝 인증 |
| `debugJson` | 개발 중 raw 응답 확인 |

---

## 9편으로

`act`를 처리하는 PHP 게이트웨이 구조는 9편에서 다룬다.
