# Build stage
FROM debian:latest AS build-env

# Install Flutter dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Switch to stable channel
RUN flutter channel stable
RUN flutter upgrade

# Copy files
WORKDIR /app
COPY . .

# Build web
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release

# Serving stage
FROM nginx:1.25.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
