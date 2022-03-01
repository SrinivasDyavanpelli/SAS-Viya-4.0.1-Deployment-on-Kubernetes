FROM jupyterhub/k8s-singleuser-sample:0.9.0
ARG NB_USER=jovyan
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libnuma1 \
      && \
    apt-get purge && apt-get clean
RUN python3 -m pip install swat
USER ${NB_USER}