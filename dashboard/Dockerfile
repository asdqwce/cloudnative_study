FROM nginxinc/nginx-unprivileged:alpine
COPY --chown=nginx:nginx . /usr/share/nginx/html
EXPOSE 8080
USER nginx
CMD ["nginx", "-g", "daemon off;"]
