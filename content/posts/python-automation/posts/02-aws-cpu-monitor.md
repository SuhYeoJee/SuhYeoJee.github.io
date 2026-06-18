---
title: AWS Lightsail CPU 모니터링
description: ""
date: 2026-06-18T11:00:00.000Z
preview: ""
draft: true
tags:
    - Python
    - AWS
    - Lightsail
    - 모니터링
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

클라우드 인스턴스의 CPU 사용률을 주기적으로 조회하고, 임계값을 넘으면 알림을 보내는 패턴이다.
AWS Lightsail은 `get-instance-metric-data` API로 `CPUUtilization` 메트릭을 제공한다.

1편에서 다룬 **설정 → 순회 → 외부 호출 → 알림 → 반복** 골격에 AWS CLI 호출이 들어간 형태다.
예제의 서버 이름·IP는 데모용이며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
servers.txt → AWS CLI 메트릭 조회 → threshold 비교 → 알림·로그 → sleep → 반복
```

메트릭 조회는 읽기 전용이라 인스턴스 설정을 바꾸지 않는다. 모니터링 스크립트에 적합한 위험 수준이다.

---

# Lightsail 메트릭 API

`aws lightsail get-instance-metric-data` 명령의 응답은 JSON이며, `metricData` 배열에 시계열 포인트가 담긴다.
각 포인트는 `timestamp`와 집계값(`maximum`, `average` 등)을 가진다.

```json
{
  "metricData": [
    { "timestamp": "2026-06-18T08:00:00+00:00", "maximum": 72.5 }
  ]
}
```

주요 파라미터 의미:

- `period` 300 — 5분 단위로 집계된 데이터 포인트
- `statistics Maximum` — 구간 내 최대값. 짧은 CPU 스파이크를 놓치지 않으려면 Average보다 유리
- `lookback_seconds` — 조회 시작 시점. `period`(300)보다 짧으면 빈 배열이 반환될 수 있음

---

# CPU 조회

`subprocess.run`으로 AWS CLI를 호출하고, stdout JSON에서 가장 최근 포인트의 `maximum`을 꺼낸다.
`check=True`는 CLI가 0이 아닌 exit code를 반환하면 `CalledProcessError`를 발생시킨다.

```python
import json
import subprocess
import time

def get_cpu_percent(instance_name: str, lookback: int = 600) -> float:
    end = int(time.time())
    start = end - lookback
    cmd = [
        "aws", "lightsail", "get-instance-metric-data",
        "--metric-name", "CPUUtilization",
        "--statistics", "Maximum",
        "--unit", "Percent",
        "--period", "300",
        "--instance-name", instance_name,
        "--start-time", str(start),
        "--end-time", str(end),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(proc.stdout)["metricData"]
    latest = max(data, key=lambda x: x["timestamp"])
    return float(latest["maximum"])
```

`--instance-name`에는 Lightsail 콘솔에 표시되는 인스턴스 이름을 넣는다. IP가 아니다.
`max(..., key=timestamp)`로 여러 포인트 중 가장 최근 값을 선택한다.

---

# 알림

콘솔 출력은 항상 수행하고, 텔레그램은 환경 변수가 있을 때만 전송한다.
Bot API는 `sendMessage` 엔드포인트에 `chat_id`와 `text`를 JSON으로 POST하면 된다.

```python
import os

def notify(message: str) -> None:
    print(message)
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    chat_id = os.getenv("TELEGRAM_CHAT_ID")
    if not token or not chat_id:
        return
    import requests
    requests.post(
        f"https://api.telegram.org/bot{token}/sendMessage",
        json={"chat_id": chat_id, "text": message},
        timeout=10,
    )
```

`requests`는 함수 안에서 import했다. 텔레그램을 쓰지 않는 환경에서는 패키지 설치 없이도 스크립트가 동작한다.
Slack webhook 등 다른 채널로 바꿀 때도 `notify` 함수 내부만 수정하면 된다.

---

# 한 사이클

`run_once`는 서버 목록을 순회하며 CPU를 조회하고, `THRESHOLD` 이상이면 `notify`를 호출한다.
개별 서버에서 예외가 나도 나머지 서버 처리는 계속하도록 `try/except`로 감쌌다.

```python
THRESHOLD = 80.0

def run_once(servers: list[tuple[str, str]]) -> None:
    for name, ip in servers:
        try:
            cpu = get_cpu_percent(name)
            print(f"{name} ({ip}): {cpu}%")
            if cpu >= THRESHOLD:
                notify(f"CPU 알림\n{name} [{ip}]\n{cpu}%")
        except Exception as e:
            print(f"[error] {name}: {e}")
```

`ip`는 AWS API 호출에 쓰이지 않고, 알림 메시지에 어떤 서버인지 표시하기 위한 용도다.
운영 환경에서는 `THRESHOLD`를 1편의 `config.ini`에서 읽도록 바꾸면 된다.

---

# 전체 스크립트 (최소)

앞의 함수들을 합치면 아래와 같은 진입점이 된다.
`load_servers`는 1편 `load_targets`와 동일한 패턴이며, `Path.read_text`로 파일을 한 번에 읽는다.

```python
import time
from pathlib import Path

def load_servers(path: str) -> list[tuple[str, str]]:
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    return [
        tuple(p.strip() for p in line.split("\t"))
        for line in lines
        if line.strip() and not line.startswith("#")
    ]

if __name__ == "__main__":
    servers = load_servers("servers.txt")
    while True:
        run_once(servers)
        time.sleep(300)  # 5분
```

`servers.txt`는 스크립트와 같은 디렉터리에 둔다. 탭으로 이름과 IP를 구분한다.

```
demo-1	10.0.0.1
demo-2	10.0.0.2
```

`time.sleep(300)`의 300초(5분)는 `config.ini`의 `delay_minutes`와 맞추면 된다.

---

# dry-run (로컬 테스트)

AWS 계정 없이 임계값 분기·알림 포맷만 검증하려면, `get_cpu_percent`를 가짜 구현으로 교체한다.
인스턴스 이름의 해시를 시드로 쓰면 같은 이름에 대해 실행마다 비슷한 값이 나와 재현성이 있다.

```python
import random

def get_cpu_percent(instance_name: str, lookback: int = 600) -> float:
    random.seed(hash(instance_name))
    return round(random.uniform(40, 95), 1)
```

실제 배포 전에 이 함수로 `run_once`를 돌려보고, 80% 넘는 경우 알림이 오는지 확인한 뒤 원래 AWS CLI 버전으로 되돌린다.

---

# 상시 실행

| 환경 | 방법 |
|------|------|
| Linux | cron 또는 systemd timer |
| Windows | 작업 스케줄러 |
| 스크립트 내부 | `while True` + `time.sleep` |

스크립트 내부 루프는 구현이 단순하고, OS 스케줄러는 프로세스가 매번 재시작되어 장기 실행 시 안정적이다.
AWS IAM에는 `lightsail:GetInstanceMetricData` 권한이 필요하다.

---

# 관련 개념

- EC2는 CloudWatch, Lightsail은 자체 메트릭 API — 인스턴스 종류에 맞는 엔드포인트를 써야 한다
- CPU 알림에는 Average보다 Maximum이 스파이크 감지에 유리하다
- boto3 `client("lightsail").get_instance_metric_data()`로 동일 작업을 SDK로도 수행할 수 있다
