# Локальная Kubernetes-стенд (Terraform + Ansible + Kubeadm + GitLab Registry)

Этот репозиторий разворачивает локальный Kubernetes-кластер на libvirt и запускает в нём ваш проект `web`.

## Что разворачивается

* `3` виртуальные машины в libvirt:

  * `k8s-master-1` (`10.10.10.10`)
  * `k8s-worker-1` (`10.10.10.11`)
  * `k8s-worker-2` (`10.10.10.12`)
* Kubernetes через `kubeadm + containerd`
* Контроллер `ingress-nginx` внутри кластера
* `Argo CD` для GitOps-деплоя из этого репозитория
* Локальный GitLab Container Registry на `gitlab.local:5050`
* Веб-стек в namespace `web`:

  * `nextapp`, `fastapi`, `postgres`, `redis`, `mongo-gridfs`
  * bootstrap-задачи: `fill-db`, `gridfs-loader`

## Структура проекта

* `terraform/` — инфраструктура libvirt и описание ВМ
* `ansible/` — bootstrap kubeadm и настройка кластера
* `k8s/` — манифесты Kubernetes (kustomize)
* `web/` — исходники приложения и Dockerfile
* `gitlab-local/` — локальный GitLab
* `scripts/` — скрипты для настройки хоста и сборки/публикации образов

## Требования

* Ubuntu-хост с `libvirt`, `qemu-kvm`, `terraform`, `ansible`, `docker`
* Базовый образ для libvirt:

  * `/var/lib/libvirt/images/ubuntu-pool/ubuntu-jammy-base.qcow2`
* SSH-ключ из `terraform/envs/dev/terraform.tfvars` должен работать для доступа к ВМ

## Домены и хостнеймы

Запустите:

```bash
./scripts/host-setup.sh
```

Это обновит локальный `/etc/hosts`:

* `127.0.0.1 gitlab.local`
* `10.10.10.10 app.lab.local`
* `10.10.10.10 api.lab.local`
* `10.10.10.10 argocd.lab.local`

## Процесс развертывания

1. Запуск локального GitLab:

```bash
cd gitlab-local
docker compose up -d
```

2. Создание ВМ:

```bash
terraform -chdir=terraform/envs/dev init -reconfigure \
  -backend-config="address=http://gitlab.local/api/v4/projects/<project_id>/terraform/state/dev" \
  -backend-config="lock_address=http://gitlab.local/api/v4/projects/<project_id>/terraform/state/dev/lock" \
  -backend-config="unlock_address=http://gitlab.local/api/v4/projects/<project_id>/terraform/state/dev/lock" \
  -backend-config="username=<gitlab-username>" \
  -backend-config="password=<gitlab-access-token>" \
  -backend-config="lock_method=POST" \
  -backend-config="unlock_method=DELETE"
terraform -chdir=terraform/envs/dev apply
```

Файл `backend.tf` уже содержит `backend "http" {}`, передаются только параметры доступа через `init`.

3. Bootstrap Kubernetes-кластера (один раз):

```bash
ansible-playbook -i ansible/inventory/terraform.py ansible/site.yml
```

Будут установлены:

* базовые компоненты Kubernetes
* ingress-nginx
* Argo CD
* Argo CD Application `web`, отслеживающее `k8s/base` из Git

Если кластер уже поднят и нужно только настроить/обновить Argo CD:

```bash
ansible-playbook -i ansible/inventory/terraform.py ansible/argocd.yml
```

4. Сборка и публикация образов в GitLab Registry:

```bash
./scripts/build-and-push.sh
```

Если registry приватный, экспортируйте креды:

```bash
export GITLAB_REGISTRY_USER="<gitlab-username>"
export GITLAB_REGISTRY_PASSWORD="<gitlab-password-or-token>"
```

5. Первичный деплой (один раз, дальше Argo CD сам):

```bash
ansible-playbook -i ansible/inventory/terraform.py ansible/deploy-web.yml
```

## Дальнейшая работа

* Инфраструктура (`terraform/`, базовая настройка kubeadm) — одноразовая
* Изменения в Kubernetes (реплики, ingress, ресурсы, теги образов) — через Git (`k8s/`)
* Argo CD автоматически синхронизирует состояние кластера
* CI/CD собирает образы и обновляет теги в `k8s/base/*.yml`

Переменные CI/CD:

* `GITLAB_REGISTRY_PASSWORD`
* `GITLAB_REGISTRY_USER` (опционально, по умолчанию `root`)
* `TF_HTTP_USERNAME` / `TF_HTTP_PASSWORD` (опционально, по умолчанию `gitlab-ci-token` + `$CI_JOB_TOKEN`)

## Доступ

* Фронтенд: `http://app.lab.local`
* API: `http://api.lab.local`
* Argo CD UI: `http://argocd.lab.local`
* GitLab: `http://gitlab.local`
* Registry: `http://gitlab.local:5050`

## Полезные проверки

```bash
ssh ubuntu@10.10.10.10 "kubectl get nodes -o wide"
ssh ubuntu@10.10.10.10 "kubectl -n web get pods,svc,ingress"
ssh ubuntu@10.10.10.10 "kubectl -n ingress-nginx get pods"
```

## Примечания

* Динамический inventory генерируется из вывода Terraform: `ansible/inventory/terraform.py`
* `containerd` на всех нодах настроен на использование локального registry `gitlab.local:5050`
* `ingress-nginx` настроен с `hostNetwork: true` на `k8s-master-1` для локального bare-metal доступа
* URL репозитория Argo CD по умолчанию: `http://10.10.10.1/root/terraform.git`
  При необходимости измените в `ansible/group_vars/all.yml`
