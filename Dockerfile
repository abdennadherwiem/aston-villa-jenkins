FROM node:12.7-alpine as build

WORKDIR /usr/src/app

ADD package.json package-lock.json ./

RUN npm install

ADD . .

RUN npm run build

RUN ls -la dist/

FROM nginx:1.17.1-alpine

ADD nginx.conf /etc/nginx/nginx.conf

COPY --from=build /usr/src/app/dist/aston-villa-app /usr/share/nginx/html

RUN ls -la /usr/share/nginx/html

CMD ["nginx" , "-g", "daemon off;"]
