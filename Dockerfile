# Node version: single declared source of truth is .nvmrc at the repo root
# (also read directly by `actions/setup-node` in .github/workflows/*.yml,
# and by nvm/fnm/Volta on the host). Docker can't read an external file to
# pick its own FROM image, so this ARG's default is kept in sync with
# .nvmrc by hand -- and scripts/check-node-version-sync.mjs, run in CI,
# fails loudly the moment the two drift apart instead of staying silently
# out of sync (see README.md for why that matters here).
ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-alpine

WORKDIR /app

# Installed at image-build time so the dependency tree matches
# package-lock.json exactly (npm ci, not npm install) -- this is the actual
# reproducibility guarantee, independent of Docker. See README.md.
COPY package.json package-lock.json ./
RUN npm ci

# The rest of the source is bind-mounted over this at runtime for live
# editing (see compose.yml) -- copying it here too keeps `docker build`
# usable standalone (e.g. to reproduce a CI failure) without compose.
COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
