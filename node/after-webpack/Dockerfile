# Node webpack bundle — single .cjs on alpine Node base
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json webpack.config.cjs ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM node:20-alpine
COPY --from=build /app/dist/app.cjs /app.cjs
ENTRYPOINT ["node", "/app.cjs"]
