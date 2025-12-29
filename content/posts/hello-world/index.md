---
title: hello-world
date: 2025-12-29T08:12:02.932Z
tags:
    - Hugo
    - GitHub Pages
    - Blog
categories:
    - Tech
description: Hugo 블로그 생성
---

Jekyll에서 Hugo로 갈아탔다.  
사유는 여러모로 관리하기 편해보여서.  

> 환경: win11


#### hugo 설치

터미널을 관리자 권한으로 실행 후 진행  

```
choco install hugo-extended
```

설치 확인 -> `hugo version`  

> v0.153.3


#### 블로그 프로젝트 생성

현재 터미널 위치에 하위 폴더로 생성

```
hugo new site blog_name
cd blog_name
```

#### 깃 초기화, 테마 다운로드

```
git init
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod

echo 'theme = "PaperMod"' >> hugo.toml
```

echo 사용시 전각문자를 사용하여 오류가 발생하는 경우  
`hugo.toml` 파일에 `theme = "PaperMod"`를 수동으로 추가함.  

`hugo server -D`로 로컬 서버 실행 후  
`http://localhost:1313/` 접속해서 테마 적용 확인  


> 선택사항: `themes/PaperMod`에서 해당 테마의 `.git`폴더 삭제.  
> 테마 수정시 버전관리 어려움  


프로젝트 루트 위치에 아래 내용으로 `.gitignore`추가

```
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


#### VScode 확장기능 설치

`Front Matter CMS` 설치.  
프로젝트 초기화, 폴더 추가(/content/posts), 대시보드 구성


프로젝트 루트에 생성되는 `frontmatter.json` 수정  

> `frontMatter.taxonomy.contentTypes` -> `"pageBundle": true`  

posts에 새 포스트를 추가할 때 폴더+index.md형식으로 생성하도록함.   

같은 파일에 아래 내용 추가   

```
  "frontMatter.content.pageFolders": [
    {
      "path": "[[workspace]]/content/posts",
      "filePrefix": "",
      "title": "Posts",
      "previewPath": "posts"
    }
  ]
```

파일 생성시 이름 규칙에 prefix삭제,   
페이지 미리보기 path에 posts추가.  


#### git pages로 배포

github 새 공개 레포 생성 `깃허브아이디.github.io`   
레포 생성 후 주소 복사.   

프로젝트 폴더 내에서 깃허브와 연결   

```
git config --global --add safe.directory 프로젝트_루트디렉토리
git remote add origin 복사한_레포_주소
```

현재상태 푸시

```
git add .
git commit -m "First blog setup"
git branch -M main
git push -u origin main
```

#### github actions로 자동 배포 설정

github의 레포 settings에서 

Actions > General > Workflow permissions을  
`Read and write permissions` 으로 변경하고 save.  

Pages > Build and deployment의 Source를 `GitHubActions`으로 설정.  


프로젝트 루트 경로의 `hugo.toml`파일의  
`baseURL`을 `https://깃허브아이디.github.io/`로 변경  


프로젝트 루트에서 .github/workflows 폴더 생성.   
하위에 `hugo.yaml`를 아래 내용으로 생성  

```
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

설정 수정사항 푸시

```
git add .
git commit -m "First Build and Deploy"
git push -u origin main
```