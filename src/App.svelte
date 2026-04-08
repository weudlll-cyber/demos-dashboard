<script>
  import { onMount, onDestroy } from 'svelte';
  import { fetchNodeData } from './api.js';
  import NodeInfo from './components/NodeInfo.svelte';
  import SyncStatus from './components/SyncStatus.svelte';
  import PeerList from './components/PeerList.svelte';
  import './styles.css';

  let data = null;
  let error = false;
  let lastUpdated = null;
  let interval = null;

  const POLL_INTERVAL_MS = 3000;

  async function load() {
    const result = await fetchNodeData();
    if (result) {
      data = result;
      error = false;
      lastUpdated = new Date();
    } else {
      error = true;
    }
  }

  onMount(() => {
    load();
    interval = setInterval(load, POLL_INTERVAL_MS);
  });

  onDestroy(() => {
    clearInterval(interval);
  });

  function formatTime(date) {
    if (!date) return '—';
    return date.toLocaleTimeString();
  }
</script>

<div class="layout">
  <header class="header">
    <div class="header-title">
      <h1>DEMOS Node</h1>
      <span class="header-badge">Live</span>
    </div>
    <div class="header-meta">
      {#if lastUpdated}
        Last updated: {formatTime(lastUpdated)}
      {:else}
        Connecting…
      {/if}
    </div>
  </header>

  {#if error && !data}
    <div class="state-screen">
      <span class="error-icon">⚠️</span>
      <p>Cannot reach node at <code>localhost:53550</code></p>
      <p style="font-size:0.8rem">Retrying every {POLL_INTERVAL_MS / 1000}s…</p>
    </div>
  {:else if !data}
    <div class="state-screen">
      <div class="spinner"></div>
      <p>Loading node data…</p>
    </div>
  {:else}
    <div class="grid grid-2">
      <NodeInfo {data} />
      <SyncStatus peer={data.peerlist?.[0]} />
      <div class="grid-full">
        <PeerList peers={data.peerlist} />
      </div>
    </div>
  {/if}
</div>
