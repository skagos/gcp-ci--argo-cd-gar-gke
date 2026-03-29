FROM nginx:alpine

# remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# copy your html
COPY app/index.html /usr/share/nginx/html/index.html