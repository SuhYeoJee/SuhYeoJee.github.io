# Python 자동화 아카이브

Python 배치·모니터링 스크립트의 **설계 패턴과 인프라 연동**을, **학습·공유 목적으로 독립 재구성**한 시리즈입니다.

별도 예제 프로젝트 없이, 각 글 본문에 **최소 구현 코드 스니펫**을 포함합니다.

> 비공개 프로젝트 소스는 포함하지 않으며, 이 시리즈 예제·스니펫은 별도로 새로 작성합니다.

## 시리즈 목록

| # | 제목 | 상태 |
|---|------|------|
| 0 | [Python 환경 설정](./posts/00-setup-and-run.md) | 초안 |
| 1 | [배치·모니터링 패턴 개요](./posts/01-series-intro.md) | 초안 |
| 2 | [AWS Lightsail CPU 모니터링](./posts/02-aws-cpu-monitor.md) | 초안 |
| 3 | [HTTPS 인증서 배치 자동화](./posts/03-https-cert-automation.md) | 초안 |
| 4 | [Google Play 앱 메트릭 수집](./posts/04-google-play-app-scraping.md) | 초안 |
| 5 | [LLM 배치 텍스트 변환](./posts/05-llm-text-batch-transform.md) | 초안 |
| 6 | [POP3 메일 수집과 DB 저장](./posts/06-email-pop3-db-pipeline.md) | 초안 |

## 작성 원칙

- 비공개 코드·URL·도메인·내부 버전명 미사용
- 기술 개념·설계 선택 중심
- 코드는 본문 인라인 스니펫 (복사 후 단일 `.py`로 실행)
- 비밀 값은 환경 변수, 실명·토큰 미사용

## 상태

- 시리즈 글 모두 `draft: true` (로컬 `hugo server -D` 미리보기, 배포 제외)
