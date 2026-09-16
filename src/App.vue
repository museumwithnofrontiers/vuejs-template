<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <header>
    <img
      alt="Museum With No Frontiers"
      class="logo"
      src="@/assets/mwnf-logo.png"
      width="160"
      height="52"
    />

    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink to="/about">About</RouterLink>
    </nav>
  </header>

  <RouterView />
</template>

<style scoped>
header {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 1rem 1.5rem;
}

.logo {
  display: block;
  height: 52px;
  width: auto;
}

nav {
  font-size: 14px;
}

nav a.router-link-exact-active {
  color: var(--color-text);
  font-weight: bold;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}
</style>
