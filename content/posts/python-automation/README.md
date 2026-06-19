# Python 자동화 아카이브

Python 배치·모니터링 스크립트의 **설계 패턴과 인프라 연동**을, **학습·공유 목적으로 독립 재구성**한 시리즈입니다.

별도 예제 프로젝트 없이, 각 글 본문에 **최소 구현 코드 스니펫**을 포함합니다.

> 비공개 프로젝트 소스는 포함하지 않으며, 이 시리즈 예제·스니펫은 별도로 새로 작성합니다.

> **면책** — 학습·설계 패턴 공유 목적입니다. 예제는 데모 URL·합성 데이터만 사용합니다. **본인이 접근·관리 권한이 있는 시스템·데이터**에만 적용하고, 제3자 서비스의 이용약관·robots·법령을 준수하세요.

## 시리즈 목록

| # | 제목 | 상태 |
|---|------|------|
| 0 | [Python — 환경 설정](./posts/00-setup-and-run.md) | 공개 |
| 1 | [Python — 배치·모니터링 패턴 개요](./posts/01-series-intro.md) | 공개 |
| 2 | [Python — AWS Lightsail CPU 모니터링](./posts/02-aws-cpu-monitor.md) | 공개 |
| 3 | [Python — HTTPS 인증서 배치 자동화](./posts/03-https-cert-automation.md) | 공개 |
| 4 | [Python — Google Play 앱 메트릭 수집](./posts/04-google-play-app-scraping.md) | 초안 |
| 5 | [Python — LLM 배치 텍스트 변환](./posts/05-llm-text-batch-transform.md) | 공개 |
| 6 | [Python — POP3 메일 읽기와 MIME 파싱](./posts/06-email-pop3-db-pipeline.md) | 공개 |
| 7 | [Python — Selenium 검색 순위 모니터링](./posts/07-selenium-serp-rank-monitoring.md) | 초안 |
| 8 | [Python — HTTP 기반 검색 순위 조회](./posts/08-http-serp-rank-monitoring.md) | 초안 |
| 9 | [Python — TSV 입력 채널과 DB 증분 적재](./posts/09-tsv-incremental-db-ingest.md) | 공개 |
| 10 | [Python — Selenium 멀티프로세싱 패턴](./posts/10-selenium-multiprocessing.md) | 공개 |
| 11 | [Python — subprocess 격리와 timeout](./posts/11-subprocess-isolation-timeout.md) | 공개 |
| 12 | [Python — HTTP DB 프록시와 요청 서명](./posts/12-http-db-proxy-signing.md) | 공개 |
| 13 | [Python — PyAutoGUI 데스크톱 입력 자동화](./posts/13-pyautogui-desktop-input.md) | 공개 |

## 작성 원칙

- 비공개 코드·URL·도메인·내부 버전명 미사용
- 기술 개념·설계 선택 중심
- 코드는 본문 인라인 스니펫 (복사 후 단일 `.py`로 실행)
- 비밀 값은 환경 변수, 실명·토큰 미사용
- 포스트 제목은 `Python — …` 접두로 통일

## 상태

- **공개** — 0~3, 5~6, 9~13편 (`draft: false`)
- **초안** — 4, 7, 8편 (`draft: true`, 배포 제외)
