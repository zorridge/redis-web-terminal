FROM node:20-bullseye

# Install tools
RUN apt-get update && \
  apt-get install -y build-essential cmake git curl zip unzip tar redis-tools && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set up client
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY client ./client
COPY server.js ./

RUN npm install -g pnpm && \
  pnpm install

# Build redis server
COPY redis ./redis

WORKDIR /app/redis
RUN git clone https://github.com/microsoft/vcpkg.git && \
  ./vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/app/redis/vcpkg
RUN cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=/app/redis/vcpkg/scripts/buildsystems/vcpkg.cmake && \
  cmake --build ./build

# Expose ports
EXPOSE 8080 6379

# Start servers
WORKDIR /app
CMD ["sh", "-c", "/app/redis/build/server & pnpm run start"]

