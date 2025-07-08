# Dockerfile
FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# Установка зависимостей
RUN apt-get update && \
    apt-get install -y python3 python3-pip git && \
    apt-get clean

# Копируем код
WORKDIR /app
COPY . /app

# Установка Python-зависимостей
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

# Порт FastAPI
EXPOSE 7860

# Запуск FastAPI
CMD ["python3", "main.py"]
