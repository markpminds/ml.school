# Build an image that can serve mlflow models.
FROM ubuntu:20.04

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends wget curl nginx ca-certificates bzip2 build-essential cmake git-core

# Setup pyenv
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libevent-dev
RUN git clone \
    --depth 1 \
    --branch $(git ls-remote --tags --sort=v:refname https://github.com/pyenv/pyenv.git | grep -o -E 'v[1-9]+(\.[1-9]+)+$' | tail -1) \
    https://github.com/pyenv/pyenv.git /root/.pyenv
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"
RUN apt install -y python3.9 python3.9-distutils \
    && ln -s -f $(which python3.9) /usr/bin/python \
    && wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py \
    && python /tmp/get-pip.py
RUN pip install virtualenv

# Setup Java
RUN apt-get install -y --no-install-recommends openjdk-11-jdk maven
#ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
#ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Alternative approach - find Java path dynamically
RUN update-alternatives --query java | grep 'Value: ' | grep -o '/.*java' | sed 's/\/bin\/java//' > /tmp/java_path && \
    export JAVA_HOME=$(cat /tmp/java_path) && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "export PATH=$PATH:$JAVA_HOME/bin" >> /etc/environment

# Verify Java installation and JAVA_HOME
RUN echo "JAVA_HOME is set to: $JAVA_HOME" && \
    java -version && \
    javac -version && \
    mvn -version

WORKDIR /opt/mlflow

# Install MLflow
RUN pip install mlflow==2.17.1

# Install Java mlflow-scoring from Maven Central
# does not work, complains about JAVA_HOME variable being incorrect
RUN mvn --batch-mode dependency:copy -Dartifact=org.mlflow:mlflow-scoring:2.17.1:pom -DoutputDirectory=/opt/java 
RUN mvn --batch-mode dependency:copy -Dartifact=org.mlflow:mlflow-scoring:2.17.1:jar -DoutputDirectory=/opt/java/jars 
RUN cp /opt/java/mlflow-scoring-2.17.1.pom /opt/java/pom.xml
RUN cd /opt/java && mvn --batch-mode dependency:copy-dependencies -DoutputDirectory=/opt/java/jars 

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.9-dev \
    python3-dev \
    gcc \
    libevent-dev \
    make

# RUN pip install --no-cache-dir gevent==23.9.1
# Install minimal serving dependencies
# does not work, fails to build wheel for gevent
RUN python -c "from mlflow.models.container import _install_pyfunc_deps;_install_pyfunc_deps(None, False)"

ENV MLFLOW_DISABLE_ENV_CREATION=False
ENV ENABLE_MLSERVER=False
ENV GUNICORN_CMD_ARGS="--timeout 60 -k gevent"

# granting read/write access and conditional execution authority to all child directories
# and files to allow for deployment to AWS Sagemaker Serverless Endpoints
# (see https://docs.aws.amazon.com/sagemaker/latest/dg/serverless-endpoints.html)
RUN chmod o+rwX /opt/mlflow/

# clean up apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["python", "-c", "import sys; from mlflow.models import container as C; C._init(sys.argv[1], 'local')"]
