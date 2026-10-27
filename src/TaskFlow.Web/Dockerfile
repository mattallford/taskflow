# TaskFlow Web Frontend Dockerfile
# Multi-stage build for production-ready React application

# Build stage
FROM node:24-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install dependencies, including the Vite and TypeScript build tools
RUN npm ci --silent && \
    npm cache clean --force

# Copy source code
COPY src/ src/
COPY index.html tsconfig.json vite.config.ts ./

# Version shown in the footer, set by CI
ARG APP_VERSION=dev
ENV VITE_APP_VERSION=$APP_VERSION

# Build the React application for production
RUN npm run build

# Production stage - Nginx for serving static files
FROM nginx:1.30-alpine AS production

# Install wget for health checks
RUN apk add --no-cache wget

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built React application from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Create nginx run directory and set permissions
RUN mkdir -p /var/cache/nginx/client_temp && \
    mkdir -p /var/cache/nginx/proxy_temp && \
    mkdir -p /var/cache/nginx/fastcgi_temp && \
    mkdir -p /var/cache/nginx/uwsgi_temp && \
    mkdir -p /var/cache/nginx/scgi_temp && \
    mkdir -p /var/run && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/run/nginx.pid && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Switch to non-root user
USER nginx

# Expose port 3000 for the web application
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]