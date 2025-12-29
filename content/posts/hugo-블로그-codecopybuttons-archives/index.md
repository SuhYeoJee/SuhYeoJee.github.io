---
title: Hugo 블로그 CodeCopyButtons, Archives, Toc
description: ""
date: 2025-12-29T09:03:41.176Z
preview: ""
tags:
    - Hugo
    - PaperMod
    - Archive
    - UI
    - TOC
categories:
    - Tech
series: ["Hugo 블로그 세팅"]
---


블로그의 가독성과 편의성을 높이기 위해 **전체 글 타임라인(Archive)** 과 **코드 블록 복사 버튼** 기능을 추가했습니다. 적용 방법은 다음과 같습니다.

---

## 1. 코드 블록 복사 버튼 활성화

PaperMod 테마는 코드 복사 기능을 내장하고 있습니다. 설정 파일에서 옵션만 켜주면 마우스를 코드 블록 위에 올렸을 때 복사 버튼이 나타납니다.

### 설정 방법
`hugo.toml` 파일을 열고 `[params]` 섹션에 아래 내용을 추가합니다.

```toml
[params]
    ShowCodeCopyButtons = true # 코드 복사 버튼 활성화
```

## 2. 목차 (Table of Contents) 활성화

글의 구조를 한눈에 파악할 수 있도록 목차 기능을 켰습니다.

### 설정 방법
`hugo.toml`의 `[params]` 섹션에 아래 설정을 추가합니다.

```toml
[params]
    showToc = true           # 모든 포스트에 목차 표시
    TocOpen = false          # 페이지 로드 시 목차를 펼쳐둘지 여부
```

특정 포스트에서만 목차를 끄고 싶다면, 해당 글의 상단(`Front Matter`)에 `showToc: false`를 적어주면 됩니다.


---

## 3. 아카이브(Archive) 페이지 추가

작성한 모든 글을 연도별로 모아볼 수 있는 아카이브 페이지를 생성합니다.

### Step 1: 아카이브 파일 생성
터미널에서 아래 명령어를 입력합니다.

```powershell
hugo new archives.md
```

### Step 2: `content/archives.md` 수정
파일을 열어 아래와 같이 레이아웃을 지정합니다.

```markdown
---
title: "Archive"
layout: "archives"
url: "/archives"
summary: "archives"
---
```

### Step 3: 메인 메뉴에 연결
`hugo.toml`의 메뉴 설정 섹션에 아카이브 경로를 추가합니다.

```toml
[[menu.main]]
    identifier = "archives"
    name = "Archive"
    url = "/archives/"
    weight = 5
```

---

## 🚀 적용 결과 확인

설정을 마친 후 아래 명령어로 배포를 진행합니다.

```powershell
git add .
git commit -m "feat: Add Archive page and enable Code Copy button, TOC."
git push origin main
```

이제 블로그 상단 메뉴의 **Archive**를 클릭하면 연도별로 정리된 포스트 목록을 볼 수 있으며, 코드 블록에서는 편리한 복사 기능을 사용할 수 있습니다! 🥳