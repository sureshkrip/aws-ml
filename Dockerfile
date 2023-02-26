FROM jupyterhub/jupyterhub:latest
EXPOSE 8000
RUN pip install notebook

ENV USERNAME=admin
ENV PASSWORD=admin

RUN useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G sudo ${USERNAME}
USER admin
WORKDIR /home/admin
CMD ["jupyterhub"]