# Build stage
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Enable go modules, and disable CGO for static binary
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

COPY . .

# Initialize go module if it doesn't exist and build
RUN if [ ! -f go.mod ]; then go mod init app; fi && \
    go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:3.24

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the pre-built binary file from the previous stage
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
