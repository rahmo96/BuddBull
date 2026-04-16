# ─── Stage 1: Dependencies ────────────────────────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app

# Install only production dependencies first (layer cache efficiency)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

# ─── Stage 2: Development ─────────────────────────────────────────────────────
FROM node:20-alpine AS development
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

EXPOSE 5000
CMD ["npm", "run", "dev"]

# ─── Stage 3: Production ──────────────────────────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app

# Non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy production node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create upload and log directories, set ownership
RUN mkdir -p uploads logs && chown -R appuser:appgroup /app

USER appuser

EXPOSE 5000

ENV NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

CMD ["node", "server.js"]
