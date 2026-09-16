#!/usr/bin/env node
// .nvmrc is the single declared source of truth for the Node version (read
// automatically by GitHub Actions' `node-version-file` and by nvm/fnm/Volta
// on the host). Docker can't read an external file to pick its own FROM
// image at build time, so Dockerfile's `ARG NODE_VERSION=<n>` default has
// to be a second, hand-typed copy of the same number -- this script is what
// keeps that copy honest: it fails loudly the moment the two drift apart,
// rather than letting a host/CI/container version mismatch go unnoticed
// (exactly the class of bug that motivated shipping this check at all).

import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')

const nvmrc = readFileSync(join(root, '.nvmrc'), 'utf8').trim()

const dockerfile = readFileSync(join(root, 'Dockerfile'), 'utf8')
const match = dockerfile.match(/^ARG NODE_VERSION=(\S+)/m)
if (!match) {
  console.error('Could not find "ARG NODE_VERSION=..." in Dockerfile.')
  process.exit(1)
}
const dockerVersion = match[1]

if (nvmrc !== dockerVersion) {
  console.error(
    `Node version drift: .nvmrc says "${nvmrc}" but Dockerfile's ARG NODE_VERSION defaults to "${dockerVersion}". ` +
      'Update Dockerfile\'s ARG NODE_VERSION to match .nvmrc (or vice versa) and keep them in sync by hand -- ' +
      'Docker cannot read .nvmrc directly at build time.',
  )
  process.exit(1)
}

console.log(`.nvmrc and Dockerfile agree: Node ${nvmrc}.`)
