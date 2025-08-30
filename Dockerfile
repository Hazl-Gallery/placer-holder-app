FROM nginx:alpine

COPY index.html /tmp/index.html

EXPOSE 80

CMD sh -c 'sed "s/\[PORT_PLACEHOLDER\]/${PORT:-80}/g" /tmp/index.html > /usr/share/nginx/html/index.html && nginx -g "daemon off;"'