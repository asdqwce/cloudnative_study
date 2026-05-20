<template>
  <div class="placeholder">
    <strong>{{ label }}</strong>
    <span>{{ hint }}</span>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  hint: string
}>()
</script>
