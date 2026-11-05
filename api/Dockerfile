FROM eclipse-temurin:11-jdk

ARG API_TAG=2026-04
ARG SBT_VERSION=1.10.7

RUN apt-get update && apt-get install -y --no-install-recommends git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# sbt launcher (the project's build.properties selects the real sbt version)
RUN curl -fsSL https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz \
    | tar -xz -C /opt
ENV PATH="/opt/sbt/bin:${PATH}"

WORKDIR /app
RUN git clone https://github.com/Systems-Modeling/SysML-v2-API-Services.git . \
    && git checkout ${API_TAG}

# Warm the dependency cache at build time (shared volume refreshes at runtime if needed)
RUN sbt -batch update || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
