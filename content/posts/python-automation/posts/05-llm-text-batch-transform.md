---
title: Python — LLM 배치 텍스트 변환
description: ""
date: 2026-06-18T12:30:00.000Z
preview: ""
draft: false
tags:
    - Python
    - OpenAI
    - LLM
    - 배치
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

긴 텍스트를 청크로 나누고, LLM API에 지시문과 함께 보내 일괄 변환하는 패턴이다.
종결 어미 통일, 톤 변경, 요약 등 **문장 단위 편집**에 쓰인다.

API 키는 환경 변수로만 전달하며, 입·출력은 로컬 텍스트 파일로 다룬다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 처리 흐름

```
input/*.txt → 청크 분할 → (선택) 문장 마킹 → LLM 요청 → 후처리·검수
    ↓
output/*.txt + (선택) HTML diff 비교 페이지
```

토큰 한도 때문에 긴 원고는 한 번에 보내지 않고, 청크 단위로 순차 호출한다.

---

## API 키와 클라이언트

OpenAI API 키는 `OPENAI_API_KEY` 환경 변수에서 읽는다.

```python
import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
```

구버전 `openai.ChatCompletion.create` 대신 v1 SDK의 `client.chat.completions.create`를 쓰는 것이 권장된다.

---

## 청크 분할

빈 줄(`\n\n`) 기준으로 문단을 나누고, N개 문단씩 묶어 API 호출 단위를 만든다.

```python
def split_chunks(text: str, chunk_size: int = 3) -> list[str]:
    paragraphs = [p for p in text.split("\n\n") if p.strip()]
    chunks = []
    for i in range(0, len(paragraphs), chunk_size):
        chunks.append("\n\n".join(paragraphs[i : i + chunk_size]))
    return chunks
```

`chunk_size`를 키우면 호출 횟수는 줄지만 토큰 초과 위험이 커진다. 모델 컨텍스트 창에 맞게 조정한다.

---

## 문장 마킹 (선택)

변환 대상 문장 끝에 마커를 붙이면, LLM이 **어디를 바꿀지** 범위를 좁힐 수 있다.
마침표로 끝나는 문장을 `<합니다.>` 형태로 감싼다.

```python
import re

def mark_sentences(text: str) -> str:
    return re.sub(
        r"([^.?\n]+[.])",
        lambda m: f"<{m.group(1).strip()}>",
        text,
    )
```

응답 후 `<`, `>`를 제거하거나, 검수 단계에서 원문과 대조한다.

---

## LLM 호출

지시문(prompt)과 마킹된 본문을 합쳐 user 메시지로 보낸다.

```python
def transform_chunk(prompt: str, body: str, model: str = "gpt-4o") -> str:
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": body},
        ],
        temperature=0.5,
    )
    return response.choices[0].message.content
```

`temperature`를 낮추면 문체 변환처럼 형식이 정해진 작업에 유리하다.
지시문은 `prompt.txt` 등 별도 파일로 관리한다.

---

## Rate limit 재시도

`RateLimitError`·`ServiceUnavailableError` 시 sleep 후 재시도한다.

```python
import time

def transform_with_retry(prompt: str, body: str, retries: int = 3) -> str:
    for attempt in range(retries):
        try:
            return transform_chunk(prompt, body)
        except Exception as e:
            if "rate" in str(e).lower() and attempt < retries - 1:
                time.sleep(10 * (attempt + 1))
                continue
            raise
```

청크 하나가 실패해도 나머지 청크는 계속 처리할지, 전체를 중단할지는 운영 정책에 따른다.

---

## 후처리·검수

LLM 출력은 규칙 기반으로 한 번 더 정리한다.

```python
def postprocess(response: str) -> str:
    # 괄호 안에 마침표가 두 번 들어간 패턴 정리
    response = re.sub(r"<[^>]*\.[^>]*>", lambda m: m.group()[: m.group().index(".") + 2], response)
    return response.replace("<", "").replace(">", "")
```

원문 줄 수와 맞추는 `sync_space`, 화살표 표기(`A -> B`) 파싱 등은 도메인별로 추가한다.

---

## HTML diff 출력 (선택)

원문과 변환 결과를 나란히 비교하려면 `difflib.HtmlDiff`로 HTML을 생성한다.

```python
import difflib

def write_diff_html(original: str, transformed: str, path: str) -> None:
    differ = difflib.HtmlDiff(wrapcolumn=80)
    html = differ.make_file(
        original.splitlines(),
        transformed.splitlines(),
        fromdesc="원문",
        todesc="변환",
    )
    Path(path).write_text(html, encoding="utf-8")
```

수동 검수용으로 `output_page/`에 파일별 HTML을 저장한다.

---

## 전체 루프 (최소)

```python
from pathlib import Path

prompt = Path("prompt.txt").read_text(encoding="utf-8")
input_dir = Path("input")
output_dir = Path("output")
output_dir.mkdir(exist_ok=True)

for file_path in input_dir.glob("*.txt"):
    text = file_path.read_text(encoding="utf-8")
    chunks = split_chunks(text, chunk_size=3)
    results = []
    for chunk in chunks:
        marked = mark_sentences(chunk)
        out = transform_with_retry(prompt, marked)
        results.append(postprocess(out))
    output = "\n\n".join(results)
    (output_dir / file_path.name).write_text(output, encoding="utf-8")
    write_diff_html(text, output, f"output_page/{file_path.stem}.html")
```

`input/`에 원고 `.txt`를 넣고 실행한다. DEBUG 폴더에 청크·응답 중간 결과를 남기면 장애 추적이 쉽다.

---

## 주의사항

- **비용** — 청크 수 × 토큰 단가. 긴 원고는 `chunk_size`와 모델 선택으로 조절
- **PII** — 개인정보가 포함된 텍스트는 API 전송 전 마스킹
- **결정론** — 동일 입력도 temperature > 0이면 결과가 달라질 수 있음
- **API 버전** — SDK·엔드포인트 변경에 맞춰 클라이언트 코드 주기적 점검

---
