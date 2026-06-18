---
title: HTTP 기반 검색 순위 조회
description: ""
date: 2026-06-20T10:30:00.000Z
preview: ""
draft: true
tags:
    - Python
    - requests
    - BeautifulSoup
    - 크롤링
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

검색 결과 순위를 **requests + BeautifulSoup**으로 파싱하는 패턴이다.
7편 Selenium과 목적은 같지만, 브라우저 없이 정적 HTML·내부 검색 API 응답만으로 처리한다.

I/O 대기가 많아 **multiprocessing**으로 키워드를 병렬 조회하는 구성이 흔하다.
데모 URL·키워드만 사용하며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 처리 흐름

```
targets.txt (키워드\tURL)
    ↓
프로세스 풀: 키워드별 HTTP GET → HTML/JSON 파싱
    ↓
결과 리스트에서 URL 매칭 → 순위
    ↓
output.txt / DB 저장
```

페이지가 JavaScript로만 채워지면 이 방식은 실패한다. 그때는 7편 Selenium을 검토한다.

---

## HTTP 요청

User-Agent·Referer를 넣지 않으면 403이 나는 경우가 많다.

```python
import requests

def fetch_search_html(keyword: str, page: int = 1) -> str:
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ),
        "Referer": "https://search.example.com/",
    }
    url = (
        f"https://api.example.com/search"
        f"?q={keyword}&start={(page - 1) * 15 + 1}"
    )
    resp = requests.get(url, headers=headers, timeout=15)
    resp.raise_for_status()
    return resp.text
```

실제 엔드포인트는 사이트마다 다르다. 개발자 도구 Network 탭으로 XHR URL을 확인하는 경우가 많다.

---

## HTML 파싱

```python
from bs4 import BeautifulSoup

ITEM_SELECTOR = 'li[class="result-item"]'
LINK_SELECTOR = 'a.item-link'

def parse_result_links(html: str) -> list[str]:
    soup = BeautifulSoup(html, "html.parser")
    links = []
    for item in soup.select(ITEM_SELECTOR):
        a = item.select_one(LINK_SELECTOR)
        if a and a.get("href"):
            links.append(a["href"])
    return links
```

`select`는 CSS 셀렉터, `select_one`은 첫 매칭만 반환한다.

---

## URL 매칭

동일 페이지라도 URL 형식이 여러 가지일 수 있다. 쿼리 파라미터나 path 일부만 비교한다.

```python
import re

def normalize_post_url(url: str) -> str:
    """데모: path 마지막 세그먼트 또는 id 파라미터로 비교"""
    m = re.search(r"id=(\d+)", url)
    if m:
        return m.group(1)
    return url.rstrip("/").split("/")[-1]

def url_matches(target: str, href: str) -> bool:
    return normalize_post_url(target) == normalize_post_url(href)
```

7편과 같이 `target in href` 단순 포함 비교도 쓰이지만, 정규화가 오탐을 줄인다.

---

## 깊은 순위 (페이지네이션)

한 페이지에 15건만 있으면, 목표 URL이 안 나올 때까지 `start` 파라미터를 올리며 요청한다.

```python
def find_rank_http(keyword: str, target_url: str, max_pages: int = 7) -> int:
    all_links: list[str] = []
    for page in range(1, max_pages + 1):
        html = fetch_search_html(keyword, page=page)
        batch = parse_result_links(html)
        if not batch:
            break
        all_links.extend(batch)
        for rank, href in enumerate(all_links, start=1):
            if url_matches(target_url, href):
                return rank
    return 0
```

`max_pages * 15`가 상한 순위가 된다. 500위까지 보려면 상한·재시도 정책을 config에 둔다.

---

## 키워드 보정 감지 (선택)

검색 엔진이 「○○으로 검색한 결과」처럼 키워드를 바꿔 보여주면, 보정된 키워드로 다시 요청해야 한다.

```python
import re

def detect_corrected_keyword(html: str) -> str | None:
    soup = BeautifulSoup(html, "html.parser")
    banner = soup.select_one("div.query-corrected")
    if not banner:
        return None
    text = banner.get_text()
    m = re.search(r"(.+?)으로 검색한 결과", text)
    return m.group(1).strip() if m else None
```

첫 응답에서 보정 키워드를 읽고, 있으면 그 키워드로 `fetch_search_html`을 재호출한다.

---

## multiprocessing 병렬

키워드마다 독립 HTTP 호출이므로 프로세스 풀에 적합하다.

```python
from multiprocessing import Pool

def check_one(args: tuple[int, str, str]) -> dict:
    idx, keyword, url = args
    try:
        rank = find_rank_http(keyword, url)
        return {"idx": idx, "keyword": keyword, "url": url, "rank": rank}
    except Exception as e:
        return {"idx": idx, "keyword": keyword, "url": url, "rank": f"err:{e}"}

def run_parallel(targets: list[tuple[str, str]], workers: int = 8) -> list[dict]:
    jobs = [(i, kw, u) for i, (kw, u) in enumerate(targets)]
    with Pool(workers) as pool:
        return list(pool.imap_unordered(check_one, jobs))
```

`workers`는 대상 사이트 rate limit에 맞게 낮춘다. `imap_unordered`는 완료 순으로 결과를 받는다.

---

## 결과 기록

```python
from pathlib import Path

def write_outputs(results: list[dict], path: str) -> None:
    lines = []
    for r in sorted(results, key=lambda x: x["idx"]):
        lines.append(f"{r['keyword']}\t{r['url']}\t{r['rank']}")
    Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
```

오류 행은 `pc_error.txt`처럼 별도 파일로 분리하면 재실행 대상만 골라낼 수 있다.

---

## 7편과 비교

| 항목 | Selenium (7편) | HTTP (현재) |
|------|----------------|-------------|
| 속도 | 느림 | 빠름 |
| 병렬 | 드라이버 비용 큼 | Pool에 적합 |
| JS 렌더 | 가능 | 불가 |
| HTML 변경 | 셀렉터 유지보수 | URL·응답 형식 유지보수 |

---

## 주의사항

- **Rate limit** — 병렬도·sleep으로 조절
- **API 비공개** — 내부 XHR URL은 문서화되지 않아 깨지기 쉬움
- **법·약관** — 크롤링 허용 범위 준수
- **Windows** — `multiprocessing` 진입점은 `if __name__ == "__main__":` 필수

---
