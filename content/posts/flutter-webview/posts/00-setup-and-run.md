---
title: Flutter — 설치와 예제 실행
description: ""
date: 2026-06-16T09:55:00.000Z
preview: ""
draft: true
tags:
    - Flutter
    - Setup
    - Windows
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

## 개요

시리즈 시작 전에 Flutter 설치부터 예제 실행까지 한 번에 정리한다.
이 글만 끝내면 `examples/` 아래 예제를 바로 실행할 수 있다.

---

## 1) Flutter SDK 설치

Windows 기준으로 가장 단순한 순서:

1. Flutter SDK 압축 파일 다운로드 (공식 문서)
2. 원하는 위치에 압축 해제 (예: `C:\dev\flutter`)
3. 시스템 환경변수 `Path`에 `C:\dev\flutter\bin` 추가
4. 새 터미널 열고 버전 확인

```bash
flutter --version
```

버전이 나오면 PATH는 정상이다.

---

## 2) Android 실행 환경 준비

WebView 예제는 에뮬레이터나 실기기 1대만 있으면 된다.

1. [Android Studio 설치](https://developer.android.com/studio?hl=ko)
2. SDK Manager에서 기본 SDK 설치
3. **SDK Tools** 탭에서 **Android SDK Command-line Tools (latest)** 체크 후 설치
4. Device Manager에서 에뮬레이터 1개 생성
5. 에뮬레이터 실행

터미널 확인:

```bash
flutter devices
```

목록에 기기가 보이면 준비 완료.

---

## 3) 의존성 체크

처음 세팅 후 한 번은 꼭 실행:

```bash
flutter doctor
```

`[!]`가 남아 있으면 해당 항목만 고치면 된다.
보통 Android toolchain / licenses에서 막히는 경우가 많다.

#### cmdline-tools / sdkmanager 없음

`flutter doctor`에 아래가 보이면 **Command-line Tools**가 빠진 상태다.

```
✗ cmdline-tools component is missing.
✗ Android license status unknown.
```

`flutter doctor --android-licenses`를 실행해도 이렇게 나올 수 있다.

```
Android sdkmanager not found. Update to the latest Android SDK and ensure that the cmdline-tools are installed to resolve this.
```

`platform-tools`, `emulator` 등은 있어도 `cmdline-tools`가 없으면 `sdkmanager`를 찾지 못해 라이선스 명령이 동작하지 않는다.

**Android Studio에서 설치 (권장)**

1. **Settings** → **Languages & Frameworks** → **Android SDK**
2. **SDK Tools** 탭
3. **Android SDK Command-line Tools (latest)** 체크 → **Apply**

**환경 변수 설정**

SDK 기본 경로: `%LOCALAPPDATA%\Android\Sdk`

PowerShell (사용자 환경 변수):

```powershell
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")
$add = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools"
if ($path -notlike "*cmdline-tools*") {
  [System.Environment]::SetEnvironmentVariable("Path", "$path;$add", "User")
}
```

터미널을 **새로 연 뒤** 라이선스를 받는다.

```bash
flutter doctor --android-licenses
flutter doctor
```

모든 항목에 `y` 입력.

**Android Studio 없이 설치하는 경우**

[Command line tools only](https://developer.android.com/studio#command-line-tools-only)를 받아 아래 구조로 둔다. 폴더명 `latest`는 필수.

```
%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\
  bin\sdkmanager.bat
  ...
```

위 환경 변수 설정 후 `flutter doctor --android-licenses`를 다시 실행한다.

---

## 4) 예제 실행 공통 패턴

이 시리즈 예제 폴더는 플랫폼 폴더를 제외하고 커밋되어 있다.
그래서 각 예제에서 한 번씩 `flutter create .`를 먼저 실행한다.

```bash
cd blog/flutter-webview/examples/01_basic_webview
flutter create . --project-name basic_webview
flutter pub get
flutter run
```

다른 예제도 동일:

- `03_dual_webview` → `--project-name dual_webview`
- `04_web_to_native_fab` → `--project-name web_to_native_fab`

---

## 5) 자주 막히는 포인트

- `flutter` 명령어가 없음  
  → PATH 설정 후 **터미널 재시작**

- `cmdline-tools component is missing` / `sdkmanager not found`  
  → SDK Tools에서 **Command-line Tools (latest)** 설치  
  → `ANDROID_HOME` 설정 후 `flutter doctor --android-licenses` (3절 참고)

- Android 기기가 안 잡힘  
  → 에뮬레이터 실행 상태 확인 + `flutter devices`

- Gradle 에러  
  → Android Studio로 SDK 설치 상태 먼저 확인

- 웹뷰가 빈 화면  
  → 에뮬레이터 네트워크, 외부 URL 차단 여부 확인  
  (이 시리즈는 기본적으로 `assets/demo/*.html`도 같이 제공)
