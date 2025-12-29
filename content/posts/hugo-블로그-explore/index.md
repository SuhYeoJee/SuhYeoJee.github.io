---
title: Hugo 블로그 Explore
description: ""
date: 2025-12-29T10:19:24.000Z
preview: ""
tags: ["Hugo", "UX", "Layout", "Partial"]
categories: ["Tech"]
series: ["Hugo 블로그 세팅"]
draft: false
---

이것저것 만드니까 더러워서 합쳐달라고 함. 

---

## 🏗️ 1. 검색창의 부품화 (Partial)

가장 먼저, 기존 검색 페이지에 종속되어 있던 검색창 코드를 어디서든 불러올 수 있도록 '부품(Partial)'으로 분리합니다.

**파일 경로:** `layouts/partials/search_box.html`

```html
<div id="searchbox">
    <input id="searchInput" autofocus placeholder="검색어를 입력하세요..."
        aria-label="search" type="search" autocomplete="off">
    <ul id="searchResults" aria-label="search results"></ul>
</div>

{{- /* 테마의 검색 스크립트 로드 */ -}}
{{- $js := resources.Get "js/search.js" -}}
{{- if $js -}}
    {{- $secureJS := $js | minify | fingerprint -}}
    <script defer src="{{ $secureJS.RelPermalink }}" integrity="{{ $secureJS.Data.Integrity }}"></script>
{{- end -}}
```

---

## 🧭 2. 통합 탐색 레이아웃 생성

이제 분리한 검색창과 함께 카테고리, 시리즈, 태그를 한눈에 보여줄 레이아웃을 만듭니다.

**파일 경로:** `layouts/_default/explore.html`

```html
{{- define "main" -}}

<header class="page-header">
    <h1>Explore</h1>
  {{- if .Description }}
  <div class="post-description">
    {{ .Description }}
  </div>
  {{- end }}
  <p>　</p>
</header>

<div class="explore-container">
    <section style="margin-bottom: 50px;">
        <h2 style="margin-bottom: 20px;">Search</h2>
        {{- partial "search_box.html" . -}} 
        </section>

    <hr style="border: 0; border-top: 1px solid var(--border); margin: 40px 0;">

    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 30px;">
        <section>
            <h2 style="margin-bottom: 20px;">Categories</h2>
            <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                {{- range $name, $taxonomy := .Site.Taxonomies.categories -}}
                <a href="{{ "/categories/" | relLangURL }}{{ $name | urlize }}/" style="padding: 8px 15px; background: var(--code-bg); border-radius: 8px; border: 1px solid var(--border);">
                    {{ $name }} <span style="font-size: 0.8em; opacity: 0.6;">({{ $taxonomy.Count }})</span>
                </a>
                {{- end -}}
            </div>
        </section>

        <section>
            <h2 style="margin-bottom: 20px;">Series</h2>
            <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                {{- range $name, $taxonomy := .Site.Taxonomies.series -}}
                <a href="{{ "/series/" | relLangURL }}{{ $name | urlize }}/" style="padding: 8px 15px; background: var(--tertiary); border-radius: 8px;">
                    {{ $name }} <span style="font-size: 0.8em; opacity: 0.6;">({{ $taxonomy.Count }})</span>
                </a>
                {{- end -}}
            </div>
        </section>
    </div>

    <hr style="border: 0; border-top: 1px solid var(--border); margin: 40px 0;">

    <section>
        <h2 style="margin-bottom: 20px;">Tags</h2>
        <div style="display: flex; flex-wrap: wrap; gap: 10px;">
            {{- range $name, $taxonomy := .Site.Taxonomies.tags -}}
            <a href="{{ "/tags/" | relLangURL }}{{ $name | urlize }}/" style="padding: 8px 15px; background: var(--tertiary); border-radius: 8px;">
                #{{ $name }}
            </a>
            {{- end -}}
        </div>
    </section>
</div>

{{- end -}}
```

---

## 📝 3. 페이지 생성 및 메뉴 연결

마지막으로 이 레이아웃을 사용하는 실제 페이지를 만들고 메뉴에 등록합니다.

**1. 페이지 파일 생성:** `content/explore.md`
```markdown
---
title: "Explore"
layout: "explore"
summary: "검색, 카테고리, 태그를 한눈에 확인하세요."
---
```

**2. 설정 파일 수정:** `hugo.toml`

기존 검색, 카테고리, 태그 페이지 주석처리함. 

```toml
[[menu.main]]
    identifier = "explore"
    name = "Explore"
    url = "/explore/"
    weight = 10
```

---

## ✨ 마치며
이제 여러 개의 메뉴를 거치지 않고 **'Explore'** 페이지 하나에서 블로그의 모든 콘텐츠를 탐색할 수 있습니다. 모듈화된 레이아웃 덕분에 나중에 검색 로직이나 분류 체계를 변경해도 통합 페이지에 자동으로 반영되어 관리가 매우 편리합니다!

```powershell
git add .
git commit -m "feat: complete integrated explore dashboard"
git push origin main
```