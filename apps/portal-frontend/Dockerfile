# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
LABEL org.opencontainers.image.description="EasyWay Sovereign Frontend"

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Run as non-root (implicit in base image, but documenting)
USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
