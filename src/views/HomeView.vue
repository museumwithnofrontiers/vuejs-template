<script setup>
// This page is a placeholder — replace it with your own content. It is
// deliberately self-contained (all of its styling lives right here in this
// file's <style scoped> block) so deleting or rewriting it leaves nothing
// else in the project to clean up. (The logo already appears in the header
// in App.vue — it is not repeated here because the navy "blue" variant of
// it has too little contrast against this same navy background.)
</script>

<template>
  <div class="hero">
    <div class="hero-content">
      <h1>Welcome</h1>
      <p>This is the starting point for your Vue.js site. Replace this page with your own content.</p>
    </div>

    <a
      class="legal-link"
      href="https://www.museumwnf.org/about/legal-notice"
      target="_blank"
      rel="noopener"
    >
      IMPORTANT LEGAL NOTICE
    </a>
  </div>
</template>

<style scoped>
.hero {
  /* Full-bleed regardless of the #app container's own max-width/padding. */
  width: 100vw;
  margin-left: calc(-50vw + 50%);
  box-sizing: border-box;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  gap: 2rem;
  padding: 3rem 1.5rem;
  background: #001d66;
  color: #ffffff;
  text-align: center;
}

.hero-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  margin: auto 0;
}

.hero h1 {
  margin: 0;
  font-size: 2rem;
}

.hero p {
  max-width: 32rem;
  line-height: 1.6;
}

.legal-link {
  color: #ffffff;
  text-decoration: underline;
  font-size: 0.85rem;
  letter-spacing: 0.03em;
}

.legal-link:hover,
.legal-link:focus-visible {
  text-decoration: none;
}
</style>
