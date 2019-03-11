FROM node:latest

# set working directory
WORKDIR /usr/app

# install and cache app dependencies
ENV PATH /usr/src/app/node_modules/.bin:$PATH
ADD package.json /usr/app/package.json
RUN npm install
RUN npm install react-scripts@0.9.5 -g

# add app
ADD src /usr/app/src
ADD public /usr/app/public

# start app
CMD ["npm", "start"]
