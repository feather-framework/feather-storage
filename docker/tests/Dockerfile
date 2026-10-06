FROM swift:6.3

WORKDIR /app

COPY . ./

RUN swift package resolve
RUN swift package clean
RUN swift package update

CMD ["swift", "test", "--parallel", "--enable-code-coverage"]
