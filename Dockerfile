ARG NGINX_BASE_IMAGE

FROM ${NGINX_BASE_IMAGE} as production-stage

# Create non-root user and set up permissions in one layer
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser && \
    chown -R appuser:appuser /var/cache/nginx && \
    chown -R appuser:appuser /var/log/nginx && \
    chown -R appuser:appuser /etc/nginx && \
    chown -R appuser:appuser /tmp && \
    chown -R appuser:appuser /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER appuser
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
