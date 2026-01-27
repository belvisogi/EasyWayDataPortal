
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Run
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
# Copy static assets if any (e.g. for branding override if local)
# COPY --from=builder /app/src/queries ./src/queries (Legacy removed, but keep checks)

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/server.js"]
