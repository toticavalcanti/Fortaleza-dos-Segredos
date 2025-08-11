# ---------- Builder ----------
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN mkdir -p public && npm run build
RUN npm prune --omit=dev

# ---------- Runner ----------
FROM node:22-alpine AS runner
ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public/

RUN addgroup -S nextjs && adduser -S nextjs -G nextjs \
    && chown -R nextjs:nextjs /app

USER nextjs

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT}/api/segredo >/dev/null 2>&1 || exit 1

EXPOSE 3000
CMD ["npm", "start"]
