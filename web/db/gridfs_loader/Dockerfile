FROM mongo:4.4

WORKDIR /loader

COPY GridFS/books /books
COPY GridFS/init_gridfs.sh /loader/init_gridfs.sh

RUN chmod +x /loader/init_gridfs.sh

CMD ["/loader/init_gridfs.sh"]
