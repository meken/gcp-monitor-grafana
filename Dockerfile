FROM grafana/grafana:9.3.2

COPY datasources.yaml /etc/grafana/provisioning/datasources/
COPY dashboards.yaml /etc/grafana/provisioning/dashboards/
COPY sample-dashboards/*.json /var/lib/grafana/dashboards/

USER root
RUN chown -R grafana /etc/grafana/provisioning
RUN chown -R grafana /var/lib/grafana/
USER grafana