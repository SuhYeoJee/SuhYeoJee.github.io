---
title: HTTPS 인증서 배치 자동화
description: ""
date: 2026-06-18T11:30:00.000Z
preview: ""
draft: true
tags:
    - Python
    - HTTPS
    - Certbot
    - DevOps
    - SSH
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

여러 서버·도메인에 Let's Encrypt 인증서를 발급·갱신할 때, SSH로 원격 명령을 실행하는 오케스트레이션 패턴이다.
CPU 모니터링(2편)과 같은 **목록 + 루프** 골격이지만, SSH로 서버 설정을 변경하므로 실패 시 HTTPS 중단으로 이어질 수 있다.
예제 도메인·IP는 `example.com` 등 데모용이며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
hosts.txt → SSH 접속 → certbot → 웹서버 reload → 로그
```

2편이 AWS API를 **읽기**만 하는 것과 달리, 이 패턴은 원격 서버에서 **쓰기** 작업을 수행한다.

---

# certbot 인증 방식

자동화 스크립트를 짜기 전에, 대상 서버가 어떤 방식으로 도메인 소유를 증명하는지 정해야 한다.

| 방식 | 설명 |
|------|------|
| standalone | certbot이 80 포트를 점유해 ACME HTTP-01 챌린지 처리. Nginx가 80을 쓰면 충돌 가능 |
| webroot | 웹서버 DocumentRoot 아래 `.well-known/acme-challenge/`에 토큰 배치. 무중단 갱신에 적합 |
| DNS-01 | DNS TXT 레코드로 증명. 와일드카드 인증서 가능, DNS API 연동 필요 |

운영 중인 서비스가 있다면 webroot가 가장 흔한 선택이다.

---

# SSH 원격 실행

`paramiko`로 SSH 세션을 열고, 원격 셸에서 명령을 실행한다.
키 파일 경로와 사용자명은 환경 변수에서 읽어 코드에 비밀 정보가 남지 않게 한다.

```python
import os
import paramiko

def run_remote(host: str, command: str) -> tuple[int, str, str]:
    key_path = os.getenv("SSH_KEY_PATH")
    user = os.getenv("SSH_USER", "ubuntu")

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, username=user, key_filename=key_path)

    _, stdout, stderr = client.exec_command(command, timeout=120)
    code = stdout.channel.recv_exit_status()
    client.close()
    return code, stdout.read().decode(), stderr.read().decode()
```

반환값은 `(exit_code, stdout, stderr)` 튜플이다. `exit_code`가 0이면 성공.
`timeout=120`은 certbot이 수십 초 걸릴 수 있어 넉넉히 잡은 값이다.
`AutoAddPolicy`는 최초 접속 시 호스트 키를 자동 등록한다. 운영 환경에서는 known_hosts를 명시적으로 관리하는 편이 안전하다.

---

# certbot 갱신

이미 발급된 인증서가 있을 때는 `certbot renew`로 갱신한다.
갱신 성공 후 Nginx를 reload해야 새 인증서가 적용된다. `&&`로 두 명령을 한 줄에 연결했다.

```python
def renew_cert(host: str, domain: str) -> bool:
    cmd = (
        f"certbot renew --cert-name {domain} --quiet "
        f"&& nginx -s reload"
    )
    code, out, err = run_remote(host, cmd)
    if code != 0:
        print(f"[fail] {domain}@{host}: {err or out}")
        return False
    print(f"[ok] {domain}@{host}")
    return True
```

`--cert-name`은 certbot이 인증서를 구분하는 이름이며, 보통 도메인과 같다.
`--quiet`는 성공 시 출력을 줄인다. 실패 시 stderr를 로그에 남긴다.

최초 발급은 `certonly`를 쓰며, webroot 방식 예시는 아래와 같다.
`-w`는 ACME 챌린지 파일을 둘 웹 루트 경로이고, `-m`은 Let's Encrypt 등록용 이메일이다.

```python
cmd = (
    f"certbot certonly --webroot -w /var/www/html "
    f"-d {domain} --non-interactive --agree-tos "
    f"-m admin@example.com"
)
```

발급(`certonly`)과 갱신(`renew`)은 목적이 다르므로, 스크립트를 분리하는 것이 운영이 단순하다.

---

# 대상 순회

`hosts.txt`에 `호스트IP\t도메인` 형식으로 대상을 적고, 2편 `load_servers`와 같은 방식으로 읽는다.
`run_once`가 각 호스트에 대해 `renew_cert`를 호출한다.

```python
from pathlib import Path

def load_hosts(path: str) -> list[tuple[str, str]]:
    """hosts.txt: 호스트IP\\t도메인"""
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    return [
        tuple(p.strip() for p in line.split("\t"))
        for line in lines
        if line.strip() and not line.startswith("#")
    ]

def run_once() -> None:
    for host, domain in load_hosts("hosts.txt"):
        renew_cert(host, domain)
```

입력 파일 예시. IP는 SSH 접속 주소, 도메인은 certbot에 넘기는 값이다.

```
203.0.113.10	www.example.com
203.0.113.11	api.example.com
```

2편처럼 `while True` + `time.sleep`으로 감싸거나, cron으로 하루 두 번 `run_once()`만 호출하는 방식이 일반적이다.

---

# 드라이런 검증

운영 스크립트를 돌리기 전에, 서버에서 certbot 설정이 올바른지 `--dry-run`으로 확인한다.
실제 인증서를 발급·갱신하지 않고 ACME 챌린지까지만 시뮬레이션한다.

```python
code, _, err = run_remote(host, "certbot renew --dry-run")
if code != 0:
    raise RuntimeError(err)
```

한 도메인이라도 dry-run이 실패하면 자동화를 켜지 않는다. 수동으로 certbot 오류를 먼저 해결해야 한다.

---

# Let's Encrypt 제약

- 동일 도메인에 짧은 시간 반복 발급 시 rate limit에 걸린다
- 인증서 유효 기간은 90일이며, `certbot renew`는 만료 30일 이내인 경우에만 실제 갱신한다
- 발급과 갱신 스크립트를 분리하고, 갱신은 cron으로 하루 1~2회가 권장 주기다

---

# CPU 모니터링과 비교

| | CPU (2편) | HTTPS (3편) |
|--|-----------|-------------|
| 연동 | AWS CLI | SSH + certbot |
| 성격 | 읽기 | 쓰기 |
| 실패 영향 | 알림 누락 | HTTPS 중단 가능 |
| 로컬 테스트 | 가짜 CPU 함수로 대체 | 서버에서 `certbot --dry-run` 필수 |
