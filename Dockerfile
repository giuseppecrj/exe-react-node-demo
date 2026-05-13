FROM oven/bun:1.3.3-debian AS deps
WORKDIR /app
COPY package.json bun.lock ./
COPY apps/web/package.json apps/web/package.json
RUN bun install --frozen-lockfile

FROM deps AS build
COPY . .
RUN bun run build

FROM oven/bun:1.3.3-debian AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY package.json bun.lock ./
COPY apps/web/package.json apps/web/package.json
RUN bun install --frozen-lockfile --production
COPY apps/web/server apps/web/server
COPY --from=build /app/apps/web/dist apps/web/dist
WORKDIR /app/apps/web
EXPOSE 3000
CMD ["bun", "run", "start"]
