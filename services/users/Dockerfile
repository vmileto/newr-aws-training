FROM node:latest

# set working directory
WORKDIR /usr/app

RUN apt-get update -y

# install and cache app dependencies
ENV PATH /usr/app/node_modules/.bin:$PATH
ADD package.json /usr/app/package.json
RUN npm install

# add service
ADD src /usr/app/src

# start service
CMD ["npm", "start"]
