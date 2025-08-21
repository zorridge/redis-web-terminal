# --- Build Stage ---
FROM node:20-bullseye AS build

RUN apt-get update && \
  apt-get install -y build-essential cmake git curl zip unzip tar && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app/redis
COPY redis ./

RUN git clone https://github.com/microsoft/vcpkg.git && \
  ./vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/app/redis/vcpkg

RUN cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=/app/redis/vcpkg/scripts/buildsystems/vcpkg.cmake && \
  cmake --build ./build

# --- Runtime Stage ---
FROM node:20-bullseye

RUN apt-get update && \
  apt-get install -y redis-tools && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/redis/build/server /app/redis/build/server

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY client ./client
COPY server.js ./

RUN npm install -g pnpm && \
  pnpm install

EXPOSE 8080

CMD ["sh", "-c", "/app/redis/build/server & pnpm run start"]
