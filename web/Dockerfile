FROM nginx:1.30.5-alpine
# the nginx image renders /etc/nginx/templates/*.template with the container's env vars at start
COPY templates/ /etc/nginx/templates/
COPY public/ /usr/share/nginx/html/
