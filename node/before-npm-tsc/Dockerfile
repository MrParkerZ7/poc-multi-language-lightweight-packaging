# Node naive deploy — full Node base + node_modules (~250 MB image)
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npx tsc

FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json .
ENTRYPOINT ["node", "dist/main.js"]
