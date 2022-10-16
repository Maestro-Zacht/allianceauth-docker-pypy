FROM ubuntu:22.04 as copy
ARG AUTH_VERSION

RUN echo "${AUTH_VERSION}"

RUN apt-get update && apt-get upgrade -y && apt-get install -y git
RUN git clone https://gitlab.com/allianceauth/allianceauth.git /allianceauth
WORKDIR /allianceauth
RUN git checkout tags/v${AUTH_VERSION}

FROM pypy:3.9-slim
ARG AUTH_VERSION
ARG AUTH_PACKAGE=allianceauth==${AUTH_VERSION}
ENV VIRTUAL_ENV=/opt/venv
ENV AUTH_USER=allianceauth
ENV AUTH_GROUP=allianceauth
ENV AUTH_USERGROUP=${AUTH_USER}:${AUTH_GROUP}
ENV STATIC_BASE=/var/www
ENV AUTH_HOME=/home/allianceauth

RUN echo "${AUTH_VERSION}"

# Setup user and directory permissions
SHELL ["/bin/bash", "-c"]
RUN groupadd -g 61000 ${AUTH_GROUP}
RUN useradd -g 61000 -l -M -s /bin/false -u 61000 ${AUTH_USER}
RUN mkdir -p ${VIRTUAL_ENV} \
    && chown ${AUTH_USERGROUP} ${VIRTUAL_ENV} \
    && mkdir -p ${STATIC_BASE} \
    && chown ${AUTH_USERGROUP} ${STATIC_BASE} \
    && mkdir -p ${AUTH_HOME} \
    && chown ${AUTH_USERGROUP} ${AUTH_HOME}

# Install build dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    libmariadb-dev gcc supervisor git htop

# Switch to non-root user
USER ${AUTH_USER}
RUN pypy -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
WORKDIR ${AUTH_HOME}

# Install python dependencies
RUN pypy -m pip install --upgrade pip
RUN pypy -m pip install wheel gunicorn
RUN pypy -m pip install ${AUTH_PACKAGE}

# Initialize auth
RUN allianceauth start myauth
COPY --from=copy /allianceauth/allianceauth/project_template/project_name/settings/local.py ${AUTH_HOME}/myauth/myauth/settings/local.py
RUN allianceauth update myauth
RUN mkdir -p ${STATIC_BASE}/myauth/static
COPY --from=copy /allianceauth/docker/conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN echo 'alias auth="pypy $AUTH_HOME/myauth/manage.py"' >> ~/.bashrc && \
    echo 'alias supervisord="supervisord -c /etc/supervisor/conf.d/supervisord.conf"' >> ~/.bashrc && \
    source ~/.bashrc

EXPOSE 8000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]