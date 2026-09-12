FROM public.ecr.aws/lambda/python:3.12

# Install build dependencies
RUN dnf install -y gcc python3-devel libjpeg-devel zlib-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel

# Install Pillow into /opt/python
RUN pip install --no-cache-dir pillow -t /opt/python

# Zip the layer
RUN cd /opt && zip -r /tmp/pillow_layer.zip .
