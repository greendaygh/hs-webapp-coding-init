ARG NODE_VERSION={{node_version}}
FROM node:${NODE_VERSION}-alpine AS build

WORKDIR /app
COPY {{frontend_dir}}/package*.json ./
RUN npm ci
COPY {{frontend_dir}}/ ./
COPY .env.production ./
RUN npm run build

FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/dist /usr/share/nginx/html
COPY assets/docker/nginx.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 80
