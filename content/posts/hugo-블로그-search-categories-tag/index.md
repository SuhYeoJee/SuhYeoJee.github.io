---
title: Hugo 블로그 Search, Categories, Tag
description: ""
date: 2025-12-29T08:52:43.162Z
preview: ""
tags: ["Hugo", "PaperMod", "Search", "Categories"]
categories: ["Tech"]
series: ["Hugo 블로그 세팅"]
---


Hugo의 **PaperMod** 테마에서 검색(Search) 기능과 카테고리(Categories) 모아보기 메뉴를 활성화하는 방법을 정리합니다.

---

## 1. 검색(Search) 기능 활성화

PaperMod는 자체적으로 로컬 검색 기능을 지원합니다. 이를 위해 검색 페이지를 만들고 인덱스를 생성해야 합니다.

### Step 1: 검색 전용 페이지 생성
터미널에서 다음 명령어를 실행하여 검색용 파일을 생성합니다.

```powershell
hugo new search.md
```

### Step 2: `content/search.md` 설정
생성된 파일을 열고 아래 내용을 작성합니다.

```markdown
---
title: "Search"
layout: "search"
summary: "search"
placeholder: "검색어를 입력하세요..."
---
```

### Step 3: `hugo.toml` 인덱스 설정
검색 데이터가 담길 JSON 파일을 생성하도록 설정 파일에 추가합니다.

```toml
[outputs]
    home = ["HTML", "RSS", "JSON"]

[[menu.main]]
    identifier = "search"
    name = "Search"
    url = "/search/"
    weight = 10
```

---

## 2. 카테고리 및 태그 메뉴 추가

글을 쓸 때 설정한 카테고리와 태그를 메인 메뉴에서 한눈에 볼 수 있도록 연결합니다.

### `hugo.toml` 메뉴 설정
설정 파일의 `[[menu.main]]` 섹션에 아래 내용을 추가합니다.

```toml
[[menu.main]]
    identifier = "categories"
    name = "Categories"
    url = "/categories/"
    weight = 20

[[menu.main]]
    identifier = "tags"
    name = "Tags"
    url = "/tags/"
    weight = 30
```

---

## 3. 부가 기능 설정 (선택 사항)

블로그를 더 편리하게 만들기 위해 `[params]` 섹션에 아래 옵션들을 추가하면 좋습니다.

```toml
[params]
    ShowPostNavLinks = true    # 이전글/다음글 링크
    ShowCodeCopyButtons = true # 코드 복사 버튼
    ShowBreadCrumbs = true     # 브레드크럼 (계층 구조 표시)
```

---

## 🚀 적용하기

1. 위의 수정 사항을 저장합니다.
2. 아래 명령어로 GitHub에 푸시합니다.

```powershell
git add .
git commit -m "feat: Add search page and navigation menus"
git push origin main
```

이제 잠시 후 블로그 상단 메뉴에서 **Search**와 **Categories**를 확인하실 수 있습니다!