FROM gradle:jdk as back
USER root

COPY back/ .
RUN gradle -q build

FROM node:8-jessie as front
USER root

RUN npm install elm
WORKDIR /tmp
COPY front/src src
COPY front/elm.json .
RUN mkdir -p dist/
COPY front/assets dist
RUN /node_modules/elm/bin/elm make src/*.elm --output=dist/tiragealea.js

FROM gcr.io/distroless/java

COPY --from=back /home/gradle/build/libs/tiragealea-1.0-SNAPSHOT-shadow.jar /
COPY --from=front /tmp/dist .

ENV WEB_ROOT=/

CMD [ "tiragealea-1.0-SNAPSHOT-shadow.jar" ]
