#Base image
FROM jupyterhub/jupyterhub:latest
#USER root

# update Ubuntu
RUN apt-get update && apt-get install wget


# Install jupyter, awscli and s3contents (for storing notebooks on S3)
RUN pip install jupyter  && \
    pip install s3contents  && \
    pip install awscli --upgrade --user  && \
    mkdir /etc/jupyter

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc && \
    rm -rf /var/lib/apt/lists/*

# Fix for devtools https://github.com/conda-forge/r-devtools-feedstock/issues/4
RUN ln -s /bin/tar /bin/gtar

RUN wget -qO ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && /bin/bash ~/miniconda.sh -b -p /opt/conda && rm ~/miniconda.sh && /opt/conda/bin/conda clean -ya
# R packages

RUN /opt/conda/bin/conda install -c r r-IRkernel && \
    /opt/conda/bin/conda install -c r rstudio && \
    /opt/conda/bin/conda install -c r/label/borked rstudio && \
    /opt/conda/bin/conda install -c r r-devtools  && \
    /opt/conda/bin/conda install -c r r-ggplot2 r-dplyr  && \
    /opt/conda/bin/conda install -c plotly plotly  && \
    /opt/conda/bin/conda install -c plotly/label/test plotly  && \ 
    /opt/conda/bin/conda update curl  && \
    /opt/conda/bin/conda install -c bioconda bcftools  && \
    /opt/conda/bin/conda install -c bioconda/label/cf201901 bcftools  

RUN R -e "devtools::install_github('IRkernel/IRkernel')"  && \
    R -e "IRkernel::installspec()"

#S3ContentManager Config
RUN echo 'from s3contents import S3ContentsManager' >> /etc/jupyter/jupyter_notebook_config.py  && \
    echo 'c = get_config()' >> /etc/jupyter/jupyter_notebook_config.py  && \
    echo 'c.NotebookApp.contents_manager_class = S3ContentsManager' >> /etc/jupyter/jupyter_notebook_config.py  && \
    echo 'c.S3ContentsManager.access_key_id = "AKIAZSLJQDLPIB6MDLND"' >> /etc/jupyter/jupyter_notebook_config.py  && \
    echo 'c.S3ContentsManager.secret_access_key = "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"' >> /etc/jupyter/jupyter_notebook_config.py  && \
    echo 'c.S3ContentsManager.bucket = "vishaljuypterhub"' >> /etc/jupyter/jupyter_notebook_config.py

#JupyterHub Config
RUN echo "c = get_config()" >> /srv/jupyterhub/jupyterhub_config.py  && \
    echo "c.Spawner.env_keep = ['AWS_DEFAULT_REGION','AWS_EXECUTION_ENV','AWS_REGION','AWS_CONTAINER_CREDENTIALS_RELATIVE_URI','ECS_CONTAINER_METADATA_URI']" >> /srv/jupyterhub/jupyterhub_config.py  && \
    echo "c.Spawner.cmd = ['/opt/conda/bin/jupyterhub-singleuser']" >> /srv/jupyterhub/jupyterhub_config.py

#Add PAM users
RUN useradd --create-home user3  && \
    echo "user3:user3"|chpasswd  && \
    echo "export PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/user3/.profile  && \
    mkdir -p /home/user3/.local/share/jupyter/kernels/ir  && \
    cp /root/.local/share/jupyter/kernels/ir/* /home/user3/.local/share/jupyter/kernels/ir/  && \
    chown -R user3:user3 /home/user3

## Start jupyterhub using config file
CMD ["jupyterhub","-f","/srv/jupyterhub/jupyterhub_config.py"]