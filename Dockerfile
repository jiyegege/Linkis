FROM centos:7


USER root

RUN yum update -y && yum install -y openssh-server wget scala
RUN  yum -y update
RUN  yum -y install zip
RUN  yum -y install vim
RUN yum -y install telnet
RUN yum -y install dos2unix
RUN yum -y install sudo

RUN mkdir -p /usr/java
COPY docker_bin/pac/jdk-8u202-linux-x64.tar.gz /tmp/
RUN tar zxvf /tmp/jdk-8u202-linux-x64.tar.gz -C /usr/java/

ENV JAVA_HOME=/usr/java/jdk1.8.0_202
ENV JRE_HOME=$JAVA_HOME/jre
ENV CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH

RUN mkdir -p /tmp/
RUN wget -O /tmp/libaio-0.3.109-13.el7.x86_64.rpm -q http://mirror.centos.org/centos/7/os/x86_64/Packages/libaio-0.3.109-13.el7.x86_64.rpm
COPY docker_bin/pac/mysql-community-client-5.7.27-1.el6.x86_64.rpm /tmp/
COPY docker_bin/pac/mysql-community-common-5.7.27-1.el6.x86_64.rpm /tmp/
COPY docker_bin/pac/mysql-community-libs-5.7.27-1.el6.x86_64.rpm /tmp/
COPY docker_bin/pac/mysql-community-server-5.7.27-1.el6.x86_64.rpm /tmp/
RUN rpm -ivh /tmp/libaio-0.3.109-13.el7.x86_64.rpm
RUN yum -y install libaio.so.1
RUN  rpm -ivh /tmp/mysql-community-common-5.7.27-1.el6.x86_64.rpm --force --nodeps \
     && rpm -ivh /tmp/mysql-community-libs-5.7.27-1.el6.x86_64.rpm --force --nodeps \
     && rpm -ivh /tmp/mysql-community-client-5.7.27-1.el6.x86_64.rpm --force --nodeps \
     && rpm -ivh /tmp/mysql-community-server-5.7.27-1.el6.x86_64.rpm --force --nodeps

RUN ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P "" \
    && cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

COPY docker_bin/pac/hadoop-2.7.3.tar.gz ./hadoop.tar.gz
RUN tar xfz hadoop.tar.gz \
        && mv /hadoop-2.7.3 /usr/local/hadoop \
        && rm /hadoop.tar.gz

COPY docker_bin/pac/spark-2.4.1-bin-hadoop2.7.tgz ./spark.tar.gz
# RUN wget -O /spark.tar.gz -q https://archive.apache.org/dist/spark/spark-2.4.1/spark-2.4.1-bin-hadoop2.7.tgz
RUN tar xfz spark.tar.gz
RUN mv /spark-2.4.1-bin-hadoop2.7 /usr/local/spark
RUN rm /spark.tar.gz

# Install Hive
ENV HIVE_VERSION=2.3.7
ENV HIVE_HOME=/usr/local/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH $PATH:$HIVE_HOME/bin
COPY docker_bin/pac/apache-hive-2.3.7-bin.tar.gz ./hive.tar.gz
RUN tar xfz hive.tar.gz \
        && mv /apache-hive-$HIVE_VERSION-bin /usr/local/hive \
        && rm /hive.tar.gz \
        && mkdir -p $HIVE_HOME/var/log \
        && mkdir -p $HIVE_HOME/var/querylog \
        && mkdir -p $HIVE_HOME/var/resources \
        && chmod 777 $HIVE_HOME/var/log \
        && chmod 777 $HIVE_HOME/var/querylog \
        && chmod 777 $HIVE_HOME/var/resources
RUN wget -O $HIVE_HOME/lib/mysql-connector-java-6.0.6.jar -q https://repo1.maven.org/maven2/mysql/mysql-connector-java/6.0.6/mysql-connector-java-6.0.6.jar


ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME:sbin:$HIVE_HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin

RUN mkdir -p $HADOOP_HOME/hdfs/namenode \
        && mkdir -p $HADOOP_HOME/hdfs/datanode


COPY docker_bin/config/ /tmp/
RUN mv /tmp/ssh_config $HOME/.ssh/config \
    && mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml \
    && mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
    && mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml.template \
    && cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml \
    && mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml \
    && mv /tmp/spark/spark-env.sh $SPARK_HOME/conf/spark-env.sh \
    && mv /tmp/spark/log4j.properties $SPARK_HOME/conf/log4j.properties \
    && mv /tmp/spark/spark.defaults.conf $SPARK_HOME/conf/spark.defaults.conf \
    && mv /tmp/hive/hive-site.xml $HIVE_CONF_DIR/hive-site.xml \
    && mv /tmp/hive/hive-env.sh $HIVE_CONF_DIR/hive-env.sh

RUN chmod 744 -R $HADOOP_HOME

# Install Linkis
COPY assembly-combined-package/target/wedatasphere-linkis-1.0.2-combined-package-dist.tar.gz /tmp/
RUN mkdir -p /linkis/
RUN tar -zvxf /tmp/wedatasphere-linkis-1.0.2-combined-package-dist.tar.gz -C /linkis/

ARG LINKIS_CONFIG_ENV_PATH=/linkis/config/linkis-env.sh

RUN sed -i 's/^deployUser=.*/deployUser=root/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's!^HIVE_META_URL=.*!HIVE_META_URL="jdbc:mysql://10.211.55.25:3306/hive?createDatabaseIfNotExist=true\&useUnicode=true\&characterEncoding=UTF-8\&useSSL=false"!' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^HIVE_META_USER=.*/HIVE_META_USER="root"/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^HIVE_META_PASSWORD=.*/HIVE_META_PASSWORD="123456"/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's!^YARN_RESTFUL_URL=.*!YARN_RESTFUL_URL=http://cluster-master:8088!' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^HADOOP_CONF_DIR=.*/HADOOP_CONF_DIR=$HADOOP_CONF_DIR/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^HIVE_CONF_DIR=.*/HIVE_CONF_DIR=$HIVE_CONF_DIR/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^SPARK_CONF_DIR=.*/SPARK_CONF_DIR=$SPARK_CONF_DIR/' $LINKIS_CONFIG_ENV_PATH \
    && sed -i 's/^export SERVER_HEAP_SIZE=.*/export SERVER_HEAP_SIZE="128M"/' $LINKIS_CONFIG_ENV_PATH

ARG LINKIS_CONFIG_DB_PATH=/linkis/config/db.sh

RUN sed -i 's!^MYSQL_HOST=.*!MYSQL_HOST=10.211.55.25!' $LINKIS_CONFIG_DB_PATH  \
    && sed -i 's/^MYSQL_PORT=.*/MYSQL_PORT=3306/' $LINKIS_CONFIG_DB_PATH  \
    && sed -i 's/^MYSQL_DB=.*/MYSQL_DB=linkis/' $LINKIS_CONFIG_DB_PATH  \
    && sed -i 's/^MYSQL_USER=.*/MYSQL_USER=root/' $LINKIS_CONFIG_DB_PATH  \
    && sed -i 's/^MYSQL_PASSWORD=.*/MYSQL_PASSWORD=123456/' $LINKIS_CONFIG_DB_PATH
RUN rm -rf /tmp


EXPOSE 20303 9001 9101 9102 9103 9104 9105 9108

ENTRYPOINT bash