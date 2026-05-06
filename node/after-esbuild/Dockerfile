# Node esbuild bundle — single .mjs on alpine Node base (~45 MB image)
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM node:20-alpine
COPY --from=build /app/dist/app.mjs /app.mjs
ENTRYPOINT ["node", "/app.mjs"]
