FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# -- ENV --
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV CPLUS_INCLUDE_PATH=$CUDA_HOME/include
ENV C_INCLUDE_PATH=$CUDA_HOME/include



# -- System packages --
RUN apt-get update && apt-get install -y \
    git \
    ninja-build \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    build-essential \
    python3 \
    python3-pip \
    python3-dev \
    wget \
    curl \
    unzip \
    libssl-dev \
    libffi-dev


# -- Set workdir --
WORKDIR /app
COPY . .

# -- Upgrade pip & install torch before diso --
RUN pip3 install --upgrade pip
RUN pip3 install torch==2.0.1 torchvision==0.15.2 --index-url https://download.pytorch.org/whl/cu118

# -- diso needs torch during build --
RUN pip3 install --no-cache-dir -r requirements.txt

# -- Port for FastAPI --
EXPOSE 7860

RUN pip3 install uvicorn[standard]

# -- Start FastAPI --
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
