ARG ARGOCD_VERSION=v0.12.1
FROM argoproj/argocd:$ARGOCD_VERSION as argocd

FROM node:11.10.1-slim

RUN apt-get update && apt-get install -y git apt-utils sudo python make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/argocd/argocd-bot

COPY --from=argocd /usr/local/bin/argocd /usr/local/bin/argocd
COPY --from=argocd /usr/local/bin/helm /usr/local/bin/helm
COPY --from=argocd /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=argocd /usr/local/bin/ks /usr/local/bin/ks

RUN groupadd -g 999 argocd && \
    useradd -r -u 999 -g argocd argocd && \
    chown argocd:argocd /home/argocd && \
    chown argocd:argocd /home/argocd/argocd-bot

# allow argocd user to have sudo access (for quickly debugging things inside the pod)
RUN echo "argocd ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY --chown=argocd . ./
#workaround https://github.com/golang/go/issues/14625
ENV USER=argocd
USER argocd

# run npm as argocd user
RUN npm install && npm run build && npm run test
