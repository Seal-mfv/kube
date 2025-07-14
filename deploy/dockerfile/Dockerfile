ARG APP_NAME

FROM golang:1.23.4-alpine3.20 AS builder
ARG APP_NAME

WORKDIR /app
RUN apk add --no-cache gcc musl-dev git

RUN go env -w GOPRIVATE="github.com/moneyforward"
RUN --mount=type=secret,id=github-pat \
    export GITHUB_PAT="$(cat /run/secrets/github-pat)" && \
    git config --global url."https://${GITHUB_PAT}@github.com/moneyforward/".insteadOf "https://github.com/moneyforward/"

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download && go mod verify

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o ${APP_NAME} cmd/${APP_NAME}/main.go

FROM alpine:3.20
ARG APP_NAME

ENV APP_NAME=${APP_NAME}
COPY --from=builder /app/${APP_NAME} /usr/local/bin/${APP_NAME}

ENTRYPOINT ["sh", "-c", "$APP_NAME"]
