# Local Kubernetes Infrastructure Lab

Учебный DevOps-проект, демонстрирующий полный путь от виртуальной инфраструктуры до доставки веб-приложения в Kubernetes.

Проект создан как практический стенд для изучения Terraform, Ansible, Kubernetes, GitLab CI/CD и GitOps-подхода с Argo CD.

## Цель проекта

Автоматизировать развёртывание веб-приложения на локальном Kubernetes-кластере, работающем поверх трёх виртуальных машин в libvirt:

- один control plane;
- две worker-ноды;
- containerd в качестве container runtime;
- ingress-nginx для внешнего доступа;
- Argo CD для GitOps-деплоя;
- локальный GitLab Registry для хранения образов.

## Архитектура

```text
Terraform
    │
    ├── libvirt network
    └── 3 virtual machines
            │
            ▼
        Ansible
            │
            ├── базовая настройка ОС
            ├── containerd и Kubernetes packages
            ├── kubeadm control plane
            ├── join worker-нод
            └── CNI, ingress-nginx, Argo CD
                    │
                    ▼
              Kubernetes cluster
                    │
                    ├── Next.js frontend
                    ├── FastAPI backend
                    ├── PostgreSQL
                    ├── Redis
                    ├── MongoDB/GridFS
                    └── bootstrap Jobs
```

## Технологический стек

### Infrastructure

- Terraform;
- libvirt / QEMU-KVM;
- cloud-init;
- Terraform HTTP backend в GitLab;
- статическая адресация VM внутри libvirt network.

### Configuration management

- Ansible;
- динамический inventory из Terraform outputs;
- отдельные роли для common configuration, containerd, Kubernetes, kubeadm и Argo CD;
- идемпотентный bootstrap-контур.

### Platform

- Kubernetes, установленный через kubeadm;
- containerd;
- Flannel CNI;
- ingress-nginx;
- local persistent volumes;
- Argo CD.

### Application delivery

- GitLab CI/CD;
- Docker images в локальном GitLab Container Registry;
- immutable image tags на основе commit SHA;
- автоматическое обновление Kustomize image tags;
- автоматическая проверка rollout и smoke tests.

## Структура репозитория

```text
terraform/          Инфраструктура libvirt и описание виртуальных машин
ansible/            Bootstrap ОС, Kubernetes и Argo CD
k8s/                Kubernetes manifests и Kustomize base
web/                Исходный код frontend/backend и database jobs
gitlab-local/       Локальный GitLab и Container Registry
monitoring/         Prometheus, Grafana, Loki и Grafana Alloy
scripts/            Сборка образов, inventory checks и CI utilities
```

## Локальный monitoring stack

Мониторинг запускается отдельным Docker Compose-стеком на хосте, по аналогии с локальным GitLab:

- Prometheus — сбор метрик;
- Grafana — dashboards и единая точка просмотра;
- Loki — хранение логов;
- Grafana Alloy — сбор Docker container logs и отправка в Loki;
- Node Exporter — метрики хоста;
- cAdvisor — метрики Docker-контейнеров.

Основные endpoints:

- Grafana: `http://localhost:3000`;
- Prometheus: `http://localhost:9090`;
- Loki: `http://localhost:3100`.

Перед запуском нужно создать `monitoring/.env` на основе `monitoring/.env.example` и задать собственный пароль Grafana.

Grafana автоматически получает Prometheus и Loki как datasources, а dashboard `Infrastructure overview` подключается через provisioning. Данные Prometheus, Grafana и Loki сохраняются в `monitoring/volumes/`, которые не добавляются в Git.

Текущая конфигурация собирает метрики и Docker-логи локального хоста, включая GitLab и monitoring stack. Логи Kubernetes workload’ов, работающих внутри VM, пока требуют отдельного агента в кластере или на Kubernetes-нодах.

## GitOps и CI/CD flow

1. Изменения в application code запускают pipeline GitLab CI.
2. Pipeline собирает и публикует образы в GitLab Registry.
3. Для образов формируется tag из короткого SHA коммита.
4. CI обновляет tags в `k8s/base/kustomization.yml`.
5. Argo CD отслеживает этот каталог и синхронизирует состояние Kubernetes.
6. После синхронизации pipeline проверяет rollout frontend/backend и выполняет smoke tests.

Terraform и Ansible отвечают за инфраструктурный bootstrap, а дальнейшие изменения приложения доставляются через GitOps.

## Реализованные инженерные решения

- Динамический Ansible inventory строится из Terraform state.
- Состав кластера проверяется Terraform validation rules.
- Worker-ноды присоединяются до установки cluster addons.
- Kubernetes-ноды получают фиксированные имена и адреса.
- Для stateful workloads используются local PV и отдельные storage paths.
- Containerd настроен на работу с локальным registry.
- SSH password authentication отключена, доступ выполняется по ключу.
- CI проверяет Terraform, Ansible, доступность Kubernetes-нод и rollout приложения.
