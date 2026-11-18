ARG NGINX_BASE_IMAGE

FROM ghcr.io/jqlang/jq:1.8.2@sha256:1e7ad54d387c3ee4cb921f8a9de0d7f2359b375f04a37d10255fda4cd119029a AS jq-source

FROM ${NGINX_BASE_IMAGE} as production-stage

# Create non-root user and set up permissions in one layer
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser && \
    chown -R appuser:appuser /var/cache/nginx && \
    chown -R appuser:appuser /var/log/nginx && \
    chown -R appuser:appuser /etc/nginx && \
    chown -R appuser:appuser /tmp && \
    chown -R appuser:appuser /usr/share/nginx/html

COPY --from=jq-source /jq /usr/local/bin/jq
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER appuser
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
