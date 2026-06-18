---
title: Hugo 블로그 설치
date: 2025-12-29T08:12:02.932Z
tags:
    - Hugo
    - GitHub Pages
    - Blog
categories:
    - Manual
description: Hugo 블로그 생성
series: ["Hugo 블로그 세팅"]
---

Jekyll에서 Hugo로 갈아탔다. 사유는 여러모로 관리하기 편해 보여서.

> 💻 **환경**: Windows 11

---

## 📑 목차
1. [Hugo 설치](#1-hugo-설치)
2. [블로그 프로젝트 생성](#2-블로그-프로젝트-생성)
3. [깃 초기화 및 테마 다운로드](#3-깃-초기화-및-테마-다운로드)
4. [VSCode 확장기능 설치](#4-vscode-확장기능-설치)
5. [GitHub Pages로 배포](#5-github-pages로-배포)
6. [GitHub Actions 자동 배포 설정](#6-github-actions-자동-배포-설정)

---

## 1. Hugo 설치
터미널을 **관리자 권한**으로 실행 후 진행합니다.

```bash
choco install hugo-extended
```

* **설치 확인**: `hugo version`
* **현재 버전**: `v0.153.3`

## 2. 블로그 프로젝트 생성
현재 터미널 위치에 하위 폴더로 생성합니다.

```bash
hugo new site blog_name
cd blog_name
```

## 3. 깃 초기화 및 테마 다운로드
```bash
git init
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod

echo 'theme = "PaperMod"' >> hugo.toml
```

* **주의**: `echo` 사용 시 전각문자로 인해 오류가 발생하면 `hugo.toml` 파일에 `theme = "PaperMod"`를 **수동으로 추가**합니다.
* **로컬 확인**: `hugo server -D` 실행 후 `http://localhost:1313/` 접속해서 테마 적용 확인
* **선택사항**: 테마 수정 편의를 위해 `themes/PaperMod` 내의 `.git` 폴더 삭제 가능

### 📄 .gitignore 설정
프로젝트 루트 위치에 아래 내용으로 추가합니다.

```text
# Hugo가 빌드할 때 만드는 임시 폴더
public/
resources/_gen/
.hugo_build.cfg

# 운영체제 생성 파일
Thumbs.db
.DS_Store

# 에디터 관련 설정
.vscode/
```

## 4. VSCode 확장기능 설치
`Front Matter CMS`를 설치합니다. 프로젝트 초기화, 폴더 추가(/content/posts), 대시보드를 구성합니다.

* **frontmatter.json 수정**: 
    * `"pageBundle": true` 설정 (새 포스트 추가 시 폴더+index.md 형식으로 생성)
* **경로 설정 추가**:

```json
  "frontMatter.content.pageFolders": [
    {
      "path": "[[workspace]]/content/posts",
      "filePrefix": "",
      "title": "Posts",
      "previewPath": "posts"
    }
  ]
```

## 5. GitHub Pages로 배포
GitHub 새 공개 레포지토리 `깃허브아이디.github.io`를 생성하고 주소를 복사합니다.

```bash
git config --global --add safe.directory 프로젝트_루트디렉토리
git remote add origin 복사한_레포_주소

git add .
git commit -m "First blog setup"
git branch -M main
git push -u origin main
```

## 6. GitHub Actions 자동 배포 설정
1.  **GitHub Repo Settings**:
    * `Actions > General`: Workflow permissions을 **Read and write permissions**로 변경 후 Save
    * `Pages > Build and deployment`: Source를 **GitHub Actions**로 설정
2.  **hugo.toml**: `baseURL`을 `https://깃허브아이디.github.io/`로 변경

### 📄 .github/workflows/hugo.yaml 생성
프로젝트 루트에서 폴더 생성 후 아래 내용으로 파일을 만듭니다.

```yaml
name: deploy-hugo-site
on:
  push:
    branches:
      - main
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true
      - name: Build
        run: hugo --minify
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### ✨ 최종 푸시
```bash
git add .
git commit -m "First Build and Deploy"
git push -u origin main
```