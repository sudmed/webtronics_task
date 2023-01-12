**Разобрать и объяснить структуру CI/CD pipeline (на примере gitlab.yml).**

Файл .gitlab-ci.yml, лежащий в корне проекта, отвечает за алгоритм и настройку пайплайна ("конвеера") CI/CD в Gitlab. В каждой ветке проекта может быть свой файл .gitlab-ci.yml, при этом по-умолчанию при каждом пуше в ветку с лежащим в ней файле .gitlab-ci.yml будет происходить запуск соответствующего пайплайна CI/CD. Пайплайн также можно запустить и вручную.  

Свой файл .gitlab-ci.yml может быть в каждой отдельной директории проекта (например, отдельные файлы в папках  `frontend/` и `backend/`), тогда файл .gitlab-ci.yml в корневой папке проекта будет выполнять роль модульного пайплайна, описывающего запуск конвеера из отдельных пайплайнов во вложенных папках (например, по событию изменения файлов в соответствующих папках).  

Пайплайн состоит из этапов (stages), они идут в четкой последовательности и каждый последующий этап выполняется только при условии успешного выполнения предыдущего. Этапы в свою очередь состоят из заданий (job). Задание содержит обычно одно конкретное действие (запуск команды или скрипта), выполняющеее какую-то логически атомарную задачу. Задания выполняются на раннерах (runner) - машинах гитлаба (shared runners) или подключенных собственных (group runners, specific runners). Внутри одного этапа может быть несколько джобов и все они, в отличии от этапов, будут выполняться не по порядку, а либо одновремено при наличии нужного количества свободных раннеров, либо в порядке освобождения раннеров без определенной очередности. На раннерах инструкции джобы могут выполняться как локально, так и в докер-контейнерах.  

Пайплайн обычно содержит три этапа: сборка, тестирование, развертывание. Этапы можно менять, добавлять, удалять. Результат выполнения одного этапа передается в следующий этап в виде артефакта, а также может быть скачан в виде zip-архива для отладки.  

Сборка исходного кода происходит в зависимости от языка программирования и особенности продукта путем компилляции в бинарный файл, упаковки в iso, архив или другой артефакт. Например, для языка Go артефактом сборки будет бинарный файл, полученный в результате выполнения команды `go build`.  

Этап тестирования может включать джобы c запуском различных тестов: от линтеров до SAST, DAST, SonarQube и других анализаторов кода.  

При успешно пройденных тестах приложение можно упаковать в докер-образ и загрузить в хранилище образов (этап релиза), чтобы затем развернуть на нужном окружении (этап развертывания). 

При непрерывном развертывании финальный этап развертывания на продуктовое окружение осуществляется с ручным контролем ("деплой по кнопке").  
При непрерывной доставке финальный этап развертывания на продуктовую среду автоматизирован полностью, без вмешательства человека.  


## Пример модульного пайплайна 
(из моего учебного проекта [momo-store](https://github.com/sudmed/momo-store)) 
#### Пайплайн включает 2 этапа: собственно запуск отдельных модулей фронтэнда и бекэнда, а также этап установки (обновления) SSL-сертификата certbot'ом
```yaml
stages:
  - module-pipelines
  - certbot

frontend:
  stage: module-pipelines
  trigger:
    include:
      - "/frontend/.gitlab-ci.yml"
    strategy: depend 
  only:
    changes: 
      - frontend/**/*

backend:
  stage: module-pipelines
  trigger:
    include:
      - "/backend/.gitlab-ci.yml"
    strategy: depend 
  only:
    changes:  
      - backend/**/* 

deploy-certbot:
  stage: certbot
  image: alpine:3.15.0
  before_script:
    - apk add openssh-client bash docker docker-compose
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
    - chmod 644 ~/.ssh/known_hosts
    - docker context create momo --docker "host=ssh://${DEV_USER}@${DEV_HOST}"
  script:
    - docker-compose -H ssh://${DEV_USER}@${DEV_HOST} up --detach certbot
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```


## Пример пайплайна для бекэнда на Go
(из моего учебного проекта [momo-store](https://github.com/sudmed/momo-store)) 
#### Пайплайн включает 5 этапов: 
1) сборка исходного кода (и отправка архива с бинарем в хранилище Sonatype Nexus 3).
2) тестирование (`go test`, SonarScanner, SpotBugs SAST, Gosec SAST).
3) упаковка в докер-образ.
4) отправка образа в хранилище GitLab Container Registry.
5) развертывание образа из GitLab Container Registry при помощи Docker Swarm mode.


