FROM golang:1.23

WORKDIR /app

COPY go.mod main.go ./
RUN go build

EXPOSE 8080

CMD ["./main"]
