FROM nginx:1.27-alpine

ARG VERSION=local-dev
ARG BUILD_TIME=unknown
ARG ENVIRONMENT=dev

WORKDIR /usr/share/nginx/html

RUN rm -rf ./*

COPY src/ .

RUN cat > /usr/share/nginx/html/version.js <<EOF_VERSION
window.__BUILD_INFO__ = {
  version: "${VERSION}",
  buildTime: "${BUILD_TIME}",
  environment: "${ENVIRONMENT}"
};
EOF_VERSION

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
