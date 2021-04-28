FROM python:3.8.0-slim as builder
RUN apt-get update \
&& apt-get install gcc -y \
&& apt-get clean
COPY requirements.txt /app/requirements.txt
WORKDIR app
RUN pip install --upgrade pip
RUN pip install --user -r requirements.txt
COPY . /app

# Here is the production image
FROM python:3.8.0-slim as app
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
COPY pepMeld /pepMeld
#RUN cd / && tar -xzf pepMeld-master.tar.gz && rm pepMeld-master.tar.gz && mv pepMeld-master pepMeld
ADD http://drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz /muscle3.8.31_i86linux64.tar.gz
RUN cd / && tar -xzf muscle3.8.31_i86linux64.tar.gz && rm muscle3.8.31_i86linux64.tar.gz && mv muscle3.8.31_i86linux64 muscle
WORKDIR /pepMeld
CMD ["/bin/bash"]