```yaml
variables:
  VERSION: 1.0.${CI_PIPELINE_ID}
  SAST_EXCLUDED_ANALYZERS: "eslint-sast,nodejs-scan-sast"

include:
  - template: Security/SAST.gitlab-ci.yml
  - project: 'templates/ci'
    file: 'DockerInDockerTemplate.yml'

stages:
  - build
  - test
  - docker-build
  - docker-release
  - deploy

build-backend:
  stage: build
  image: 
    name: golang:1.19.3
    entrypoint: [""]
  script:
    - echo "ARTIFACT_JOB_ID=${CI_JOB_ID}" > CI_JOB_ID.txt
    - cd backend
    - mkdir -p temp
    - go build -o temp ./...
    - cd ..
    - mkdir -p momo-store-${VERSION}
    - mv backend/temp/api momo-store-${VERSION}/backend-${VERSION}
  after_script:
    - tar czvf momo-store-${VERSION}.tar.gz momo-store-${VERSION}
    - curl -v -u "${NEXUS_USER}:${NEXUS_PASS}" --upload-file momo-store-$VERSION.tar.gz ${NEXUS_URL}/06-momostore-pashkov-backend/$VERSION/momo-store-backend-$VERSION.tar.gz
  artifacts:
    paths:
      - momo-store-${VERSION}/backend-${VERSION}
    reports:
      dotenv: CI_JOB_ID.txt
  rules:
    - changes:
      - backend/**/*

TestFakeAppIntegrational:
  image:
    name: golang:1.19.3
    entrypoint: [""]
  stage: test
  script:
    - cd backend
    - go test -v ./...
  rules:
    - changes:
        - backend/**/*

sonarqube-backend:
  stage: test
  image:
    name: sonarsource/sonar-scanner-cli:latest
    entrypoint: [""]
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
    GIT_DEPTH: "0"
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - cd backend
    - sonar-scanner -Dsonar.projectKey=${SONAR_PROJECT_KEY_BACKEND} -Dsonar.sources=. -Dsonar.host.url=${SONARQUBE_URL} -Dsonar.login=${SONAR_LOGIN}
  rules:
    - changes:
      - backend/**/*
  dependencies:
    - build-backend

spotbugs-sast:
  stage: test
  dependencies:
    - build-backend

gosec-sast:
  variables:
    COMPILE: "false"

docker-build:
  stage: docker-build
  image: docker:20.10.12-dind-rootless
  before_script:
    - until docker info; do sleep 1; done
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - mkdir -p $HOME/.docker
    - echo "$DOCKER_AUTH_CONFIG" > $HOME/.docker/config.json
  script:
    - cd backend
    - >
      docker build
      --no-cache
      --build-arg VERSION=$VERSION
      --tag $CI_REGISTRY_IMAGE/momo-backend:$VERSION
      .
    - until docker info; do sleep 1; done
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE/momo-backend:$VERSION
  dependencies:
    - sonarqube-backend

docker-release:
  stage: docker-release
  image: docker:20.10.12-dind-rootless
  variables:
    GIT_STRATEGY: none
  before_script:
    - until docker info; do sleep 1; done
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $CI_REGISTRY_IMAGE/momo-backend:$VERSION
    - docker tag $CI_REGISTRY_IMAGE/momo-backend:$VERSION $CI_REGISTRY_IMAGE/momo-backend:latest
    - docker push $CI_REGISTRY_IMAGE/momo-backend:latest

deploy-backend:
  stage: deploy
  image: alpine:3.15.0
  before_script:
    - apk add openssh-client bash docker
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY_SWARM" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan -H $SWARM_HOST >> ~/.ssh/known_hosts
    - chmod 644 ~/.ssh/known_hosts
    - docker context create momo --docker "host=ssh://${SWARM_USER}@${SWARM_HOST}"
    - docker --context momo login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - if docker --context momo stack ls | grep momo-store | awk '{print $1;}';
      then
        echo "Momo-store stack found. Updating backend service only...";
        docker --context momo service update --with-registry-auth --image $CI_REGISTRY_IMAGE/momo-backend:$VERSION momo-store_backend;
      else
        echo "No momo-store services found. Full stack deploy started...";
        docker --context momo stack deploy --with-registry-auth --resolve-image always --prune --compose-file docker-compose-stack.yml momo-store;
      fi
    - docker -H ssh://${SWARM_USER}@${SWARM_HOST} stack ls
    - docker --context momo service ls
```
