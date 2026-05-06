# Node @vercel/ncc bundle — single index.js on alpine Node base
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM node:20-alpine
COPY --from=build /app/dist/index.js /index.js
ENTRYPOINT ["node", "/index.js"]
