#!/bin/sh
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout key.pem -out cert.pem
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
openssl rsa -in privateKey.key -check
openssl x509 -in certificate.crt -text -noout
openssl rsa -in privateKey.key -text > private.pem
openssl x509 -inform PEM -in certificate.crt > public.pem

#aws iam upload-server-certificate --server-certificate-name CSC --certificate-body file://public.pem --private-key file://private.pem
