FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# -- ENV --
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV CPLUS_INCLUDE_PATH=$CUDA_HOME/include
ENV C_INCLUDE_PATH=$CUDA_HOME/include
ENV PYTHONUNBUFFERED=1

# Системные пакеты
RUN apt-get update && apt-get install -y \
    git ninja-build ffmpeg libgl1-mesa-glx libglib2.0-0 libsm6 \
    build-essential wget curl unzip libssl-dev libffi-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncursesw5-dev zlib1g-dev \
    tk-dev xz-utils llvm make liblzma-dev

# Установка Python 3.10
RUN cd /opt && \
    wget https://www.python.org/ftp/python/3.10.14/Python-3.10.14.tgz && \
    tar xzf Python-3.10.14.tgz && \
    cd Python-3.10.14 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    /usr/local/bin/python3.10 -m ensurepip --upgrade && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/local/bin/pip3.10 /usr/bin/pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Копируем проект
WORKDIR /app
COPY . .

# Обновляем pip
RUN pip install --upgrade pip

# Устанавливаем torch и torchvision (до зависимостей)
RUN pip install torch==2.0.1 torchvision==0.15.2 --index-url https://download.pytorch.org/whl/cu118

# Устанавливаем wheel (нужно для C++ extensions)
RUN pip install wheel

# Устанавливаем зависимости (без diso — он будет отдельно)
RUN pip install -r requirements.txt

# Устанавливаем diso отдельно после torch
RUN pip install --no-build-isolation git+https://github.com/SarahWeiii/diso.git


# Uvicorn
RUN pip install uvicorn[standard]

# Порт
EXPOSE 7860

# Команда запуска
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]




# FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# # -- ENV --
# ENV DEBIAN_FRONTEND=noninteractive
# ENV CUDA_HOME=/usr/local/cuda
# ENV PATH=$CUDA_HOME/bin:$PATH
# ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
# ENV TORCH_CUDA_ARCH_LIST="8.6"
# ENV CPLUS_INCLUDE_PATH=$CUDA_HOME/include
# ENV C_INCLUDE_PATH=$CUDA_HOME/include



# # -- System packages --
# RUN apt-get update && apt-get install -y \
#     git \
#     ninja-build \
#     ffmpeg \
#     libgl1-mesa-glx \
#     libglib2.0-0 \
#     libsm6 \
#     build-essential \
#     python3 \
#     python3-pip \
#     python3-dev \
#     wget \
#     curl \
#     unzip \
#     libssl-dev \
#     libffi-dev


# # -- Set workdir --
# WORKDIR /app
# COPY . .

# # -- Upgrade pip & install torch before diso --
# RUN pip3 install --upgrade pip
# RUN pip3 install torch==2.0.1 torchvision==0.15.2 --index-url https://download.pytorch.org/whl/cu118

# # -- diso needs torch during build --
# RUN pip3 install --no-cache-dir -r requirements.txt

# # -- Port for FastAPI --
# EXPOSE 7860

# RUN pip3 install uvicorn[standard]

# # -- Start FastAPI --
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
