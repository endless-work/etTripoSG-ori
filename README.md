# TripoSG 3D Generation Model Deployment Guide for DockerHub

0. Login docker hub

  docker login

1. Build local docker image 

  docker build --platform=linux/amd64 -t etstas/etapp-tripo:latest .

2. Push on docker hub repo

  docker push etstas/etapp-tripo:latest




# TripoSG 3D Generation Model Deployment Guide for GITHUB

This guide walks you through deploying your TripoSG-based 3D generation model using Docker and hosting it on a virtual machine (e.g. Ori or other cloud provider) with GPU support.

---

## 1. Prepare the GitHub Repository

1. Create a new GitHub repository.
2. Push your model code (TripoSG pipeline) to the repository.
3. Make sure to include:
   - `main.py` (FastAPI handler)
   - `Dockerfile` (to build the container)

---

## 2. Build Docker Image Locally

From the root of your repository, run:

```bash
docker build --platform=linux/amd64 -t triposg-app .
```

> We use `--platform=linux/amd64` to ensure compatibility with most GPU-enabled virtual machines.

---

## 3. Push Docker Image to GHCR (GitHub Container Registry)

1. [Create a GitHub token](https://github.com/settings/tokens) with `write:packages` permission.
2. Authenticate:

```bash
echo YOUR_GHCR_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

3. Tag and push the image:

```bash
docker tag triposg-app ghcr.io/YOUR_GITHUB_USERNAME/triposg-app:latest
docker push ghcr.io/YOUR_GITHUB_USERNAME/triposg-app:latest
```

---

## 4. Set Up Virtual Machine

1. Create a virtual machine with GPU support (e.g. on [Ori](https://ori.co/)).
2. SSH into the machine:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@YOUR_SERVER_IP
```

---

## 5. Pull and Run Docker Image

On the virtual machine:

```bash
docker pull ghcr.io/YOUR_GITHUB_USERNAME/triposg-app:latest
docker run -it --gpus all -p 7860:7860 ghcr.io/YOUR_GITHUB_USERNAME/triposg-app:latest
```

> This will launch the FastAPI server on port `7860`, accessible via `http://YOUR_SERVER_IP:7860`.

---

## 6. Call from Frontend

From your frontend (e.g. React or Next.js), you can now send requests to the VM using the FastAPI endpoint, e.g.:

```js
fetch("http://YOUR_SERVER_IP:7860/predict", {
  method: "POST",
  headers: {
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    image: "data:image/png;base64,...",
    prompt: "generate 3d"
  })
})
```

---

## ✅ You're all set!









# 🚀 Инструкция по деплою модели TripoSG через Docker, GHCR и Виртуальную машину

---

## 1. 📦 Создание GitHub репозитория

Создай новый репозиторий (например, `triposg-app`) с такой структурой:

```
triposg-app/
├── triposg/                  # Код модели
├── main.py                  # FastAPI хендлер
├── requirements.txt         # Зависимости
├── Dockerfile               # Docker-инструкции
```

---

## 2. 🧱 Сборка Docker-образа под нужную архитектуру

```bash
docker build --platform=linux/amd64 -t triposg-app .
```

> Платформа `amd64` нужна, потому что серверы с GPU используют именно её.

---

## 3. 🏷️ Тегирование образа для GHCR

```bash
docker tag triposg-app ghcr.io/staswrs/triposg-app:latest
```

> Это связывает твой локальный образ с удалённым адресом в GHCR.

---

## 4. 🚀 Публикация образа в GHCR

```bash
docker push ghcr.io/staswrs/triposg-app:latest
```

> Перед этим выполни логин:
```bash
echo YOUR_GHCR_TOKEN | docker login ghcr.io -u staswrs --password-stdin
```

---

## 5. 🔧 Подготовка виртуальной машины с GPU

На сервере (Ori, AWS, etc.):

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

Перезапусти сессию или выполни `newgrp docker`.

---

## 6. 🔐 Подключение к серверу

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@141.95.174.49
```

---

## 7. ⚙️ Установка NVIDIA драйверов

```bash
sudo apt install -y nvidia-driver-535 nvidia-container-toolkit
sudo systemctl restart docker
```

Проверка:

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

---

## 8. 📥 Загрузка образа с GHCR

```bash
docker pull ghcr.io/staswrs/triposg-app:latest
```

---

## 9. ▶️ Запуск сервиса

```bash
docker run -it --gpus all -p 7860:7860 ghcr.io/staswrs/triposg-app:latest
```

> Теперь FastAPI доступен по `http://141.95.174.49:7860`

---

## 10. 🌐 Запросы с фронта

```js
await fetch("http://141.95.174.49:7860/predict", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    imageBase64: "...",
    prompt: "...",
    ...
  }),
});
```

---

## ✅ Готово!


