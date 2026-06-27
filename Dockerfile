# Stage 1 — Flutter Web Build
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Dependencies zuerst cachen (nur neu laden wenn pubspec sich ändert)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Quellcode und Assets kopieren
COPY . .

# Lokalisierungen generieren und Web bauen
RUN flutter gen-l10n && flutter build web --release

# Stage 2 — nginx Production Server
FROM nginx:alpine

# Gebaute Web-App ins nginx-Verzeichnis
COPY --from=builder /app/build/web /usr/share/nginx/html

# Nginx-Konfiguration (SPA-Routing: alle Pfade auf index.html)
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
