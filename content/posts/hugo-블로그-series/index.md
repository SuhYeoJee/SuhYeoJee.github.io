---
title: Hugo 블로그 Series
description: ""
date: 2025-12-29T09:44:30.991Z
preview: ""
tags: ["Hugo", "PaperMod", "Series", "Layout", "UI"]
categories: ["Manual"]
series: ["Hugo 블로그 세팅"]
---

매뉴얼이나 연재물을 작성할 때 관련 글들을 하나로 묶어주는 **시리즈(Series)** 기능은 필수입니다. 단순히 모아보기만 하는 것이 아니라, 글 하단에 목록을 띄우고 이전/다음 글로 바로 이동할 수 있는 **접이식 시리즈 네비게이션** 구현 방법을 정리합니다.

---

## 1. 분류 체계(Taxonomy) 설정

먼저 Hugo가 '시리즈'라는 개념을 인식할 수 있도록 설정을 추가해야 합니다.

**`hugo.toml`** (또는 config.toml) 파일을 열어 아래 내용을 수정하거나 추가하세요.

```toml
[taxonomies]
    category = "categories"
    tag = "tags"
    series = "series"  # 시리즈 기능 활성화
```

---

## 2. 시리즈 네비게이션 템플릿 생성

이제 글 하단에 나타날 레이아웃을 만듭니다. 이 코드는 **한글, 공백, 대소문자** 문제를 모두 해결하고, 기본적으로 **접혀 있는** 상태로 출력됩니다.

1. 프로젝트 루트의 `layouts/partials/` 폴더로 이동합니다. (폴더가 없으면 생성하세요.)
2. **`series_nav.html`** 파일을 만들고 아래 코드를 복사하여 넣습니다.

```html
{{- if .Params.series -}}
  {{- range .Params.series -}}
    {{- $name := . -}}
    {{- /* 대소문자, 한글, 공백 대응을 위한 이중 검색 로직 */ -}}
    {{- $series := index $.Site.Taxonomies.series ($name | lower) -}}
    {{- if not $series -}}{{- $series = index $.Site.Taxonomies.series (urlize $name) -}}{{- end -}}
    {{- if not $series -}}{{- $series = index $.Site.Taxonomies.series $name -}}{{- end -}}
    
    {{- if $series -}}
    <div class="series-nav" style="margin: 20px 0;">
      <details style="background: var(--code-bg); border: 1px solid var(--border); border-radius: 8px; padding: 15px;">
        <summary style="cursor: pointer; font-weight: bold; font-size: 1.1em; list-style: none;">
          <span style="margin-right: 10px;">📂</span> "{{ $name }}" 시리즈 목록
        </summary>
        
        <div style="margin-top: 15px;">
          <ul style="padding-left: 20px;">
            {{- range $series.Pages.ByDate -}}
            <li style="margin: 8px 0;">
              <a href="{{ .RelPermalink }}" {{ if eq . $ }}style="font-weight:bold; color:var(--primary); text-decoration: underline;"{{ end }}>
                {{ .Title }}
              </a>
            </li>
            {{- end -}}
          </ul>

          <div style="display: flex; justify-content: space-between; margin-top: 20px; border-top: 1px solid var(--border); padding-top: 15px; font-size: 0.95em;">
            {{- $current := $ -}}
            {{- $prev := "" -}}
            {{- $next := "" -}}
            {{- $pages := $series.Pages.ByDate -}}
            {{- range $index, $page := $pages -}}
              {{- if eq $page $current -}}
                {{- if gt $index 0 -}}{{- $prev = index $pages (sub $index 1) -}}{{- end -}}
                {{- if lt $index (sub (len $pages) 1) -}}{{- $next = index $pages (add $index 1) -}}{{- end -}}
              {{- end -}}
            {{- end -}}

            <div>{{ if $prev }}<a href="{{ $prev.RelPermalink }}" style="color: var(--primary);">👈 이전 편</a>{{ end }}</div>
            <div>{{ if $next }}<a href="{{ $next.RelPermalink }}" style="color: var(--primary);">다음 편 👉</a>{{ end }}</div>
          </div>
        </div>
      </details>
    </div>
    {{- end -}}
  {{- end -}}
{{- end -}}
```

---

## 3. 본문 레이아웃에 적용하기

만든 템플릿을 실제 포스트 페이지에 나타나게 연결합니다.

1. `themes/PaperMod/layouts/_default/single.html` 파일을 복사하여,
2. 프로젝트 루트의 `layouts/_default/single.html` 위치에 붙여넣습니다.
3. 파일 내에서 본문 내용이 끝나는 지점(보통 `{{- if .Content }}` 블록 끝부분)에 아래 코드를 삽입합니다.

```html
{{ partial "series_nav.html" . }}
```

---

## 4. 포스트에서 시리즈 지정하기

이제 개별 포스트 상단(`Front Matter`)에 어떤 시리즈에 속하는지 적어주기만 하면 됩니다.

```yaml
---
title: "나의 첫 번째 매뉴얼"
series: ["Hugo 블로그 세팅"]
---
```

## 5. Front Matter CMS에 series 필드 추가하기

`frontmatter.json` 설정 파일에서 `series` 필드의 타입을 도구가 허용하는 값 중 하나인 **`taxonomy`** 또는 **`tags`**로 지정해야 합니다.

**설정 예시:**
```json
{
    "title": "series",
    "name": "series",
    "type": "taxonomy",
    "taxonomyId": "series"
}
```

## ✨ 완성된 기능의 특징
- **자동 목록화**: 동일한 시리즈 이름을 가진 글들이 날짜순으로 자동 나열됩니다.
- **스마트 네비게이션**: 시리즈 내의 이전 글과 다음 글 링크를 자동으로 생성합니다.
- **깔끔한 UI**: 기본적으로 리스트가 접혀 있어 본문 가독성을 해치지 않으며, 현재 읽고 있는 글은 굵게 강조됩니다.
- **강력한 매칭**: 한글, 띄어쓰기, 대소문자가 섞인 시리즈 이름도 오류 없이 인식합니다.

이제 체계적으로 매뉴얼을 쌓아가는 즐거움을 느껴보세요! 🚀