# Prepare the base environment.
FROM ubuntu:22.04 as builder_base

RUN apt-get update && apt-get install -y software-properties-common

RUN apt-get clean && \
apt-get upgrade -y \
vim \ 
gunicorn \
wget \
cron \
#python3-setuptools python3-pip python3 python3-dev python3-distutils
python3-pip python3-setuptools python3 python3-dev python3-distutils libpq-dev

FROM builder_base as python_libs
WORKDIR /app
COPY requirements.txt ./
RUN python3 -m pip install --no-cache-dir -r requirements.txt \
  # Update the Django <1.11 bug in django/contrib/gis/geos/libgeos.py
  # Reference: https://stackoverflow.com/questions/18643998/geodjango-geosexception-error
  # && sed -i -e "s/ver = geos_version().decode()/ver = geos_version().decode().split(' ')[0]/" /usr/local/lib/python2.7/dist-packages/django/contrib/gis/geos/libgeos.py \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/*

# Install the project (ensure that frontend projects have been built prior to this step).
FROM python_libs
COPY gunicorn.ini manage.py ./

#touch /app/.env
#COPY .git ./.git
COPY mysite ./mysite
RUN python3 manage.py collectstatic --noinput && \
mkdir /app/tmp/ && \
chmod 777 /app/tmp/

COPY cron /etc/cron.d/dockercron
COPY startup.sh /
#COPY nginx-default.conf /etc/nginx/sites-enabled/default
# Cron start
#RUN service rsyslog start
RUN chmod 0644 /etc/cron.d/dockercron
RUN crontab /etc/cron.d/dockercron
RUN touch /var/log/cron.log
RUN service cron start
RUN chmod 755 /startup.sh

# Health checks for kubernetes 
#RUN wget https://raw.githubusercontent.com/dbca-wa/wagov_utils/main/wagov_utils/bin/health_check.sh -O /bin/health_check.sh
#RUN chmod 755 /bin/health_check.sh

EXPOSE 8080
HEALTHCHECK --interval=1m --timeout=5s --start-period=10s --retries=3 CMD ["wget", "-q", "-O", "-", "http://localhost:8080/"]
CMD ["/startup.sh"]
#CMD ["gunicorn", "commercialoperator.wsgi", "--bind", ":8080", "--config", "gunicorn.ini"]
