FROM continuumio/miniconda3

ARG RELEASE_TAG=2026-08

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Python env + Java 21 (kernel runs with whatever `java` is on PATH)
RUN conda create -n sysml -y -c conda-forge python=3.11 openjdk=21
ENV PATH=/opt/conda/envs/sysml/bin:$PATH
ENV CONDA_DEFAULT_ENV=sysml CONDA_PREFIX=/opt/conda/envs/sysml

RUN git clone https://github.com/Systems-Modeling/SysML-v2-Release.git /opt/SysML-v2-Release \
    && cd /opt/SysML-v2-Release && git checkout ${RELEASE_TAG} \
    && cd install/jupyter && chmod +x install.sh \
    && source /opt/conda/etc/profile.d/conda.sh && conda activate sysml && ./install.sh

# Point %publish at the local API (overridable via ISYSML_API_BASE_PATH env)
COPY patch_kernel.py /patch_kernel.py
RUN python /patch_kernel.py http://api:9000

RUN mkdir -p /home/jovyan/notebooks
WORKDIR /home/jovyan/notebooks
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", \
     "--ServerApp.token=", "--ServerApp.password="]
